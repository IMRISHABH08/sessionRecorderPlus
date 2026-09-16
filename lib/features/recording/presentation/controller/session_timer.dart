import 'dart:async';

import 'package:flutter/foundation.dart';

class SessionTimer {
  SessionTimer({required this.cap});

  final Duration cap;

  Timer? _capTimer;
  Timer? _ticker;
  DateTime? _startedAt;

  final ValueNotifier<Duration> remaining = ValueNotifier<Duration>(
    Duration.zero,
  );

  Duration get elapsed => _startedAt == null
      ? Duration.zero
      : DateTime.now().difference(_startedAt!);

  void start(VoidCallback onCap) {
    _startedAt = DateTime.now();
    remaining.value = cap;
    _capTimer = Timer(cap, () {
      _ticker?.cancel();
      onCap();
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = cap - elapsed;
      remaining.value = left.isNegative ? Duration.zero : left;
    });
  }

  void cancel() {
    _capTimer?.cancel();
    _ticker?.cancel();
    _capTimer = null;
    _ticker = null;
  }

  void dispose() {
    cancel();
    remaining.dispose();
  }
}
