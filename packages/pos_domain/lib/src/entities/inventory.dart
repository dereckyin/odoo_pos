enum MovementReason {
  sale,
  refund,
  receive,
  transferOut,
  transferIn,
  adjustment,
  damage,
  initial,
}

class InventoryLevel {
  const InventoryLevel({
    required this.storeId,
    required this.productId,
    required this.onHand,
    this.safetyStock = 0,
    this.reserved = 0,
    this.updatedAt,
  });

  final String storeId;
  final String productId;
  final num onHand;
  final num safetyStock;
  final num reserved;
  final DateTime? updatedAt;

  num get available => onHand - reserved;
  bool get belowSafety => onHand <= safetyStock;
}

class InventoryMovement {
  const InventoryMovement({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.qtyDelta,
    required this.reason,
    required this.createdAt,
    this.refType,
    this.refId,
    this.terminalId,
    this.userId,
    this.note,
  });

  final String id;
  final String storeId;
  final String productId;
  final num qtyDelta;
  final MovementReason reason;
  final DateTime createdAt;
  final String? refType;
  final String? refId;
  final String? terminalId;
  final String? userId;
  final String? note;
}

enum TransferStatus { draft, dispatched, inTransit, received, cancelled }

class TransferOrder {
  const TransferOrder({
    required this.id,
    required this.fromStoreId,
    required this.toStoreId,
    required this.lines,
    required this.status,
    required this.createdAt,
    this.dispatchedAt,
    this.receivedAt,
    this.note,
  });

  final String id;
  final String fromStoreId;
  final String toStoreId;
  final List<TransferLine> lines;
  final TransferStatus status;
  final DateTime createdAt;
  final DateTime? dispatchedAt;
  final DateTime? receivedAt;
  final String? note;
}

class TransferLine {
  const TransferLine({
    required this.id,
    required this.productId,
    required this.qty,
    this.receivedQty,
  });

  final String id;
  final String productId;
  final num qty;
  final num? receivedQty;
}

class StocktakeOrder {
  const StocktakeOrder({
    required this.id,
    required this.storeId,
    required this.lines,
    required this.createdAt,
    this.completedAt,
    this.note,
  });

  final String id;
  final String storeId;
  final List<StocktakeLine> lines;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? note;
}

class StocktakeLine {
  const StocktakeLine({
    required this.id,
    required this.productId,
    required this.expectedQty,
    required this.actualQty,
  });

  final String id;
  final String productId;
  final num expectedQty;
  final num actualQty;
  num get diff => actualQty - expectedQty;
}
