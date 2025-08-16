import 'package:desk_switch/core/utils/logger.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DebugObserver extends ProviderObserver {
  const DebugObserver();

  @override
  void didAddProvider(
    ProviderObserverContext context,
    Object? value,
  ) {
    logger.info('Provider ${context.provider} was initialized with $value');
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    logger.info('Provider ${context.provider} was disposed');
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    // logger.info(
    //   'Provider ${context.provider} updated from $previousValue to $newValue',
    // );
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    logger.error(
      'Provider ${context.provider} threw $error at $stackTrace',
    );
  }
}
