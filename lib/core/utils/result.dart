class Result<T> {
  final T? data;
  final String? error;

  Result({this.data, this.error});

  bool get isSuccess => error == null;

  // Helper methods to make the API cleaner
  static Result<T> success<T>(T data) => Result<T>(data: data);

  static Result<T> failure<T>(String error) => Result<T>(error: error);
}
