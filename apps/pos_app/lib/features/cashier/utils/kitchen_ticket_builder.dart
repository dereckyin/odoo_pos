import '../../../data/api/dto.dart';
import '../../../data/printer/escpos_service.dart';

KitchenTicket kitchenTicketFromGuestOrder(GuestOrderDto order) => KitchenTicket(
      guestOrderId: order.id,
      tableLabel: order.tableLabel ?? '?',
      placedAt: order.createdAt,
      partySize: order.partySize,
      note: order.customerNote,
      lines: order.lines
          .map(
            (l) => KitchenTicketLine(
              name: l.productName,
              qty: l.qty,
              note: l.note,
            ),
          )
          .toList(),
    );
