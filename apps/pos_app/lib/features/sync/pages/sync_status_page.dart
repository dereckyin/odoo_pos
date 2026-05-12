import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../../data/sync/delta_puller.dart';
import '../../../data/sync/sync_providers.dart';
import '../../../data/sync/sync_worker.dart';

class SyncStatusPage extends ConsumerStatefulWidget {
  const SyncStatusPage({super.key});

  @override
  ConsumerState<SyncStatusPage> createState() => _SyncStatusPageState();
}

class _SyncStatusPageState extends ConsumerState<SyncStatusPage> {
  String? _downloadMessage;
  String? _uploadMessage;
  bool _downloading = false;
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    final asyncStatus = ref.watch(syncStatusProvider);
    final deltaStatus = ref.watch(deltaPullStatusProvider);
    final pending = ref.watch(pendingSyncCountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('同步狀態')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            deltaStatus.maybeWhen(
              data: (status) => Card(
                child: ListTile(
                  leading: Icon(_iconForDelta(status.state)),
                  title: const Text('主檔下載'),
                  subtitle: Text(
                    [
                      if (status.lastPullAt != null) '上次成功 ${status.lastPullAt}',
                      if (status.error != null) '錯誤: ${status.error}',
                      if (_downloadMessage != null) _downloadMessage!,
                    ].join('\n'),
                  ),
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            asyncStatus.maybeWhen(
              data: (status) => Card(
                child: ListTile(
                  leading: Icon(_iconForUpload(status.state)),
                  title: const Text('離線上傳'),
                  subtitle: Text(
                    [
                      '待同步 ${status.pending} 筆',
                      if (status.lastSyncAt != null) '上次成功 ${status.lastSyncAt}',
                      if (status.lastError != null) '錯誤: ${status.lastError}',
                      if (_uploadMessage != null) _uploadMessage!,
                    ].join('\n'),
                  ),
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
              icon: Icons.cloud_download_outlined,
              label: _downloading ? '下載主檔中…' : '下載主檔',
              onPressed: _downloading ? null : _downloadMasterData,
            ),
            const SizedBox(height: 12),
            BigButton(
              icon: Icons.cloud_upload_outlined,
              label: _uploading ? '上傳中…' : '上傳離線資料',
              onPressed: _uploading ? null : _uploadPending,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('完整重拉主檔'),
              onPressed: _downloading ? null : _confirmFullResync,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadMasterData() async {
    setState(() {
      _downloading = true;
      _downloadMessage = null;
    });
    final result = await ref.read(deltaPullerProvider).pullAll();
    if (!mounted) return;
    setState(() {
      _downloading = false;
      _downloadMessage = result.isSuccess ? '主檔下載完成' : result.summary;
    });
  }

  Future<void> _uploadPending() async {
    setState(() {
      _uploading = true;
      _uploadMessage = null;
    });
    await ref.read(syncWorkerProvider).flush();
    if (!mounted) return;
    setState(() {
      _uploading = false;
      _uploadMessage = '已嘗試上傳離線資料';
    });
  }

  Future<void> _confirmFullResync() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('完整重拉主檔'),
        content: const Text('將清空本機商品、分類、會員、促銷與庫存主檔，並重新從伺服器下載。本機訂單與待上傳佇列會保留。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('確認')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _downloading = true;
      _downloadMessage = null;
    });
    final result = await ref.read(deltaPullerProvider).pullAll(forceFullResync: true);
    if (!mounted) return;
    setState(() {
      _downloading = false;
      _downloadMessage = result.isSuccess ? '主檔已完整重拉' : result.summary;
    });
  }

  static IconData _iconForDelta(DeltaPullState state) => switch (state) {
        DeltaPullState.idle => Icons.cloud_done_outlined,
        DeltaPullState.syncing => Icons.sync,
        DeltaPullState.error => Icons.error_outline,
      };

  static IconData _iconForUpload(WorkerState state) => switch (state) {
        WorkerState.idle => Icons.cloud_done_outlined,
        WorkerState.running => Icons.sync,
        WorkerState.offline => Icons.cloud_off_outlined,
        WorkerState.error => Icons.error_outline,
      };
}
