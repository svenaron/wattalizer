import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/models/autolap_config.dart';
import 'package:wattalizer/presentation/providers/autolap_config_provider.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';

enum _Preset { shortSprint, flying200, teamSprint, custom }

class AutoLapConfigScreen extends ConsumerStatefulWidget {
  const AutoLapConfigScreen({super.key});

  @override
  ConsumerState<AutoLapConfigScreen> createState() =>
      _AutoLapConfigScreenState();
}

class _AutoLapConfigScreenState extends ConsumerState<AutoLapConfigScreen> {
  final _formKey = GlobalKey<FormState>();

  _Preset _preset = _Preset.custom;
  late TextEditingController _nameCtrl;
  late TextEditingController _startDeltaCtrl;
  late TextEditingController _startConfirmCtrl;
  late TextEditingController _startDropoutCtrl;
  late TextEditingController _endDeltaCtrl;
  late TextEditingController _endConfirmCtrl;
  late TextEditingController _minEffortCtrl;
  late TextEditingController _baselineWindowCtrl;
  late TextEditingController _trailingWindowCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _startDeltaCtrl = TextEditingController();
    _startConfirmCtrl = TextEditingController();
    _startDropoutCtrl = TextEditingController();
    _endDeltaCtrl = TextEditingController();
    _endConfirmCtrl = TextEditingController();
    _minEffortCtrl = TextEditingController();
    _baselineWindowCtrl = TextEditingController();
    _trailingWindowCtrl = TextEditingController();
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
    super.dispose();
  }

  void _loadConfig(AutoLapConfig cfg) {
    _nameCtrl.text = cfg.name;
    _startDeltaCtrl.text = cfg.startDeltaWatts.toString();
    _startConfirmCtrl.text = cfg.startConfirmSeconds.toString();
    _startDropoutCtrl.text = cfg.startDropoutTolerance.toString();
    _endDeltaCtrl.text = cfg.endDeltaWatts.toString();
    _endConfirmCtrl.text = cfg.endConfirmSeconds.toString();
    _minEffortCtrl.text = cfg.minEffortSeconds.toString();
    _baselineWindowCtrl.text = cfg.preEffortBaselineWindow.toString();
    _trailingWindowCtrl.text = cfg.inEffortTrailingWindow.toString();
  }

  void _onPresetChanged(_Preset? p) {
    if (p == null) return;
    setState(() => _preset = p);
    switch (p) {
      case _Preset.shortSprint:
        _loadConfig(AutoLapConfig.shortSprint());
      case _Preset.flying200:
        _loadConfig(AutoLapConfig.flying200());
      case _Preset.teamSprint:
        _loadConfig(AutoLapConfig.teamSprint());
      case _Preset.custom:
        break;
    }
  }

  void _onFieldEdited() {
    if (_preset != _Preset.custom) {
      setState(() => _preset = _Preset.custom);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final config = AutoLapConfig(
      id: 'user_default',
      name: _nameCtrl.text.trim(),
      startDeltaWatts: double.tryParse(_startDeltaCtrl.text) ?? 200,
      startConfirmSeconds: int.tryParse(_startConfirmCtrl.text) ?? 2,
      startDropoutTolerance: int.tryParse(_startDropoutCtrl.text) ?? 1,
      endDeltaWatts: double.tryParse(_endDeltaCtrl.text) ?? 150,
      endConfirmSeconds: int.tryParse(_endConfirmCtrl.text) ?? 5,
      minEffortSeconds: int.tryParse(_minEffortCtrl.text) ?? 3,
      preEffortBaselineWindow: int.tryParse(_baselineWindowCtrl.text) ?? 15,
      inEffortTrailingWindow: int.tryParse(_trailingWindowCtrl.text) ?? 10,
      isDefault: true,
    );

    final repo = ref.read(rideRepositoryProvider);
    await repo.saveAutoLapConfig(config);
    ref.invalidate(autoLapConfigProvider);

    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(autoLapConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Auto-Lap Config')),
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: _buildForm,
      ),
    );
  }

  Widget _buildForm(AutoLapConfig current) {
    // Seed fields on first build.
    if (_nameCtrl.text.isEmpty) {
      _loadConfig(current);
      _preset = _detectPreset(current);
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Preset', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<_Preset>(
            segments: const [
              ButtonSegment(value: _Preset.shortSprint, label: Text('Short')),
              ButtonSegment(value: _Preset.flying200, label: Text('Flying')),
              ButtonSegment(value: _Preset.teamSprint, label: Text('Team')),
              ButtonSegment(value: _Preset.custom, label: Text('Custom')),
            ],
            selected: {_preset},
            onSelectionChanged: (s) => _onPresetChanged(s.first),
          ),
          const SizedBox(height: 24),
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
            tooltip: 'Power increase above baseline to '
                'trigger effort start',
            isDouble: true,
          ),
          _field(
            _startConfirmCtrl,
            'Confirm Seconds',
            tooltip: 'Seconds power must stay elevated '
                'to confirm start',
          ),
          _field(
            _startDropoutCtrl,
            'Dropout Tolerance',
            tooltip: 'Allowed null readings during '
                'start confirmation',
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
            tooltip: 'Power decrease from trailing avg '
                'to trigger effort end',
            isDouble: true,
          ),
          _field(
            _endConfirmCtrl,
            'Confirm Seconds',
            tooltip: 'Seconds power must stay low '
                'to confirm end',
          ),
          const SizedBox(height: 16),
          const Text('Effort', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _field(
            _minEffortCtrl,
            'Min Effort Seconds',
            tooltip: 'Efforts shorter than this '
                'are discarded',
          ),
          _field(
            _baselineWindowCtrl,
            'Baseline Window',
            tooltip: 'Seconds to average before effort '
                'for baseline',
          ),
          _field(
            _trailingWindowCtrl,
            'Trailing Window',
            tooltip: 'Seconds to track decay '
                'during effort',
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
                : const Text('Save as Default'),
          ),
        ],
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
        onChanged: (_) => _onFieldEdited(),
        validator: (v) {
          if (v == null || v.trim().isEmpty) {
            return 'Required';
          }
          if (isDouble) {
            if (double.tryParse(v) == null) return 'Invalid';
          } else if (label != 'Name') {
            if (int.tryParse(v) == null) return 'Invalid';
          }
          return null;
        },
      ),
    );
  }

  static _Preset _detectPreset(AutoLapConfig cfg) {
    final ss = AutoLapConfig.shortSprint();
    if (_matches(cfg, ss)) return _Preset.shortSprint;
    final f2 = AutoLapConfig.flying200();
    if (_matches(cfg, f2)) return _Preset.flying200;
    final ts = AutoLapConfig.teamSprint();
    if (_matches(cfg, ts)) return _Preset.teamSprint;
    return _Preset.custom;
  }

  static bool _matches(AutoLapConfig a, AutoLapConfig b) {
    return a.startDeltaWatts == b.startDeltaWatts &&
        a.startConfirmSeconds == b.startConfirmSeconds &&
        a.startDropoutTolerance == b.startDropoutTolerance &&
        a.endDeltaWatts == b.endDeltaWatts &&
        a.endConfirmSeconds == b.endConfirmSeconds &&
        a.minEffortSeconds == b.minEffortSeconds &&
        a.preEffortBaselineWindow == b.preEffortBaselineWindow &&
        a.inEffortTrailingWindow == b.inEffortTrailingWindow;
  }
}
