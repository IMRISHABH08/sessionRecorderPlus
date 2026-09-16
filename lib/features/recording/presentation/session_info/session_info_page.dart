import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/session_chunk.dart';
import '../../domain/repository/session_chunk_repository.dart';
import '../../domain/usecase/chunk_upload_coordinator.dart';
import 'components/approach_filter_bar.dart';
import 'components/chunk_tile.dart';

class SessionInfoPage extends StatefulWidget {
  const SessionInfoPage({super.key});

  @override
  State<SessionInfoPage> createState() => _SessionInfoPageState();
}

class _SessionInfoPageState extends State<SessionInfoPage> {
  late final SessionChunkRepository _repo = getIt<SessionChunkRepository>();
  late final ChunkUploadCoordinator _coordinator =
      getIt<ChunkUploadCoordinator>();
  late final Future<void> _loading = _repo.ensureLoaded();

  String? _filter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.sessionInfoTitle)),
      body: FutureBuilder<void>(
        future: _loading,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return ValueListenableBuilder<List<SessionChunk>>(
            valueListenable: _repo.chunks,
            builder: (context, allChunks, _) {
              if (allChunks.isEmpty) {
                return const _EmptyState();
              }

              final approaches = allChunks.map((c) => c.approachName).toSet().toList()
                ..sort();
              final chunks = _filter == null
                  ? allChunks
                  : allChunks.where((c) => c.approachName == _filter).toList();

              return Column(
                children: [
                  const SizedBox(height: 12),
                  ApproachFilterBar(
                    approaches: approaches,
                    selected: _filter,
                    onSelected: (value) => setState(() => _filter = value),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: chunks.isEmpty
                        ? const _NoMatchesState()
                        : _ChunkList(chunks: chunks, coordinator: _coordinator),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ChunkList extends StatelessWidget {
  const _ChunkList({required this.chunks, required this.coordinator});

  final List<SessionChunk> chunks;
  final ChunkUploadCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    final groups = _groupByDate(chunks);
    return CustomScrollView(
      slivers: [
        for (final group in groups) ...[
          SliverPersistentHeader(
            pinned: true,
            delegate: _DateHeaderDelegate(group.date),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverList.list(
              children: [
                for (final chunk in group.chunks)
                  ChunkTile(
                    chunk: chunk,
                    onRetry: () => coordinator.retry(chunk),
                  ),
              ],
            ),
          ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }
}

class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  _DateHeaderDelegate(this.date);

  final DateTime date;

  @override
  double get minExtent => 44;

  @override
  double get maxExtent => 44;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Opaque background: this is pinned, so content scrolls underneath it.
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        DateFormat.yMMMd().format(date),
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DateHeaderDelegate oldDelegate) =>
      oldDelegate.date != date;
}

class _DateGroup {
  const _DateGroup(this.date, this.chunks);

  final DateTime date;
  final List<SessionChunk> chunks;
}

List<_DateGroup> _groupByDate(List<SessionChunk> chunks) {
  final map = <DateTime, List<SessionChunk>>{};
  for (final chunk in chunks) {
    final day = DateTime(
      chunk.capturedAt.year,
      chunk.capturedAt.month,
      chunk.capturedAt.day,
    );
    map.putIfAbsent(day, () => []).add(chunk);
  }
  return map.entries.map((e) => _DateGroup(e.key, e.value)).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.clockRotateLeft,
              size: 40,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.noSessionsYetTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.noSessionsYetDescription,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMatchesState extends StatelessWidget {
  const _NoMatchesState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        AppStrings.noSessionsForApproachTitle,
        style: TextStyle(color: scheme.onSurfaceVariant),
      ),
    );
  }
}
