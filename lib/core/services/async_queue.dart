abstract class AsyncQueue {
  void enqueue(Future<void> Function() operation);
}
