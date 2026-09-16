import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/duration_chip.dart';
import '../../domain/entities/recorder_choice.dart';
import '../controller/playground_controller.dart';
import '../session_summary/session_summary_page.dart';
import 'components/playground_header.dart';
import 'item_detail_page.dart';

class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({super.key, required this.choice});

  final RecorderChoice choice;

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  late final PlaygroundController _controller;

  @override
  void initState() {
    super.initState();
    _controller = createPlaygroundController(widget.choice);
    _controller.addListener(_onControllerChanged);
    // Recording begins as a side effect of entering this screen — no
    // manual "start" action anywhere in this app.
    final started = _controller.start();
    // Registered synchronously here (not inside start()'s async body) so it
    // fires right after THIS first frame paints, not some indeterminate
    // later one — see the comment on PlaygroundController.fireScreenEnter.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await started;
      if (mounted) _controller.fireScreenEnter();
    });
  }

  void _onControllerChanged() {
    if (!_controller.hasEnded || !mounted) return;
    if (_controller.supportsChunking) {
      // Chunks are already queued for upload and browsable via Session
      // Info — there's nothing left to show on a dedicated summary page.
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    final result = _controller.result;
    if (result == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => SessionSummaryPage(result: result)),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showDialog() async {
    _controller.onDialogOpen();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.dialogAppearedTitle),
        content: const Text(AppStrings.dialogAppearedContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.closeButton),
          ),
        ],
      ),
    );
    _controller.onDialogClose();
  }

  void _handlePopAttempt(bool didPop, Object? result) {
    if (didPop) return;
    if (_controller.hasEnded) {
      Navigator.of(context).pop();
      return;
    }
    // Leaving via back button/gesture without tapping "End session" should
    // behave identically to tapping it — stop the recorder and flush
    // whatever chunk was in progress, instead of silently abandoning it.
    // Not awaited: navigation away happens from _onControllerChanged once
    // endSession()'s notifyListeners() fires, same path the button uses.
    _controller.endSession();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PlaygroundController>.value(
      value: _controller,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: _handlePopAttempt,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.choice.title),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: _controller.supportsChunking
                      ? DurationChip(
                          duration: _controller.elapsed,
                          avatar: FaIcon(
                            FontAwesomeIcons.solidCircle,
                            size: 10,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        )
                      : DurationChip(
                          duration: _controller.legacyTimer.remaining,
                          avatar: const FaIcon(
                            FontAwesomeIcons.stopwatch,
                            size: 16,
                          ),
                        ),
                ),
              ),
              IconButton(
                tooltip: AppStrings.endSessionTooltip,
                icon: const FaIcon(FontAwesomeIcons.circleStop),
                onPressed: _controller.endSession,
              ),
            ],
          ),
          // The captured RepaintBoundary wraps only this body, not the
          // Scaffold — so it needs its own opaque background fill. Without
          // this, "empty" regions inside the boundary (gaps, padding) are
          // genuinely transparent, and since video/JPEG have no alpha
          // channel, transparent encodes as solid black.
          body: _controller.recorder.wrapContent(
            ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: _buildContent(context),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showDialog,
            icon: const FaIcon(
              FontAwesomeIcons.arrowUpRightFromSquare,
              size: 18,
            ),
            label: const Text(AppStrings.showDialogButton),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SafeArea(
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            _controller.onScrollDelta(
              notification.scrollDelta ?? 0,
              notification.metrics.pixels,
            );
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PlaygroundHeader(
                onCtaTap: _controller.onCtaTap,
                applied: _controller.applied,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: 40,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final label =
                      '${AppStrings.scrollableItemPrefix} ${index + 1}';
                  return Card(
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(label),
                      subtitle: const Text(AppStrings.scrollableItemSubtitle),
                      onTap: () {
                        _controller.onItemTap(label);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ItemDetailPage(title: label),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
          ],
        ),
      ),
    );
  }
}
