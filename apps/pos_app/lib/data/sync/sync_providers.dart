import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../features/books/providers/consignment_providers.dart';
import 'delta_puller.dart';
import 'master_data_scope.dart';
import 'sync_queue_dao.dart';
import 'sync_worker.dart';

final masterDataScopeStoreProvider = Provider<MasterDataScopeStore>((ref) {
  return MasterDataScopeStore(ref.read(databaseProvider));
});

final syncQueueDaoProvider = Provider<SyncQueueDao>((ref) {
  return SyncQueueDao(ref.read(databaseProvider));
});

final pendingSyncCountProvider = StreamProvider<int>((ref) {
  return ref.read(syncQueueDaoProvider).watchPending();
});

final syncWorkerProvider = Provider<SyncWorker>((ref) {
  final w = SyncWorker(
    db: ref.read(databaseProvider),
    api: ref.read(posApiProvider),
    logger: ref.read(loggerProvider),
  );
  ref.onDispose(w.stop);
  return w;
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  return ref.read(syncWorkerProvider).status;
});

final deltaPullerProvider = Provider<DeltaPuller>((ref) {
  final puller = DeltaPuller(
    db: ref.read(databaseProvider),
    api: ref.read(posApiProvider),
    logger: ref.read(loggerProvider),
  );
  ref.onDispose(puller.stop);
  return puller;
});

final deltaPullStatusProvider = StreamProvider<DeltaPullStatus>((ref) {
  return ref.read(deltaPullerProvider).status;
});

final syncSessionLifecycleProvider = Provider<void>((ref) {
  ref.listen<AuthState>(authStateProvider, (previous, next) {
    final session = next.session;
    if (session == null || !next.isLoggedIn) return;

    unawaited((() async {
      await ref.read(masterDataScopeStoreProvider).applySessionScope(
            tenantId: session.tenantId,
            storeId: session.storeId,
          );
      ref.read(syncWorkerProvider).start();
      ref.read(deltaPullerProvider).startAfterLogin(storeId: session.storeId);
      await ref.read(consignmentPosConfigProvider.notifier).refresh();
    })());
  }, fireImmediately: true);
});
