import 'package:syncora_frontend/core/utils/result.dart';

typedef Func<T, TResult> = TResult Function(T arg);

typedef AsyncResultCallback<T> = Future<Result<T>> Function();

// A typedef that defines a function that takes in an OutboxEntry and AsyncResultCallback and returns a Future<Result<void>>
typedef OutBoxEnqueueFunc<OutboxEntry, AsyncResultCallback>
    = Future<Result<void>> Function(
        OutboxEntry entry, AsyncResultCallback onAfterEnqueue);
