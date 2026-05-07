import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'delta_puller.dart';
import 'sync_queue_dao.dart';
import 'sync_worker.dart';

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
