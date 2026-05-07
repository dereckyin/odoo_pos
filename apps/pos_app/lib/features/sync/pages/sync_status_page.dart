import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../../data/sync/sync_providers.dart';
import '../../../data/sync/sync_worker.dart';

class SyncStatusPage extends ConsumerWidget {
  const SyncStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStatus = ref.watch(syncStatusProvider);
    final pending = ref.watch(pendingSyncCountProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('同步狀態')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            asyncStatus.maybeWhen(
              data: (s) => Card(
                child: ListTile(
                  leading: Icon(_iconFor(s.state)),
                  title: Text(_textFor(s.state)),
                  subtitle: Text('待同步 ${s.pending} 筆'
                      '${s.lastSyncAt == null ? '' : '・上次成功 ${s.lastSyncAt}'}'
                      '${s.lastError == null ? '' : '\n錯誤: ${s.lastError}'}'),
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            pending.maybeWhen(
              data: (n) => Text('當前佇列: $n', style: Theme.of(context).textTheme.titleMedium),
              orElse: () => const SizedBox.shrink(),
            ),
            const Spacer(),
            BigButton(
              icon: Icons.cloud_sync_outlined,
              label: '立即同步',
              onPressed: () => ref.read(syncWorkerProvider).flush(),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(WorkerState s) => switch (s) {
        WorkerState.idle => Icons.cloud_done_outlined,
        WorkerState.running => Icons.sync,
        WorkerState.offline => Icons.cloud_off_outlined,
        WorkerState.error => Icons.error_outline,
      };

  static String _textFor(WorkerState s) => switch (s) {
        WorkerState.idle => '已同步',
        WorkerState.running => '同步中…',
        WorkerState.offline => '離線',
        WorkerState.error => '錯誤',
      };
}
