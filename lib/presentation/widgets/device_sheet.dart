import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/interfaces/ble_service.dart';
import 'package:wattalizer/domain/models/device_info.dart';
import 'package:wattalizer/presentation/providers/ble_connection_provider.dart';
import 'package:wattalizer/presentation/providers/ble_service_provider.dart';
import 'package:wattalizer/presentation/providers/connected_device_provider.dart';
import 'package:wattalizer/presentation/providers/device_list_provider.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';

/// Opens the device connection sheet (spec §9.4.2).
///
/// Compact (<600dp): modal bottom sheet with draggable scroll.
/// Medium/Expanded (>=600dp): centered dialog.
void showDeviceSheet(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;

  if (width < 600) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) =>
              _DeviceSheetContent(scrollController: scrollController),
        ),
      ),
    );
  } else {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
            child: _DeviceSheetContent(scrollController: ScrollController()),
          ),
        ),
      ),
    );
  }
}

class _DeviceSheetContent extends ConsumerStatefulWidget {
  const _DeviceSheetContent({required this.scrollController});

  final ScrollController scrollController;

  @override
  ConsumerState<_DeviceSheetContent> createState() =>
      _DeviceSheetContentState();
}

class _DeviceSheetContentState extends ConsumerState<_DeviceSheetContent> {
  StreamSubscription<List<DiscoveredDevice>>? _scanSub;
  List<DiscoveredDevice> _scanResults = [];
  late final BleService _bleService;

  @override
  void initState() {
    super.initState();
    _bleService = ref.read(bleServiceProvider);
    _startScan();
  }

  void _startScan() {
    _scanResults = [];
    _scanSub = _bleService.scanForDevices().listen((devices) {
      if (!mounted) return;
      setState(() {
        for (final d in devices) {
          _scanResults
            ..removeWhere((e) => e.deviceId == d.deviceId)
            ..add(d);
        }
      });
    });
  }

  @override
  void dispose() {
    unawaited(_scanSub?.cancel());
    _bleService.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rememberedAsync = ref.watch(deviceListProvider);
    final connectedId = ref.watch(connectedDeviceProvider);
    final connState = ref.watch(bleConnectionProvider);

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Center(
          child: Container(
            width: 32,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Text('Devices', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),

        // --- Remembered devices ---
        ...rememberedAsync.when(
          data: (devices) =>
              _buildRememberedSection(devices, connectedId, connState),
          loading: () => [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          error: (e, _) => [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error loading devices: $e'),
            ),
          ],
        ),

        const Divider(height: 24),

        // --- Scan results ---
        Row(
          children: [
            Text(
              'Nearby Devices',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(width: 8),
            if (_scanResults.isEmpty)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ..._buildScanSection(rememberedAsync.asData?.value ?? []),
      ],
    );
  }

  List<Widget> _buildRememberedSection(
    List<DeviceInfo> devices,
    String? connectedId,
    AsyncValue<BleConnectionState> connState,
  ) {
    if (devices.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'No remembered devices',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ];
    }
    return devices.map((device) {
      final isThisConnected = connectedId == device.deviceId;
      final stateValue = isThisConnected
          ? (connState.asData?.value ?? BleConnectionState.disconnected)
          : BleConnectionState.disconnected;

      return ListTile(
        leading: _ServiceIcons(services: device.supportedServices),
        title: Text(device.displayName),
        subtitle: Text(
          isThisConnected ? _connectionLabel(stateValue) : 'Saved',
          style: TextStyle(
            color: stateValue == BleConnectionState.connected
                ? Colors.green
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!device.autoConnect)
              Tooltip(
                message: 'Auto-connect off',
                child: Icon(
                  Icons.link_off,
                  size: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.38),
                ),
              ),
            PopupMenuButton<_DeviceAction>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (action) => _onDeviceAction(action, device),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: _DeviceAction.rename,
                  child: Text('Rename'),
                ),
                PopupMenuItem(
                  value: _DeviceAction.toggleAutoConnect,
                  child: Text(
                    device.autoConnect
                        ? 'Disable auto-connect'
                        : 'Enable auto-connect',
                  ),
                ),
                const PopupMenuItem(
                  value: _DeviceAction.forget,
                  child: Text('Forget'),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _toggleConnection(device.deviceId, isThisConnected),
      );
    }).toList();
  }

  List<Widget> _buildScanSection(List<DeviceInfo> remembered) {
    final rememberedIds = remembered.map((d) => d.deviceId).toSet();
    final filtered =
        _scanResults.where((d) => !rememberedIds.contains(d.deviceId)).toList();

    if (filtered.isEmpty && _scanResults.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Scanning\u2026',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ];
    }
    if (filtered.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'No new devices found',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ];
    }

    return filtered.map((device) {
      return ListTile(
        leading: _ServiceIcons(services: device.advertisedServices),
        title: Text(device.name.isNotEmpty ? device.name : 'Unknown'),
        trailing: _SignalIcon(rssi: device.rssi),
        onTap: () => _connectAndRemember(device),
      );
    }).toList();
  }

  Future<void> _toggleConnection(String deviceId, bool isConnected) async {
    if (isConnected) {
      await ref.read(connectedDeviceProvider.notifier).disconnect();
    } else {
      await ref.read(connectedDeviceProvider.notifier).connect(deviceId);
    }
  }

  Future<void> _connectAndRemember(DiscoveredDevice device) async {
    final repo = ref.read(rideRepositoryProvider);
    final info = DeviceInfo(
      deviceId: device.deviceId,
      displayName: device.name.isNotEmpty ? device.name : 'Unknown',
      supportedServices: device.advertisedServices,
      lastConnected: DateTime.now(),
    );
    await repo.saveDevice(info);
    ref.invalidate(deviceListProvider);
    await ref.read(connectedDeviceProvider.notifier).connect(device.deviceId);
  }

  Future<void> _onDeviceAction(_DeviceAction action, DeviceInfo device) async {
    switch (action) {
      case _DeviceAction.rename:
        await _showRenameDialog(device);
      case _DeviceAction.toggleAutoConnect:
        final updated = device.copyWith(autoConnect: !device.autoConnect);
        await ref.read(rideRepositoryProvider).saveDevice(updated);
        ref.invalidate(deviceListProvider);
      case _DeviceAction.forget:
        await _showForgetDialog(device);
    }
  }

  Future<void> _showRenameDialog(DeviceInfo device) async {
    final controller = TextEditingController(text: device.displayName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Device'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Device name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName != null &&
        newName.isNotEmpty &&
        newName != device.displayName) {
      final updated = device.copyWith(displayName: newName);
      await ref.read(rideRepositoryProvider).saveDevice(updated);
      ref.invalidate(deviceListProvider);
    }
  }

  Future<void> _showForgetDialog(DeviceInfo device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forget Device'),
        content: Text(
          'Remove "${device.displayName}" from remembered devices?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Forget'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (ref.read(connectedDeviceProvider) == device.deviceId) {
        await ref.read(connectedDeviceProvider.notifier).disconnect();
      }
      await ref.read(rideRepositoryProvider).deleteDevice(device.deviceId);
      ref.invalidate(deviceListProvider);
    }
  }

  String _connectionLabel(BleConnectionState state) {
    return switch (state) {
      BleConnectionState.connected => 'Connected',
      BleConnectionState.connecting => 'Connecting\u2026',
      BleConnectionState.reconnecting => 'Reconnecting\u2026',
      BleConnectionState.disconnected => 'Disconnected',
    };
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

enum _DeviceAction { rename, toggleAutoConnect, forget }

class _ServiceIcons extends StatelessWidget {
  const _ServiceIcons({required this.services});

  final Set<SensorType> services;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (services.contains(SensorType.power))
          const Icon(Icons.bolt, size: 18, color: Colors.amber),
        if (services.contains(SensorType.heartRate))
          const Icon(Icons.favorite, size: 18, color: Colors.red),
        if (services.contains(SensorType.cadence))
          const Icon(Icons.speed, size: 18, color: Colors.blue),
      ],
    );
  }
}

class _SignalIcon extends StatelessWidget {
  const _SignalIcon({required this.rssi});

  final int rssi;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    if (rssi > -60) {
      icon = Icons.signal_cellular_alt;
      color = Colors.green;
    } else if (rssi > -80) {
      icon = Icons.signal_cellular_alt_2_bar;
      color = Colors.amber;
    } else {
      icon = Icons.signal_cellular_alt_1_bar;
      color = Colors.red;
    }
    return Icon(icon, size: 20, color: color);
  }
}
