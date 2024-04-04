import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/mutation.dart';
import 'package:fquery/src/mutation_observer.dart';

class UseMutationResult<TVariables, TData, TError> {
  final TData? data;
  final TError? error;
  final bool isIdle;
  final bool isPending;
  final bool isSuccess;
  final bool isError;
  final MutationStatus status;
  final Future<void> Function(TVariables) mutate;
  final DateTime? submittedAt;

  UseMutationResult({
    required this.data,
    required this.error,
    required this.status,
    required this.mutate,
    required this.submittedAt,
  })  : isIdle = status == MutationStatus.idle,
        isPending = status == MutationStatus.pending,
        isSuccess = status == MutationStatus.success,
        isError = status == MutationStatus.error;
}

class UseMutationOptions<TVariables, TData, TError> {
  final void Function(TData)? onMutate;
  final Future<TData> Function(TVariables) mutationFn;
  final void Function(TData, TVariables)? onSuccess;
  final void Function(TError, TVariables)? onError;
  final void Function(TData?, TError?, TVariables)? onSettled;

  UseMutationOptions({
    this.onMutate,
    required this.mutationFn,
    this.onSuccess,
    this.onError,
    this.onSettled,
  });
}

UseMutationResult<TVariables, TData, TError>
    useMutation<TVariables, TData, TError>(
  Future<TData> Function(TVariables) mutationFn, {
  void Function(TData)? onMutate,
  void Function(TData, TVariables)? onSuccess,
  void Function(TError, TVariables)? onError,
  void Function(TData?, TError?, TVariables)? onSettled,
}) {
  final options = useMemoized(
      () => UseMutationOptions(
            onMutate: onMutate,
            mutationFn: mutationFn,
            onSuccess: onSuccess,
            onError: onError,
            onSettled: onSettled,
          ),
      [
        onMutate,
        mutationFn,
        onSuccess,
        onError,
        onSettled,
      ]);
  final client = useQueryClient();
  final observer = useMemoized(
      () => MutationObserver<TVariables, TData, TError>(
            client: client,
            options: options,
          ),
      []);

  final mutate = useCallback(
    (TVariables variables) async {
      await observer.mutate(variables);
    },
    [observer],
  );

  // This subscribes to the observer
  // and rebuilds the widget on updates.
  useListenable(observer);

  return UseMutationResult(
    data: observer.mutation.state.data,
    error: observer.mutation.state.error,
    status: observer.mutation.state.status,
    mutate: mutate,
    submittedAt: observer.mutation.state.submittedAt,
  );
}
