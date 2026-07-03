import 'dart:math';

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import '../api/dto.dart';
import '../database/app_database.dart';
import 'escpos_service.dart';
import 'tspl_service.dart';

String optionsLabelFromJson(List<Map<String, dynamic>> optionsJson) {
  if (optionsJson.isEmpty) return '';
  final parts = <String>[];
  for (final o in optionsJson) {
    final group = o['group_name'] as String? ?? o['groupName'] as String?;
    final choice = o['choice_name'] as String? ?? o['choiceName'] as String? ?? o['name'] as String?;
    if (choice != null && choice.isNotEmpty) {
      parts.add(group != null && group.isNotEmpty ? '$group:$choice' : choice);
    }
  }
  return parts.join(' / ');
}

String orderRefShort(String id) => id.length >= 4 ? id.substring(id.length - 4) : id;

OrderConfirmation confirmationFromGuestOrder(GuestOrderDto order) => OrderConfirmation(
      tableLabel: order.displayTitle,
      placedAt: order.createdAt,
      orderRef: orderRefShort(order.id),
      note: order.customerNote,
      estimatedTotal: Money(order.estimatedSubtotalCents),
      lines: order.lines
          .map(
            (l) => OrderConfirmationLine(
              name: l.productName,
              qty: l.qty,
              lineTotal: Money(l.lineTotalCents),
              optionsLabel: optionsLabelFromJson(l.optionsJson),
              note: l.note,
            ),
          )
          .toList(),
    );

OrderConfirmation confirmationFromCart(Cart cart, {String? tableLabel}) => OrderConfirmation(
      tableLabel: tableLabel ?? '現場',
      placedAt: DateTime.now(),
      note: cart.note,
      estimatedTotal: cart.total,
      lines: cart.lines
          .map(
            (l) => OrderConfirmationLine(
              name: l.product.name,
              qty: l.qty,
              lineTotal: l.net,
              optionsLabel: l.selectedOptions.displayLabel,
              note: l.note,
            ),
          )
          .toList(),
    );

KitchenTicket kitchenTicketFromGuestOrder(GuestOrderDto order) => KitchenTicket(
      guestOrderId: order.id,
      tableLabel: order.displayTitle,
      placedAt: order.createdAt,
      partySize: order.partySize,
      note: order.customerNote,
      lines: order.lines
          .map(
            (l) => KitchenTicketLine(
              name: l.productName,
              qty: l.qty,
              note: l.note,
              optionsLabel: optionsLabelFromJson(l.optionsJson),
            ),
          )
          .toList(),
    );

KitchenTicket kitchenTicketFromCart(Cart cart, {String? tableLabel}) => KitchenTicket(
      guestOrderId: newUuid(),
      tableLabel: tableLabel ?? '現場',
      placedAt: DateTime.now(),
      note: cart.note,
      lines: cart.lines
          .map(
            (l) => KitchenTicketLine(
              name: l.product.name,
              qty: l.qty,
              note: l.note,
              optionsLabel: l.selectedOptions.displayLabel,
            ),
          )
          .toList(),
    );

List<DrinkLabel> drinkLabelsFromGuestOrder(
  GuestOrderDto order,
  Set<String> labelProductIds,
) {
  final labels = <DrinkLabel>[];
  final ref = orderRefShort(order.id);
  for (final line in order.lines) {
    if (!labelProductIds.contains(line.productId)) continue;
    final cups = max(1, line.qty.round());
    for (var i = 1; i <= cups; i++) {
      labels.add(
        DrinkLabel(
          productName: line.productName,
          tableLabel: order.displayTitle,
          orderRef: ref,
          placedAt: order.createdAt,
          cupIndex: i,
          cupTotal: cups,
          optionsLabel: optionsLabelFromJson(line.optionsJson),
          note: line.note,
        ),
      );
    }
  }
  return labels;
}

List<DrinkLabel> drinkLabelsFromCart(
  Cart cart, {
  required Set<String> labelProductIds,
  String? tableLabel,
}) {
  final labels = <DrinkLabel>[];
  final ref = orderRefShort(newUuid());
  final placedAt = DateTime.now();
  for (final line in cart.lines) {
    if (!labelProductIds.contains(line.product.id)) continue;
    final cups = max(1, line.qty.round());
    for (var i = 1; i <= cups; i++) {
      labels.add(
        DrinkLabel(
          productName: line.product.name,
          tableLabel: tableLabel ?? '現場',
          orderRef: ref,
          placedAt: placedAt,
          cupIndex: i,
          cupTotal: cups,
          optionsLabel: line.selectedOptions.displayLabel,
          note: line.note,
        ),
      );
    }
  }
  return labels;
}

Future<Set<String>> labelProductIdsFromDb(AppDatabase db) async {
  final rows = await (db.select(db.products)
        ..where((t) => t.printLabel.equals(true))
        ..where((t) => t.deletedAt.isNull()))
      .get();
  return rows.map((r) => r.id).toSet();
}
