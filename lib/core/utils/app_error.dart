class AppError {
  final String message;
  final String? parsedStackTrace;
  AppError(this.message, [this.parsedStackTrace]);
}
