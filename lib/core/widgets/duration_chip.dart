import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


class DurationChip extends StatelessWidget {
  const DurationChip({super.key, required this.duration, required this.avatar});

  final ValueListenable<Duration> duration;
  final Widget avatar;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: duration,
      builder: (context, value, _) {
        final minutes = value.inMinutes;
        final seconds = value.inSeconds % 60;
        return Chip(
          avatar: avatar,
          label: Text('$minutes:${seconds.toString().padLeft(2, '0')}'),
        );
      },
    );
  }
}
