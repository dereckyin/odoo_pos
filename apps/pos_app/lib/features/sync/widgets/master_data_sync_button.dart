import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/sync/delta_puller.dart';
import '../../../data/sync/sync_providers.dart';

class MasterDataSyncButton extends ConsumerWidget {
  const MasterDataSyncButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(deltaPullStatusProvider);
    return status.when(
      data: (s) {
        final isSyncing = s.state == DeltaPullState.syncing;
        final tooltip = s.lastPullAt != null
            ? '上次同步: ${_formatTime(s.lastPullAt!)}'
            : '尚未同步';
        return IconButton(
          tooltip: isSyncing ? '同步中…' : '$tooltip（點擊立即同步）',
          icon: isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  s.state == DeltaPullState.error ? Icons.sync_problem : Icons.sync,
                  color: s.state == DeltaPullState.error
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
          onPressed: isSyncing
              ? null
              : () => ref.read(deltaPullerProvider).pullAll(),
        );
      },
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => IconButton(
        tooltip: '同步失敗，點擊重試',
        icon: Icon(Icons.sync_problem, color: Theme.of(context).colorScheme.error),
        onPressed: () => ref.read(deltaPullerProvider).pullAll(),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
