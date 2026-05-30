import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/api/dto.dart';
import '../../../data/printer/escpos_service.dart';
import '../../../data/printer/printer_providers.dart';

/// Snapshot of guest orders shown on the KDS board, grouped by lifecycle
/// state. The board polls every few seconds (a WebSocket push is a future
/// optimisation; UI doesn't change).
class GuestOrdersSnapshot {
  GuestOrdersSnapshot({
    this.orders = const [],
    this.lastError,
    this.lastFetched,
  });

  final List<GuestOrderDto> orders;
  final String? lastError;
  final DateTime? lastFetched;

  List<GuestOrderDto> ofStatus(String status) =>
      orders.where((o) => o.status == status).toList();

  GuestOrdersSnapshot copyWith({
    List<GuestOrderDto>? orders,
    String? lastError,
    DateTime? lastFetched,
    bool clearError = false,
  }) {
    return GuestOrdersSnapshot(
      orders: orders ?? this.orders,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastFetched: lastFetched ?? this.lastFetched,
    );
  }
}

class GuestOrdersController extends StateNotifier<GuestOrdersSnapshot> {
  GuestOrdersController(this._ref) : super(GuestOrdersSnapshot());

  final Ref _ref;
  Timer? _timer;

  /// Begin polling the staff guest-orders endpoint. Safe to call multiple
  /// times; only one timer is kept alive.
  void startPolling({Duration interval = const Duration(seconds: 3)}) {
    if (_timer?.isActive ?? false) return;
    refresh();
    _timer = Timer.periodic(interval, (_) => refresh());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh() async {
    final session = _ref.read(authStateProvider).session;
    if (session == null) return;
    try {
      final api = _ref.read(posApiProvider);
      final list = await api.listGuestOrders(
        storeId: session.storeId,
        statusIn: 'submitted,accepted,ready',
      );
      state = state.copyWith(
        orders: list,
        lastFetched: DateTime.now(),
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(lastError: e.toString());
    }
  }

  /// Accept a submitted guest order: kitchen ticket prints first; only on
  /// successful print (or printer disabled) do we advance the state. This
  /// avoids a foot-gun where the kitchen taps "accept" but never sees a
  /// paper ticket.
  Future<GuestOrderDto> accept(GuestOrderDto order) async {
    final printer = _ref.read(kitchenPrinterServiceProvider);
    final ticket = KitchenTicket(
      guestOrderId: order.id,
      tableLabel: order.tableLabel ?? '?',
      placedAt: order.createdAt,
      partySize: order.partySize,
      note: order.customerNote,
      lines: order.lines
          .map((l) => KitchenTicketLine(
                name: l.productName,
                qty: l.qty,
                note: l.note,
              ))
          .toList(),
    );
    await printer.printTicket(ticket); // throws if I/O fails

    final api = _ref.read(posApiProvider);
    final updated = await api.acceptGuestOrder(order.id);
    _replace(updated);
    return updated;
  }

  Future<GuestOrderDto> markReady(GuestOrderDto order) async {
    final api = _ref.read(posApiProvider);
    final updated = await api.markGuestOrderReady(order.id);
    _replace(updated);
    return updated;
  }

  /// Print kitchen ticket, accept, then mark ready — for cashier-all-in-one flow.
  Future<GuestOrderDto> acceptAndReady(GuestOrderDto order) async {
    final accepted = await accept(order);
    return markReady(accepted);
  }

  Future<void> cancel(GuestOrderDto order, {String? reason}) async {
    final api = _ref.read(posApiProvider);
    final updated = await api.cancelGuestOrder(order.id, reason: reason);
    _replace(updated);
  }

  void _replace(GuestOrderDto updated) {
    final next = [
      for (final o in state.orders)
        if (o.id == updated.id) updated else o,
    ];
    if (!next.any((o) => o.id == updated.id)) next.add(updated);
    state = state.copyWith(orders: next);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final guestOrdersControllerProvider =
    StateNotifierProvider<GuestOrdersController, GuestOrdersSnapshot>(
  (ref) => GuestOrdersController(ref),
);
