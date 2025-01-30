class RouteException implements Exception {
  final String message;
  final dynamic error;

  RouteException(this.message, [this.error]);

  @override
  String toString() {
    if (error != null) {
      return 'RouteException: $message (Error: $error)';
    }
    return 'RouteException: $message';
  }
}