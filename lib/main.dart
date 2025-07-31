import 'dart:io';

import 'package:desk_switch/core/utils/logger.dart';
import 'package:desk_switch/core/utils/observer.dart';
import 'package:desk_switch/l10n/app_localizations.dart';
import 'package:desk_switch/router/app_router.dart';
import 'package:desk_switch/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow();

  // Set window properties
  await windowManager.setTitle('DeskSwitch');
  await windowManager.setSize(const Size(800, 600));
  await windowManager.setMinimumSize(const Size(800, 600));
  await windowManager.setMaximumSize(const Size(800, 600));
  await windowManager.setResizable(false);
  await windowManager.center();

  /// Handles errors caught within Flutter framework
  FlutterError.onError = (details) async {
    // FlutterError.presentError(details);
    // await crashlytics?.recordFlutterError(details);
    logger.error(
      'FlutterError',
      error: details.exception,
      stackTrace: details.stack,
    );

    /// Crashes app when error occurs in release mode
    if (kReleaseMode) exit(1);
  };

  /// Passes all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    // crashlytics?.recordError(error, stack);
    // logger.shout('crash', error, stack);
    logger.error(
      'PlatformDispatcherError',
      error: error,
      stackTrace: stack,
    );

    /// Crashes app when error occurs in release mode
    if (kReleaseMode) exit(1);
    return true;
  };

  runApp(
    const ProviderScope(
      observers: [if (kDebugMode) DebugObserver()],
      child: DeskSwitchApp(),
    ),
  );
}

class DeskSwitchApp extends ConsumerWidget {
  const DeskSwitchApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final theme = ref.watch(appThemeProvider);

    return MaterialApp.router(
      title: 'DeskSwitch',
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: theme.lightTheme,
      darkTheme: theme.darkTheme,
    );
  }
}
