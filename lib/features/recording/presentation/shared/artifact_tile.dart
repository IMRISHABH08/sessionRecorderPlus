import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/widgets/expand_chevron.dart';
import '../../domain/entities/recording_session_result.dart';
import 'format_utils.dart';

// JSON artifacts expand in place to show their (pretty-printed) content on
// tap; other kinds (video, screenshot) just show as a plain row.
class ArtifactTile extends StatefulWidget {
  const ArtifactTile({super.key, required this.artifact});

  final LocalArtifact artifact;

  @override
  State<ArtifactTile> createState() => _ArtifactTileState();
}

class _ArtifactTileState extends State<ArtifactTile> {
  bool _expanded = false;
  bool _loading = false;
  String? _content;

  bool get _isJson => widget.artifact.kind == ArtifactKind.timelineJson;

  Future<void> _toggle() async {
    if (!_isJson) return;
    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }
    setState(() {
      _expanded = true;
      _loading = _content == null;
    });
    if (_content != null) return;
    String pretty;
    try {
      final raw = await File(widget.artifact.path).readAsString();
      pretty = const JsonEncoder.withIndent('  ').convert(jsonDecode(raw));
    } catch (e) {
      pretty = 'Could not read file: $e';
    }
    if (mounted) {
      setState(() {
        _content = pretty;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _isJson ? _toggle : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                FaIcon(iconForArtifactKind(widget.artifact.kind), size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.artifact.path.split('/').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatBytes(widget.artifact.sizeBytes),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                // Fixed-width trailing slot (chevron or blank) so the size
                // column lines up across rows regardless of artifact kind.
                SizedBox(
                  width: 20,
                  child: _isJson
                      ? Align(
                          alignment: Alignment.centerRight,
                          child: ExpandChevron(expanded: _expanded, size: 12),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(4),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : SelectableText(
                    _content ?? '',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
          ),
      ],
    );
  }
}
