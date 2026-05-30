// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => '點餐趣';

  @override
  String get cashier => 'Cashier';

  @override
  String get checkout => 'Checkout';

  @override
  String get products => 'Products';

  @override
  String get members => 'Members';

  @override
  String get inventory => 'Inventory';

  @override
  String get promotions => 'Promotions';

  @override
  String get history => 'Orders';

  @override
  String get settings => 'Settings';

  @override
  String get login => 'Sign in';

  @override
  String get logout => 'Sign out';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get terminal => 'Terminal';

  @override
  String get cart => 'Order';

  @override
  String get cartEmptyTitle => 'No items yet';

  @override
  String get cartEmptySubtitle => 'Tap products on the left to add';

  @override
  String get addToOrder => 'Add to order';

  @override
  String get orderDetailHasItems => 'Order has items';

  @override
  String get importGuestOrderReplaceMessage =>
      'Importing a table order will replace the current order. Continue?';

  @override
  String get parkAndImport => 'Park & import';

  @override
  String get replaceAndImport => 'Replace & import';

  @override
  String get parkOrder => 'Park';

  @override
  String get recallHeldOrders => 'Recall';

  @override
  String get heldOrdersTitle => 'Parked orders';

  @override
  String get heldOrdersEmpty => 'No parked orders';

  @override
  String get restoreHeld => 'Restore';

  @override
  String get deleteHeld => 'Delete';

  @override
  String importedToOrderDetail(String table) {
    return 'Table $table imported — review before checkout';
  }

  @override
  String get reprintKitchenTicket => 'Reprint kitchen ticket';

  @override
  String guestOrderSource(String table) {
    return 'Table order · $table';
  }

  @override
  String get fulfillAndImport => 'Accept & import';

  @override
  String get importToOrderDetail => 'Import to order';

  @override
  String get importOrderDetailFailed => 'Import failed';

  @override
  String get fulfillFailed => 'Accept failed';

  @override
  String get parkSuccess => 'Order parked';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get tax => 'Tax';

  @override
  String get total => 'Total';

  @override
  String get amountDue => 'Due';

  @override
  String get tendered => 'Tendered';

  @override
  String get change => 'Change';

  @override
  String get cash => 'Cash';

  @override
  String get creditCard => 'Credit';

  @override
  String get linePay => 'LINE Pay';
}
