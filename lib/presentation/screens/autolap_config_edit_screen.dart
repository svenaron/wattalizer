import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/models/autolap_config.dart';
import 'package:wattalizer/presentation/providers/autolap_config_provider.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';

class AutoLapConfigEditScreen extends ConsumerStatefulWidget {
  const AutoLapConfigEditScreen({required this.config, super.key});

  final AutoLapConfig? config;

  @override
  ConsumerState<AutoLapConfigEditScreen> createState() =>
      _AutoLapConfigEditScreenState();
}

class _AutoLapConfigEditScreenState
    extends ConsumerState<AutoLapConfigEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _startDeltaCtrl;
  late TextEditingController _startConfirmCtrl;
  late TextEditingController _startDropoutCtrl;
  late TextEditingController _endDeltaCtrl;
  late TextEditingController _endConfirmCtrl;
  late TextEditingController _minEffortCtrl;
  late TextEditingController _baselineWindowCtrl;
  late TextEditingController _trailingWindowCtrl;
  late TextEditingController _minPeakWattsCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final cfg = widget.config;
    _nameCtrl = TextEditingController(text: cfg?.name ?? '');
    _startDeltaCtrl =
        TextEditingController(text: cfg?.startDeltaWatts.toString() ?? '200');
    _startConfirmCtrl =
        TextEditingController(text: cfg?.startConfirmSeconds.toString() ?? '2');
    _startDropoutCtrl = TextEditingController(
      text: cfg?.startDropoutTolerance.toString() ?? '1',
    );
    _endDeltaCtrl =
        TextEditingController(text: cfg?.endDeltaWatts.toString() ?? '150');
    _endConfirmCtrl =
        TextEditingController(text: cfg?.endConfirmSeconds.toString() ?? '5');
    _minEffortCtrl =
        TextEditingController(text: cfg?.minEffortSeconds.toString() ?? '3');
    _baselineWindowCtrl = TextEditingController(
      text: cfg?.preEffortBaselineWindow.toString() ?? '15',
    );
    _trailingWindowCtrl = TextEditingController(
      text: cfg?.inEffortTrailingWindow.toString() ?? '10',
    );
    _minPeakWattsCtrl = TextEditingController(
      text: cfg?.minPeakWatts != null ? cfg!.minPeakWatts.toString() : '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _startDeltaCtrl.dispose();
    _startConfirmCtrl.dispose();
    _startDropoutCtrl.dispose();
    _endDeltaCtrl.dispose();
    _endConfirmCtrl.dispose();
    _minEffortCtrl.dispose();
    _baselineWindowCtrl.dispose();
    _trailingWindowCtrl.dispose();
    _minPeakWattsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final config = AutoLapConfig(
      id: widget.config?.id,
      name: _nameCtrl.text.trim(),
      startDeltaWatts: double.tryParse(_startDeltaCtrl.text) ?? 200,
      startConfirmSeconds: int.tryParse(_startConfirmCtrl.text) ?? 2,
      startDropoutTolerance: int.tryParse(_startDropoutCtrl.text) ?? 1,
      endDeltaWatts: double.tryParse(_endDeltaCtrl.text) ?? 150,
      endConfirmSeconds: int.tryParse(_endConfirmCtrl.text) ?? 5,
      minEffortSeconds: int.tryParse(_minEffortCtrl.text) ?? 3,
      preEffortBaselineWindow: int.tryParse(_baselineWindowCtrl.text) ?? 15,
      inEffortTrailingWindow: int.tryParse(_trailingWindowCtrl.text) ?? 10,
      minPeakWatts: double.tryParse(_minPeakWattsCtrl.text.trim()),
      isDefault: widget.config?.isDefault ?? false,
    );

    final repo = ref.read(rideRepositoryProvider);
    await repo.saveAutoLapConfig(config);
    ref
      ..invalidate(autoLapConfigProvider)
      ..invalidate(autoLapConfigListProvider);

    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.config == null;
    return Scaffold(
      appBar: AppBar(title: Text(isNew ? 'New Config' : 'Edit Config')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(
              _nameCtrl,
              'Name',
              tooltip: 'Display name for this configuration',
            ),
            const SizedBox(height: 16),
            const Text(
              'Start Detection',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _field(
              _startDeltaCtrl,
              'Delta Watts',
              tooltip: 'Power increase above baseline to trigger effort start',
              isDouble: true,
            ),
            _field(
              _startConfirmCtrl,
              'Confirm Seconds',
              tooltip: 'Seconds power must stay elevated to confirm start',
            ),
            _field(
              _startDropoutCtrl,
              'Dropout Tolerance',
              tooltip: 'Allowed null readings during start confirmation',
            ),
            const SizedBox(height: 16),
            const Text(
              'End Detection',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _field(
              _endDeltaCtrl,
              'Delta Watts',
              tooltip: 'Power decrease from trailing avg to trigger effort end',
              isDouble: true,
            ),
            _field(
              _endConfirmCtrl,
              'Confirm Seconds',
              tooltip: 'Seconds power must stay low to confirm end',
            ),
            const SizedBox(height: 16),
            const Text(
              'Effort',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _field(
              _minEffortCtrl,
              'Min Effort Seconds',
              tooltip: 'Efforts shorter than this are discarded',
            ),
            _field(
              _baselineWindowCtrl,
              'Baseline Window',
              tooltip: 'Seconds to average before effort for baseline',
            ),
            _field(
              _trailingWindowCtrl,
              'Trailing Window',
              tooltip: 'Seconds to track decay during effort',
            ),
            _optionalField(
              _minPeakWattsCtrl,
              'Min Peak Watts',
              tooltip:
                  'Efforts that never reach this watt threshold are discarded '
                  '(leave empty to disable)',
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? tooltip,
    bool isDouble = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          helperText: tooltip,
          helperMaxLines: 2,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (v) {
          if (v == null || v.trim().isEmpty) {
            return 'Required';
          }
          if (label == 'Name') return null;
          if (isDouble) {
            if (double.tryParse(v) == null) return 'Invalid';
          } else {
            if (int.tryParse(v) == null) return 'Invalid';
          }
          return null;
        },
      ),
    );
  }

  Widget _optionalField(
    TextEditingController ctrl,
    String label, {
    String? tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          helperText: tooltip,
          helperMaxLines: 3,
          hintText: 'Leave empty to disable',
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return null;
          if (double.tryParse(v.trim()) == null) return 'Invalid';
          return null;
        },
      ),
    );
  }
}
