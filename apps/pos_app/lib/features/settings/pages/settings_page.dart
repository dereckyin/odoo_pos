import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../theme/theme_controller.dart';
import 'printer_settings_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final session = ref.watch(authStateProvider).session;
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          const ListTile(title: Text('外觀'), dense: true),
          RadioListTile<ThemeMode>(
            title: const Text('跟隨系統'),
            value: ThemeMode.system,
            groupValue: mode,
            onChanged: (v) => v == null ? null : ref.read(themeModeProvider.notifier).state = v,
          ),
          RadioListTile<ThemeMode>(
            title: const Text('淺色'),
            value: ThemeMode.light,
            groupValue: mode,
            onChanged: (v) => v == null ? null : ref.read(themeModeProvider.notifier).state = v,
          ),
          RadioListTile<ThemeMode>(
            title: const Text('深色'),
            value: ThemeMode.dark,
            groupValue: mode,
            onChanged: (v) => v == null ? null : ref.read(themeModeProvider.notifier).state = v,
          ),
          const Divider(),
          const ListTile(title: Text('帳號'), dense: true),
          if (session != null)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(session.displayName),
              subtitle: Text('${session.username}・${session.role}'),
              trailing: TextButton(
                onPressed: () => ref.read(authStateProvider.notifier).logout(),
                child: const Text('登出'),
              ),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud_sync_outlined),
            title: const Text('同步狀態'),
            onTap: () => context.push('/sync'),
          ),
          ListTile(
            leading: const Icon(Icons.print_outlined),
            title: const Text('印表機'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const PrinterSettingsPage(),
            )),
          ),
        ],
      ),
    );
  }
}
