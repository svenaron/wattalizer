import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/models/autolap_config.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/domain/models/ride_summary.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';
import 'package:wattalizer/domain/services/effort_manager.dart';
import 'package:wattalizer/presentation/providers/autolap_config_provider.dart';
import 'package:wattalizer/presentation/providers/historical_range_provider.dart';
import 'package:wattalizer/presentation/providers/ride_detail_provider.dart';
import 'package:wattalizer/presentation/providers/ride_list_provider.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';
import 'package:wattalizer/presentation/widgets/effort_timeline.dart';

/// Opens the re-detection preview adaptively:
/// narrow (<600dp) → modal bottom sheet, wide (≥600dp) → centered dialog.
void showRedetectSheet(
  BuildContext context,
  Ride ride,
  List<SensorReading> readings,
) {
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
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, __) =>
              RedetectPreviewSheet(ride: ride, readings: readings),
        ),
      ),
    );
  } else {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
            child: RedetectPreviewSheet(ride: ride, readings: readings),
          ),
        ),
      ),
    );
  }
}

class RedetectPreviewSheet extends ConsumerStatefulWidget {
  const RedetectPreviewSheet({
    required this.ride,
    required this.readings,
    super.key,
  });

  final Ride ride;
  final List<SensorReading> readings;

  @override
  ConsumerState<RedetectPreviewSheet> createState() =>
      _RedetectPreviewSheetState();
}

class _RedetectPreviewSheetState extends ConsumerState<RedetectPreviewSheet> {
  late AutoLapConfig _config;
  late List<Effort> _preview;
  bool _applying = false;
  AutoLapConfig? _selectedConfig; // null = custom

  late TextEditingController _startDeltaCtrl;
  late TextEditingController _startConfirmCtrl;
  late TextEditingController _endDeltaCtrl;
  late TextEditingController _endConfirmCtrl;
  late TextEditingController _minEffortCtrl;
  late TextEditingController _baselineWindowCtrl;
  late TextEditingController _minPeakWattsCtrl;

  @override
  void initState() {
    super.initState();
    _config = ref.read(autoLapConfigProvider).asData?.value ??
        AutoLapConfig.standingStart();

    _startDeltaCtrl =
        TextEditingController(text: _config.startDeltaWatts.toString());
    _startConfirmCtrl =
        TextEditingController(text: _config.startConfirmSeconds.toString());
    _endDeltaCtrl =
        TextEditingController(text: _config.endDeltaWatts.toString());
    _endConfirmCtrl =
        TextEditingController(text: _config.endConfirmSeconds.toString());
    _minEffortCtrl =
        TextEditingController(text: _config.minEffortSeconds.toString());
    _baselineWindowCtrl =
        TextEditingController(text: _config.preEffortBaselineWindow.toString());
    _minPeakWattsCtrl = TextEditingController(
      text: _config.minPeakWatts != null ? _config.minPeakWatts.toString() : '',
    );

    _preview = widget.ride.efforts;
    _runPreview();
  }

  @override
  void dispose() {
    _startDeltaCtrl.dispose();
    _startConfirmCtrl.dispose();
    _endDeltaCtrl.dispose();
    _endConfirmCtrl.dispose();
    _minEffortCtrl.dispose();
    _baselineWindowCtrl.dispose();
    _minPeakWattsCtrl.dispose();
    super.dispose();
  }

  void _runPreview() {
    final newEfforts = EffortManager().redetectEfforts(
      rideId: widget.ride.id,
      readings: widget.readings,
      config: _config,
    );
    setState(() => _preview = newEfforts);
  }

  void _applyConfig(AutoLapConfig cfg) {
    setState(() => _selectedConfig = cfg);
    _startDeltaCtrl.text = cfg.startDeltaWatts.toString();
    _startConfirmCtrl.text = cfg.startConfirmSeconds.toString();
    _endDeltaCtrl.text = cfg.endDeltaWatts.toString();
    _endConfirmCtrl.text = cfg.endConfirmSeconds.toString();
    _minEffortCtrl.text = cfg.minEffortSeconds.toString();
    _baselineWindowCtrl.text = cfg.preEffortBaselineWindow.toString();
    _minPeakWattsCtrl.text =
        cfg.minPeakWatts != null ? cfg.minPeakWatts.toString() : '';
    _config = cfg;
    _runPreview();
  }

  void _onFieldChanged() {
    setState(() => _selectedConfig = null); // switch to Custom
    _config = AutoLapConfig(
      id: _config.id,
      name: _config.name,
      startDeltaWatts:
          double.tryParse(_startDeltaCtrl.text) ?? _config.startDeltaWatts,
      startConfirmSeconds:
          int.tryParse(_startConfirmCtrl.text) ?? _config.startConfirmSeconds,
      startDropoutTolerance: _config.startDropoutTolerance,
      endDeltaWatts:
          double.tryParse(_endDeltaCtrl.text) ?? _config.endDeltaWatts,
      endConfirmSeconds:
          int.tryParse(_endConfirmCtrl.text) ?? _config.endConfirmSeconds,
      minEffortSeconds:
          int.tryParse(_minEffortCtrl.text) ?? _config.minEffortSeconds,
      preEffortBaselineWindow: int.tryParse(_baselineWindowCtrl.text) ??
          _config.preEffortBaselineWindow,
      inEffortTrailingWindow: _config.inEffortTrailingWindow,
      minPeakWatts: double.tryParse(_minPeakWattsCtrl.text.trim()),
      isDefault: _config.isDefault,
    );
    _runPreview();
  }

  AutoLapConfig? _detectConfig(
    AutoLapConfig cfg,
    List<AutoLapConfig> configs,
  ) {
    for (final c in configs) {
      if (_matches(cfg, c)) return c;
    }
    return null;
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    final repo = ref.read(rideRepositoryProvider);
    await repo.saveEfforts(widget.ride.id, _preview);
    final s = widget.ride.summary;
    final updatedRide = widget.ride.copyWith(
      efforts: _preview,
      summary: RideSummary(
        durationSeconds: s.durationSeconds,
        activeDurationSeconds: s.activeDurationSeconds,
        avgPower: s.avgPower,
        maxPower: s.maxPower,
        readingCount: s.readingCount,
        effortCount: _preview.length,
        avgHeartRate: s.avgHeartRate,
        maxHeartRate: s.maxHeartRate,
        avgCadence: s.avgCadence,
        avgLeftRightBalance: s.avgLeftRightBalance,
      ),
    );
    await repo.updateRide(updatedRide);
    ref
      ..invalidate(rideDetailProvider(widget.ride.id))
      ..invalidate(rideListProvider)
      ..invalidate(historicalRangeProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final currentCount = ride.efforts.length;
    final previewCount = _preview.length;
    // Detect matching config on first load
    final configsAsync = ref.watch(autoLapConfigListProvider)
      ..whenData((configs) {
        if (_selectedConfig == null) {
          final matched = _detectConfig(_config, configs);
          if (matched != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedConfig = matched);
            });
          }
        }
      });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Re-detect Efforts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Config chip row ---
                  configsAsync.when(
                    loading: () => const SizedBox(
                      height: 36,
                      child: Center(child: LinearProgressIndicator()),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (configs) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final cfg in configs)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cfg.name),
                                selected: _selectedConfig?.id == cfg.id,
                                onSelected: (_) => _applyConfig(cfg),
                              ),
                            ),
                          ChoiceChip(
                            label: const Text('Custom'),
                            selected: _selectedConfig == null,
                            onSelected: (_) {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // --- Parameter fields ---
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _compactField(
                        _startDeltaCtrl,
                        'Start Delta W',
                        isDouble: true,
                      ),
                      _compactField(_startConfirmCtrl, 'Start Confirm s'),
                      _compactField(
                        _endDeltaCtrl,
                        'End Delta W',
                        isDouble: true,
                      ),
                      _compactField(_endConfirmCtrl, 'End Confirm s'),
                      _compactField(_minEffortCtrl, 'Min Effort s'),
                      _compactField(_baselineWindowCtrl, 'Baseline Window s'),
                      _compactField(
                        _minPeakWattsCtrl,
                        'Min Peak W',
                        isDouble: true,
                        optional: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- Current efforts timeline ---
                  Text(
                    'Current: $currentCount '
                    'effort${currentCount == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  EffortTimeline(
                    efforts: ride.efforts,
                    totalDurationSeconds: ride.summary.durationSeconds,
                  ),
                  const SizedBox(height: 12),

                  // --- Preview efforts timeline ---
                  Text(
                    'Preview: $previewCount '
                    'effort${previewCount == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  EffortTimeline(
                    efforts: _preview,
                    totalDurationSeconds: ride.summary.durationSeconds,
                  ),
                  const SizedBox(height: 12),

                  // --- Changes summary ---
                  _buildChangeSummary(currentCount, previewCount),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // --- Action row ---
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _applying ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _applying ? null : _apply,
                child: _applying
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactField(
    TextEditingController ctrl,
    String label, {
    bool isDouble = false,
    bool optional = false,
  }) {
    return SizedBox(
      width: 140,
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 8,
          ),
          hintText: optional ? 'disabled' : null,
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: isDouble),
        onChanged: (_) => _onFieldChanged(),
      ),
    );
  }

  Widget _buildChangeSummary(int currentCount, int previewCount) {
    if (previewCount == currentCount) {
      return Text(
        'No change ($currentCount effort${currentCount == 1 ? '' : 's'})',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    final durations =
        _preview.map((e) => '${e.summary.durationSeconds}s').join(', ');
    return Text(
      '$currentCount → $previewCount effort${previewCount == 1 ? '' : 's'}.'
      '${durations.isNotEmpty ? ' New durations: $durations' : ''}',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  static bool _matches(AutoLapConfig a, AutoLapConfig b) {
    return a.startDeltaWatts == b.startDeltaWatts &&
        a.startConfirmSeconds == b.startConfirmSeconds &&
        a.endDeltaWatts == b.endDeltaWatts &&
        a.endConfirmSeconds == b.endConfirmSeconds &&
        a.minEffortSeconds == b.minEffortSeconds &&
        a.preEffortBaselineWindow == b.preEffortBaselineWindow &&
        a.minPeakWatts == b.minPeakWatts;
  }
}
