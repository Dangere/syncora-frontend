class AppError {
  final String message;
  final StackTrace? parsedStackTrace;
  AppError(this.message, [this.parsedStackTrace]);
}
