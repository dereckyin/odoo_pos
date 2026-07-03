import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import 'l10n/app_localizations.dart';
import 'routing/router.dart';
import 'data/printer/remote_print_job_worker.dart';
import 'data/sync/sync_providers.dart';
import 'theme/theme_controller.dart';

class PosApp extends ConsumerWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(syncSessionLifecycleProvider);
    ref.watch(printWorkstationLifecycleProvider);
    final router = ref.watch(routerProvider);
    final mode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: '點餐趣',
      debugShowCheckedModeBanner: false,
      theme: PosTheme.light(),
      darkTheme: PosTheme.dark(),
      themeMode: mode,
      locale: const Locale('zh', 'TW'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }
}
