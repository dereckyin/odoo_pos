import 'package:pos_core/pos_core.dart';

enum SyncOp {
  uploadOrder,
  uploadRefund,
  uploadInventoryMovement,
  uploadTransfer,
  uploadStocktake,
  uploadMember,
  uploadPointTx,
  issueInvoice,
  voidInvoice,
  capturePayment,
  refundPayment,
}

class SyncQueueEntry {
  const SyncQueueEntry({
    required this.id,
    required this.op,
    required this.payload,
    required this.createdAt,
    required this.retries,
    required this.nextRetryAt,
    this.lastError,
  });

  final String id;
  final SyncOp op;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retries;
  final DateTime nextRetryAt;
  final String? lastError;
}

enum SyncWorkerState { idle, running, offline, error }

class SyncStatus {
  const SyncStatus({
    required this.state,
    required this.pendingCount,
    required this.lastSyncAt,
    this.lastError,
  });

  final SyncWorkerState state;
  final int pendingCount;
  final DateTime? lastSyncAt;
  final String? lastError;
}

abstract interface class SyncRepository {
  Future<Result<void>> enqueue(SyncOp op, Map<String, dynamic> payload);
  Future<Result<int>> pendingCount();
  Stream<SyncStatus> watchStatus();
  Future<Result<void>> flush();
  Future<Result<void>> pullDelta();
}
