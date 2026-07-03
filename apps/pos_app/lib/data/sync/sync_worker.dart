import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:pos_core/pos_core.dart';

import '../api/pos_api.dart';
import '../database/app_database.dart';
import '../database/tables.dart';
import 'sync_models.dart';
import 'sync_queue_dao.dart';

enum WorkerState { idle, running, offline, error }

class SyncStatus {
  const SyncStatus({
    required this.state,
    required this.pending,
    this.lastSyncAt,
    this.lastError,
  });
  final WorkerState state;
  final int pending;
  final DateTime? lastSyncAt;
  final String? lastError;
}

class SyncWorker {
  SyncWorker({
    required this.db,
    required this.api,
    required this.logger,
  }) : dao = SyncQueueDao(db);

  final AppDatabase db;
  final PosApi api;
  final AppLogger logger;
  final SyncQueueDao dao;

  Timer? _ticker;
  StreamSubscription? _conn;
  bool _running = false;
  WorkerState _state = WorkerState.idle;
  DateTime? _lastSyncAt;
  String? _lastError;

  final _statusCtrl = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get status => _statusCtrl.stream;

  Future<void> start() async {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => _tick());
    _conn = Connectivity().onConnectivityChanged.listen((event) {
      if (event.any((c) => c != ConnectivityResult.none)) {
        _tick();
      }
    });
    unawaited(_tick());
  }

  Future<void> stop() async {
    _ticker?.cancel();
    await _conn?.cancel();
    await _statusCtrl.close();
  }

  Future<void> flush() => _tick(force: true);

  Future<void> _tick({bool force = false}) async {
    if (_running && !force) return;
    _running = true;
    try {
      final pending = await dao.pendingCount();
      _emit(state: pending == 0 ? WorkerState.idle : WorkerState.running, pending: pending);
      if (pending == 0) return;

      final entries = await dao.dueEntries();
      for (final e in entries) {
        try {
          final ok = await _process(e);
          if (ok) {
            await dao.remove(e.id);
          } else {
            await dao.markRetry(e.id, e.retries + 1, _lastError);
          }
        } catch (err, st) {
          logger.warn('sync entry ${e.id} failed', err, st);
          await dao.markRetry(e.id, e.retries + 1, err.toString());
          _lastError = err.toString();
        }
      }
      _lastSyncAt = DateTime.now();
      _emit(
        state: WorkerState.idle,
        pending: await dao.pendingCount(),
      );
    } catch (e, st) {
      _lastError = e.toString();
      logger.error('sync tick failed', e, st);
      _emit(state: WorkerState.error, pending: await dao.pendingCount());
    } finally {
      _running = false;
    }
  }

  Future<bool> _process(SyncQueueRow e) async {
    final op = SyncOpKindCode.fromCode(e.op);
    final payload = (jsonDecode(e.payloadJson) as Map).cast<String, dynamic>();

    try {
      switch (op) {
        case SyncOpKind.uploadOrder:
          final res = await api.uploadOrder(payload);
          await _markOrderSynced(
            payload['id'] as String,
            orderNo: res['order_no'] as String?,
          );
        case SyncOpKind.uploadRefund:
          final orderId = payload['order_id'] as String;
          await api.refundOrder(orderId, payload);
        case SyncOpKind.uploadInventoryMovement:
          await api.postMovement(payload);
        case SyncOpKind.issueInvoice:
          final res = await api.issueInvoice(payload);
          await _stampInvoice(res);
        case SyncOpKind.voidInvoice:
          await api.voidInvoice(payload);
        case SyncOpKind.capturePayment:
          await api.charge(payload);
        case SyncOpKind.refundPayment:
          // Routed through orders/refunds path on the server
          await api.refundOrder(payload['order_id'] as String, payload);
        case SyncOpKind.upsertMember:
          await api.createMember(payload);
        case SyncOpKind.recordPoints:
          await api.charge(payload); // overload not relevant; placeholder
      }
      return true;
    } on DioException catch (e) {
      // 4xx (except 401/408/429) => give up, don't retry forever
      final code = e.response?.statusCode ?? 0;
      if (code == 409) {
        // already synced - treat as success
        return true;
      }
      if (code >= 400 && code < 500 && code != 401 && code != 408 && code != 429) {
        _lastError = 'permanent ${e.response?.statusCode}: ${e.response?.data}';
        return true; // remove from queue but log
      }
      _lastError = e.message;
      return false;
    }
  }

  Future<void> _markOrderSynced(String orderId, {String? orderNo}) async {
    await (db.update(db.orders)..where((t) => t.id.equals(orderId))).write(
          OrdersCompanion(
            syncedAt: Value(DateTime.now()),
            orderNo: orderNo == null || orderNo.isEmpty ? const Value.absent() : Value(orderNo),
          ),
        );
  }

  Future<void> _stampInvoice(Map<String, dynamic> res) async {
    final id = res['id'] as String?;
    final number = res['invoice_number'] as String?;
    if (id == null) return;
    await (db.update(db.invoices)..where((t) => t.id.equals(id))).write(InvoicesCompanion(
      status: const Value('issued'),
      invoiceNumber: Value(number),
      invoiceDate: Value(
        res['invoice_date'] != null ? DateTime.parse(res['invoice_date'] as String) : null,
      ),
      randomCode: Value(res['random_code'] as String?),
      barcode: Value(res['barcode'] as String?),
      qrLeft: Value(res['qr_left'] as String?),
      qrRight: Value(res['qr_right'] as String?),
    ));
    if (number != null) {
      final orderId = res['order_id'] as String?;
      if (orderId != null) {
        await (db.update(db.orders)..where((t) => t.id.equals(orderId)))
            .write(OrdersCompanion(invoiceNumber: Value(number)));
      }
    }
  }

  void _emit({required WorkerState state, required int pending}) {
    _state = state;
    if (_statusCtrl.isClosed) return;
    _statusCtrl.add(SyncStatus(
      state: state,
      pending: pending,
      lastSyncAt: _lastSyncAt,
      lastError: _lastError,
    ));
  }

  WorkerState get currentState => _state;
}
