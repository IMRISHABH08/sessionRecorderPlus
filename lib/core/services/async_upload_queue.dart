import 'package:flutter/foundation.dart';

import 'async_queue.dart';

class AsyncUploadQueue implements AsyncQueue {
  AsyncUploadQueue({this.onQueueEmpty});

  final void Function()? onQueueEmpty;

  final List<_QueueItem> _queue = [];
  bool _processing = false;

  @override
  void enqueue(Future<void> Function() operation) {
    _queue.add(_QueueItem(operation));
    if (!_processing) _process();
  }

  Future<void> _process() async {
    _processing = true;
    while (_queue.isNotEmpty) {
      final item = _queue.first;
      try {
        await item.operation();
        _queue.removeAt(0);
      } catch (e) {
        item.attempts++;
        if (item.attempts >= _QueueItem.maxAttempts) {
          debugPrint(
            '[AsyncUploadQueue] Dropped after ${_QueueItem.maxAttempts} attempts: $e',
          );
          _queue.removeAt(0);
        }
      }
    }
    _processing = false;
    onQueueEmpty?.call();
  }
}

class _QueueItem {
  _QueueItem(this.operation);

  final Future<void> Function() operation;
  int attempts = 0;
  static const maxAttempts = 3;
}
