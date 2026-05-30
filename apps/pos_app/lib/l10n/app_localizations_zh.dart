// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '點餐趣';

  @override
  String get cashier => '收銀';

  @override
  String get checkout => '結帳';

  @override
  String get products => '商品';

  @override
  String get members => '會員';

  @override
  String get inventory => '庫存';

  @override
  String get promotions => '行銷';

  @override
  String get history => '訂單記錄';

  @override
  String get settings => '設定';

  @override
  String get login => '登入';

  @override
  String get logout => '登出';

  @override
  String get username => '帳號';

  @override
  String get password => '密碼';

  @override
  String get terminal => '終端機代號';

  @override
  String get cart => '點單明細';

  @override
  String get cartEmptyTitle => '尚無點單品項';

  @override
  String get cartEmptySubtitle => '點選左側商品加入點單';

  @override
  String get addToOrder => '加入點單';

  @override
  String get orderDetailHasItems => '點單明細內尚有品項';

  @override
  String get importGuestOrderReplaceMessage => '匯入桌邊訂單將取代目前點單明細，是否繼續？';

  @override
  String get parkAndImport => '掛單保留並匯入';

  @override
  String get replaceAndImport => '覆蓋並匯入';

  @override
  String get parkOrder => '掛單';

  @override
  String get recallHeldOrders => '取單';

  @override
  String get heldOrdersTitle => '掛單列表';

  @override
  String get heldOrdersEmpty => '目前沒有掛單';

  @override
  String get restoreHeld => '還原';

  @override
  String get deleteHeld => '刪除';

  @override
  String importedToOrderDetail(String table) {
    return '已帶入桌 $table 點單明細，請確認後結帳';
  }

  @override
  String get reprintKitchenTicket => '補印廚房單';

  @override
  String guestOrderSource(String table) {
    return '桌邊訂單 · 桌 $table';
  }

  @override
  String get fulfillAndImport => '接單出餐並帶入';

  @override
  String get importToOrderDetail => '帶入點單明細';

  @override
  String get importOrderDetailFailed => '帶入點單明細失敗';

  @override
  String get fulfillFailed => '接單出餐失敗';

  @override
  String get parkSuccess => '已掛單保留';

  @override
  String get subtotal => '小計';

  @override
  String get tax => '稅';

  @override
  String get total => '合計';

  @override
  String get amountDue => '應付';

  @override
  String get tendered => '收款';

  @override
  String get change => '找零';

  @override
  String get cash => '現金';

  @override
  String get creditCard => '信用卡';

  @override
  String get linePay => 'LINE Pay';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => '點餐趣';

  @override
  String get cashier => '收銀';

  @override
  String get checkout => '結帳';

  @override
  String get products => '商品';

  @override
  String get members => '會員';

  @override
  String get inventory => '庫存';

  @override
  String get promotions => '行銷';

  @override
  String get history => '訂單記錄';

  @override
  String get settings => '設定';

  @override
  String get login => '登入';

  @override
  String get logout => '登出';

  @override
  String get username => '帳號';

  @override
  String get password => '密碼';

  @override
  String get terminal => '終端機代號';

  @override
  String get cart => '點單明細';

  @override
  String get cartEmptyTitle => '尚無點單品項';

  @override
  String get cartEmptySubtitle => '點選左側商品加入點單';

  @override
  String get addToOrder => '加入點單';

  @override
  String get orderDetailHasItems => '點單明細內尚有品項';

  @override
  String get importGuestOrderReplaceMessage => '匯入桌邊訂單將取代目前點單明細，是否繼續？';

  @override
  String get parkAndImport => '掛單保留並匯入';

  @override
  String get replaceAndImport => '覆蓋並匯入';

  @override
  String get parkOrder => '掛單';

  @override
  String get recallHeldOrders => '取單';

  @override
  String get heldOrdersTitle => '掛單列表';

  @override
  String get heldOrdersEmpty => '目前沒有掛單';

  @override
  String get restoreHeld => '還原';

  @override
  String get deleteHeld => '刪除';

  @override
  String importedToOrderDetail(String table) {
    return '已帶入桌 $table 點單明細，請確認後結帳';
  }

  @override
  String get reprintKitchenTicket => '補印廚房單';

  @override
  String guestOrderSource(String table) {
    return '桌邊訂單 · 桌 $table';
  }

  @override
  String get fulfillAndImport => '接單出餐並帶入';

  @override
  String get importToOrderDetail => '帶入點單明細';

  @override
  String get importOrderDetailFailed => '帶入點單明細失敗';

  @override
  String get fulfillFailed => '接單出餐失敗';

  @override
  String get parkSuccess => '已掛單保留';

  @override
  String get subtotal => '小計';

  @override
  String get tax => '稅';

  @override
  String get total => '合計';

  @override
  String get amountDue => '應付';

  @override
  String get tendered => '收款';

  @override
  String get change => '找零';

  @override
  String get cash => '現金';

  @override
  String get creditCard => '信用卡';

  @override
  String get linePay => 'LINE Pay';
}
