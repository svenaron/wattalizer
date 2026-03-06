import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Intents for ride screen actions.

class SetFocusModeIntent extends Intent {
  const SetFocusModeIntent();
}

class SetChartModeIntent extends Intent {
  const SetChartModeIntent();
}

class ManualLapIntent extends Intent {
  const ManualLapIntent();
}

class StopRideIntent extends Intent {
  const StopRideIntent();
}

class StartRideIntent extends Intent {
  const StartRideIntent();
}

class OpenDeviceSheetIntent extends Intent {
  const OpenDeviceSheetIntent();
}

/// Keyboard shortcut map for the active ride screen.
const activeRideShortcuts = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.arrowLeft): SetFocusModeIntent(),
  SingleActivator(LogicalKeyboardKey.arrowRight): SetChartModeIntent(),
  SingleActivator(LogicalKeyboardKey.space): ManualLapIntent(),
  SingleActivator(LogicalKeyboardKey.escape): StopRideIntent(),
  SingleActivator(LogicalKeyboardKey.keyD): OpenDeviceSheetIntent(),
};

/// Keyboard shortcut map for the idle ride screen.
const idleRideShortcuts = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.enter): StartRideIntent(),
  SingleActivator(LogicalKeyboardKey.keyD): OpenDeviceSheetIntent(),
};
