import 'package:equatable/equatable.dart';

enum RecorderEventType {
  screenEnter,
  screenExit,
  tap,
  longPress,
  significantScroll,
  navigation,
  dialogOpen,
  dialogClose,
  bottomSheetOpen,
  bottomSheetClose,
  textInputCompleted,
  loadingStart,
  loadingEnd,
  error,
  uiStateChanged,
}

extension RecorderEventTypeWireName on RecorderEventType {
  String get wireName => switch (this) {
    RecorderEventType.screenEnter => 'SCREEN_ENTER',
    RecorderEventType.screenExit => 'SCREEN_EXIT',
    RecorderEventType.tap => 'TAP',
    RecorderEventType.longPress => 'LONG_PRESS',
    RecorderEventType.significantScroll => 'SIGNIFICANT_SCROLL',
    RecorderEventType.navigation => 'NAVIGATION',
    RecorderEventType.dialogOpen => 'DIALOG_OPEN',
    RecorderEventType.dialogClose => 'DIALOG_CLOSE',
    RecorderEventType.bottomSheetOpen => 'BOTTOM_SHEET_OPEN',
    RecorderEventType.bottomSheetClose => 'BOTTOM_SHEET_CLOSE',
    RecorderEventType.textInputCompleted => 'TEXT_INPUT_COMPLETED',
    RecorderEventType.loadingStart => 'LOADING_START',
    RecorderEventType.loadingEnd => 'LOADING_END',
    RecorderEventType.error => 'ERROR',
    RecorderEventType.uiStateChanged => 'UI_STATE_CHANGED',
  };
}

class RecorderEvent extends Equatable {
  const RecorderEvent(this.type, this.timestamp, {this.data = const {}});

  final RecorderEventType type;
  final DateTime timestamp;

  // Per-type extras: target/offset/delta/field, matching the wire schema.
  final Map<String, dynamic> data;

  @override
  List<Object?> get props => [type, timestamp, data];
}
