import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/widgets/expand_chevron.dart';
import '../../../domain/entities/session_chunk.dart';
import '../../shared/session_metrics_details.dart';
import '../../shared/stat_tile.dart';
import 'chunk_status_chip.dart';

FaIconData _iconForApproach(String approachName) {
  if (approachName.contains('Hybrid')) return FontAwesomeIcons.tableCells;
  if (approachName.contains('widget_recorder_plus')) return FontAwesomeIcons.video;
  return FontAwesomeIcons.cloud;
}

// Custom expand/collapse rather than ExpansionTile: ExpansionTile's
// title/subtitle/trailing all share one row, which squeezes a long
// approach name against the status chip and forces it to wrap. Splitting
// the name and the time+chip onto their own rows gives each all the width
// it needs.
class ChunkTile extends StatefulWidget {
  const ChunkTile({super.key, required this.chunk, required this.onRetry});

  final SessionChunk chunk;
  final VoidCallback onRetry;

  @override
  State<ChunkTile> createState() => _ChunkTileState();
}

class _ChunkTileState extends State<ChunkTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chunk = widget.chunk;
    final isFailed = chunk.status.isFailed;
    final hasDriveLinks =
        chunk.status.isSucceeded &&
        chunk.driveLinks != null &&
        chunk.driveLinks!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: FaIcon(
                          _iconForApproach(chunk.approachName),
                          color: scheme.primary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          chunk.approachName,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.solidClock,
                        size: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat.Hm().format(chunk.capturedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      ChunkStatusChip(status: chunk.status),
                      const SizedBox(width: 10),
                      ExpandChevron(expanded: _expanded),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  // Chunk identity/metadata — the same data uploaded in the
                  // Drive file's description field, surfaced here too.
                  StatTile(
                    icon: FontAwesomeIcons.mapPin,
                    label: AppStrings.chunkScreenLabel,
                    value: chunk.screenName,
                  ),
                  const Divider(height: 1),
                  StatTile(
                    icon: FontAwesomeIcons.listOl,
                    label: AppStrings.chunkIndexLabel,
                    value: '${chunk.indexValue}',
                  ),
                  const Divider(height: 1),
                  StatTile(
                    icon: FontAwesomeIcons.fingerprint,
                    label: AppStrings.chunkIdLabel,
                    value: chunk.id,
                  ),
                  const Divider(height: 1),
                  SessionMetricsDetails(
                    metrics: chunk.metrics,
                    localArtifacts: chunk.localArtifacts,
                  ),
                  if (isFailed) ...[
                    const SizedBox(height: 16),
                    if (chunk.errorMessage != null)
                      Text(
                        chunk.errorMessage!,
                        style: TextStyle(color: scheme.error),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: widget.onRetry,
                      icon: const FaIcon(FontAwesomeIcons.arrowRotateRight, size: 14),
                      label: const Text(AppStrings.retryUploadButton),
                    ),
                  ],
                  if (hasDriveLinks) ...[
                    const SizedBox(height: 12),
                    for (final link in chunk.driveLinks!)
                      InkWell(
                        onTap: () => launchUrl(
                          Uri.parse(link),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.arrowUpRightFromSquare,
                                size: 14,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  link,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: scheme.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
