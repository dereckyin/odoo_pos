import 'package:drift/drift.dart';

@DataClassName('StoreRow')
class Stores extends Table {
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get taxId => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get phone => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TerminalRow')
class Terminals extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text().references(Stores, #id)();
  TextColumn get code => text()();
  DateTimeColumn get lastSeenAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get parentId => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  BoolColumn get hideFromPublicOrdering =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get hideFromPosBrowse => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProductRow')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get sku => text()();
  TextColumn get name => text()();
  IntColumn get priceCents => integer().withDefault(const Constant(0))();
  IntColumn get costCents => integer().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  RealColumn get taxRate => real().withDefault(const Constant(0.05))();
  BoolColumn get isWeighted => boolean().withDefault(const Constant(false))();
  TextColumn get unit => text().withDefault(const Constant('個'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get description => text().nullable()();
  BoolColumn get hideFromPublicOrdering =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get hideFromPosBrowse => boolean().withDefault(const Constant(false))();
  BoolColumn get trackInventory => boolean().withDefault(const Constant(true))();
  TextColumn get productKind => text().withDefault(const Constant('regular'))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BookDetailRow')
class BookDetails extends Table {
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get barcode => text()();
  TextColumn get author => text().nullable()();
  TextColumn get publisher => text().nullable()();
  TextColumn get isbn => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {productId};
}

@DataClassName('ProductBarcodeRow')
class ProductBarcodes extends Table {
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get barcode => text()();

  @override
  Set<Column> get primaryKey => {barcode};
}

@DataClassName('MemberLevelRow')
class MemberLevels extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get discountRate => real().withDefault(const Constant(1.0))();
  IntColumn get minSpend => integer().withDefault(const Constant(0))();
  IntColumn get minPoints => integer().withDefault(const Constant(0))();
  TextColumn get color => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MemberRow')
class Members extends Table {
  TextColumn get id => text()();
  TextColumn get phone => text()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  DateTimeColumn get birthday => dateTime().nullable()();
  IntColumn get points => integer().withDefault(const Constant(0))();
  IntColumn get totalSpentCents => integer().withDefault(const Constant(0))();
  TextColumn get levelId => text().nullable()();
  TextColumn get qrCode => text().nullable()();
  DateTimeColumn get joinedAt => dateTime()();
  DateTimeColumn get lastVisitAt => dateTime().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CouponRow')
class Coupons extends Table {
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get type => text()();
  RealColumn get value => real()();
  TextColumn get memberId => text().nullable()();
  IntColumn get minSpendCents => integer().withDefault(const Constant(0))();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  DateTimeColumn get usedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PointTransactionRow')
class PointTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get memberId => text()();
  IntColumn get delta => integer()();
  TextColumn get reason => text()();
  TextColumn get orderId => text().nullable()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OrderRow')
class Orders extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text()();
  TextColumn get terminalId => text()();
  TextColumn get cashierId => text()();
  TextColumn get memberId => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('paid'))();
  IntColumn get subtotalCents => integer().withDefault(const Constant(0))();
  IntColumn get discountCents => integer().withDefault(const Constant(0))();
  IntColumn get taxCents => integer().withDefault(const Constant(0))();
  IntColumn get totalCents => integer().withDefault(const Constant(0))();
  IntColumn get refundedCents => integer().withDefault(const Constant(0))();
  TextColumn get invoiceNumber => text().nullable()();
  TextColumn get invoiceCarrier => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get orderNo => text().nullable()();
  TextColumn get tableLabel => text().nullable()();
  TextColumn get primaryPaymentMethod => text().nullable()();
  TextColumn get sourceGuestOrderId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OrderLineRow')
class OrderLines extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text()();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  TextColumn get sku => text()();
  RealColumn get qty => real()();
  IntColumn get unitPriceCents => integer()();
  IntColumn get lineDiscountCents => integer().withDefault(const Constant(0))();
  IntColumn get lineTotalCents => integer()();
  RealColumn get taxRate => real().withDefault(const Constant(0.05))();
  TextColumn get note => text().nullable()();
  TextColumn get optionsJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OptionGroupRow')
class OptionGroups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get selectionType => text().withDefault(const Constant('single'))();
  BoolColumn get isRequired => boolean().withDefault(const Constant(true))();
  IntColumn get minSelections => integer().withDefault(const Constant(0))();
  IntColumn get maxSelections => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OptionChoiceRow')
class OptionChoices extends Table {
  TextColumn get id => text()();
  TextColumn get optionGroupId => text().references(OptionGroups, #id)();
  TextColumn get name => text()();
  IntColumn get priceDeltaCents => integer().withDefault(const Constant(0))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProductOptionGroupRow')
class ProductOptionGroups extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get optionGroupId => text().references(OptionGroups, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isRequired => boolean().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProductOptionChoiceOverrideRow')
class ProductOptionChoiceOverrides extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get optionChoiceId => text().references(OptionChoices, #id)();
  IntColumn get priceDeltaCents => integer().nullable()();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PaymentRow')
class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text()();
  TextColumn get method => text()();
  IntColumn get amountCents => integer()();
  TextColumn get status => text().withDefault(const Constant('captured'))();
  TextColumn get gatewayRef => text().nullable()();
  TextColumn get gatewayResponseJson => text().nullable()();
  IntColumn get tenderedCents => integer().nullable()();
  IntColumn get changeDueCents => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RefundRow')
class Refunds extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text()();
  TextColumn get userId => text()();
  TextColumn get method => text()();
  IntColumn get totalAmountCents => integer()();
  TextColumn get reason => text().nullable()();
  TextColumn get gatewayRef => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RefundLineRow')
class RefundLines extends Table {
  TextColumn get id => text()();
  TextColumn get refundId => text()();
  TextColumn get orderLineId => text()();
  RealColumn get qty => real()();
  IntColumn get amountCents => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('InventoryLevelRow')
class InventoryLevels extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text()();
  TextColumn get productId => text()();
  RealColumn get onHand => real().withDefault(const Constant(0))();
  RealColumn get safetyStock => real().withDefault(const Constant(0))();
  RealColumn get reserved => real().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('InventoryMovementRow')
class InventoryMovements extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text()();
  TextColumn get productId => text()();
  RealColumn get qtyDelta => real()();
  TextColumn get reason => text()();
  TextColumn get refType => text().nullable()();
  TextColumn get refId => text().nullable()();
  TextColumn get terminalId => text().nullable()();
  TextColumn get userId => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransferOrderRow')
class TransferOrders extends Table {
  TextColumn get id => text()();
  TextColumn get fromStoreId => text()();
  TextColumn get toStoreId => text()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  DateTimeColumn get dispatchedAt => dateTime().nullable()();
  DateTimeColumn get receivedAt => dateTime().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransferLineRow')
class TransferLines extends Table {
  TextColumn get id => text()();
  TextColumn get transferId => text()();
  TextColumn get productId => text()();
  RealColumn get qty => real()();
  RealColumn get receivedQty => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('StocktakeRow')
class Stocktakes extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('StocktakeLineRow')
class StocktakeLines extends Table {
  TextColumn get id => text()();
  TextColumn get stocktakeId => text()();
  TextColumn get productId => text()();
  RealColumn get expectedQty => real()();
  RealColumn get actualQty => real()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PromotionRow')
class Promotions extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get strategy => text()();
  TextColumn get configJson => text()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  DateTimeColumn get startsAt => dateTime().nullable()();
  DateTimeColumn get endsAt => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get stackable => boolean().withDefault(const Constant(false))();
  TextColumn get applicableProductIdsJson => text().withDefault(const Constant('[]'))();
  TextColumn get applicableCategoryIdsJson => text().withDefault(const Constant('[]'))();
  TextColumn get memberLevelIdsJson => text().withDefault(const Constant('[]'))();
  TextColumn get description => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('InvoiceRow')
class Invoices extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get invoiceNumber => text().nullable()();
  DateTimeColumn get invoiceDate => dateTime().nullable()();
  IntColumn get totalCents => integer()();
  IntColumn get taxCents => integer()();
  IntColumn get taxType => integer().withDefault(const Constant(1))();
  TextColumn get carrierType => text().nullable()();
  TextColumn get carrierCode => text().nullable()();
  TextColumn get taxId => text().nullable()();
  TextColumn get companyName => text().nullable()();
  TextColumn get donationCode => text().nullable()();
  TextColumn get gateway => text().nullable()();
  TextColumn get gatewayRef => text().nullable()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SyncQueueRow')
class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get op => text()();
  TextColumn get payloadJson => text()();
  IntColumn get retries => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cashier-parked order (掛單) — survives app restarts; not synced to server.
@DataClassName('HeldCartRow')
class HeldCarts extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  TextColumn get payload => text()();
  TextColumn get pendingGuestOrderId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('KvMetaRow')
class KvMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}
