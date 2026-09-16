import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../../core/widgets/pill_chip.dart';
import '../../../domain/entities/session_chunk.dart';

class ChunkStatusChip extends StatelessWidget {
  const ChunkStatusChip({super.key, required this.status});

  final ChunkUploadStatus status;

  (FaIconData, Color) _visuals(ColorScheme scheme) => switch (status) {
    ChunkUploadStatus.queued => (
      FontAwesomeIcons.clock,
      scheme.onSurfaceVariant,
    ),
    ChunkUploadStatus.uploading => (
      FontAwesomeIcons.cloudArrowUp,
      scheme.primary,
    ),
    ChunkUploadStatus.succeeded => (FontAwesomeIcons.circleCheck, Colors.green),
    ChunkUploadStatus.failed => (
      FontAwesomeIcons.triangleExclamation,
      scheme.error,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _visuals(Theme.of(context).colorScheme);
    return PillChip(icon: icon, label: status.name, color: color);
  }
}
