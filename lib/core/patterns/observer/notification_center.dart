typedef TripNotificationListener = void Function(String message);

class NotificationCenter {
  NotificationCenter._();

  static final NotificationCenter instance = NotificationCenter._();

  final List<TripNotificationListener> _listeners =
      <TripNotificationListener>[];

  void addListener(TripNotificationListener listener) {
    _listeners.add(listener);
  }

  void removeListener(TripNotificationListener listener) {
    _listeners.remove(listener);
  }

  void publish(String message) {
    for (final listener in List<TripNotificationListener>.of(_listeners)) {
      listener(message);
    }
  }
}
