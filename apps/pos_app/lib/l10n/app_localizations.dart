import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'點餐趣'**
  String get appTitle;

  /// No description provided for @cashier.
  ///
  /// In zh_TW, this message translates to:
  /// **'收銀'**
  String get cashier;

  /// No description provided for @checkout.
  ///
  /// In zh_TW, this message translates to:
  /// **'結帳'**
  String get checkout;

  /// No description provided for @products.
  ///
  /// In zh_TW, this message translates to:
  /// **'商品'**
  String get products;

  /// No description provided for @members.
  ///
  /// In zh_TW, this message translates to:
  /// **'會員'**
  String get members;

  /// No description provided for @inventory.
  ///
  /// In zh_TW, this message translates to:
  /// **'庫存'**
  String get inventory;

  /// No description provided for @promotions.
  ///
  /// In zh_TW, this message translates to:
  /// **'行銷'**
  String get promotions;

  /// No description provided for @history.
  ///
  /// In zh_TW, this message translates to:
  /// **'訂單記錄'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In zh_TW, this message translates to:
  /// **'設定'**
  String get settings;

  /// No description provided for @login.
  ///
  /// In zh_TW, this message translates to:
  /// **'登入'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In zh_TW, this message translates to:
  /// **'登出'**
  String get logout;

  /// No description provided for @username.
  ///
  /// In zh_TW, this message translates to:
  /// **'帳號'**
  String get username;

  /// No description provided for @password.
  ///
  /// In zh_TW, this message translates to:
  /// **'密碼'**
  String get password;

  /// No description provided for @terminal.
  ///
  /// In zh_TW, this message translates to:
  /// **'終端機代號'**
  String get terminal;

  /// No description provided for @cart.
  ///
  /// In zh_TW, this message translates to:
  /// **'點單明細'**
  String get cart;

  /// No description provided for @cartEmptyTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚無點單品項'**
  String get cartEmptyTitle;

  /// No description provided for @cartEmptySubtitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'點選左側商品加入點單'**
  String get cartEmptySubtitle;

  /// No description provided for @addToOrder.
  ///
  /// In zh_TW, this message translates to:
  /// **'加入點單'**
  String get addToOrder;

  /// No description provided for @orderDetailHasItems.
  ///
  /// In zh_TW, this message translates to:
  /// **'點單明細內尚有品項'**
  String get orderDetailHasItems;

  /// No description provided for @importGuestOrderReplaceMessage.
  ///
  /// In zh_TW, this message translates to:
  /// **'匯入桌邊訂單將取代目前點單明細，是否繼續？'**
  String get importGuestOrderReplaceMessage;

  /// No description provided for @parkAndImport.
  ///
  /// In zh_TW, this message translates to:
  /// **'掛單保留並匯入'**
  String get parkAndImport;

  /// No description provided for @replaceAndImport.
  ///
  /// In zh_TW, this message translates to:
  /// **'覆蓋並匯入'**
  String get replaceAndImport;

  /// No description provided for @parkOrder.
  ///
  /// In zh_TW, this message translates to:
  /// **'掛單'**
  String get parkOrder;

  /// No description provided for @recallHeldOrders.
  ///
  /// In zh_TW, this message translates to:
  /// **'取單'**
  String get recallHeldOrders;

  /// No description provided for @heldOrdersTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'掛單列表'**
  String get heldOrdersTitle;

  /// No description provided for @heldOrdersEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'目前沒有掛單'**
  String get heldOrdersEmpty;

  /// No description provided for @restoreHeld.
  ///
  /// In zh_TW, this message translates to:
  /// **'還原'**
  String get restoreHeld;

  /// No description provided for @deleteHeld.
  ///
  /// In zh_TW, this message translates to:
  /// **'刪除'**
  String get deleteHeld;

  /// No description provided for @importedToOrderDetail.
  ///
  /// In zh_TW, this message translates to:
  /// **'已帶入桌 {table} 點單明細，請確認後結帳'**
  String importedToOrderDetail(String table);

  /// No description provided for @reprintKitchenTicket.
  ///
  /// In zh_TW, this message translates to:
  /// **'補印廚房單'**
  String get reprintKitchenTicket;

  /// No description provided for @guestOrderSource.
  ///
  /// In zh_TW, this message translates to:
  /// **'桌邊訂單 · 桌 {table}'**
  String guestOrderSource(String table);

  /// No description provided for @fulfillAndImport.
  ///
  /// In zh_TW, this message translates to:
  /// **'接單出餐並帶入'**
  String get fulfillAndImport;

  /// No description provided for @importToOrderDetail.
  ///
  /// In zh_TW, this message translates to:
  /// **'帶入點單明細'**
  String get importToOrderDetail;

  /// No description provided for @importOrderDetailFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'帶入點單明細失敗'**
  String get importOrderDetailFailed;

  /// No description provided for @fulfillFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'接單出餐失敗'**
  String get fulfillFailed;

  /// No description provided for @parkSuccess.
  ///
  /// In zh_TW, this message translates to:
  /// **'已掛單保留'**
  String get parkSuccess;

  /// No description provided for @subtotal.
  ///
  /// In zh_TW, this message translates to:
  /// **'小計'**
  String get subtotal;

  /// No description provided for @tax.
  ///
  /// In zh_TW, this message translates to:
  /// **'稅'**
  String get tax;

  /// No description provided for @total.
  ///
  /// In zh_TW, this message translates to:
  /// **'合計'**
  String get total;

  /// No description provided for @amountDue.
  ///
  /// In zh_TW, this message translates to:
  /// **'應付'**
  String get amountDue;

  /// No description provided for @tendered.
  ///
  /// In zh_TW, this message translates to:
  /// **'收款'**
  String get tendered;

  /// No description provided for @change.
  ///
  /// In zh_TW, this message translates to:
  /// **'找零'**
  String get change;

  /// No description provided for @cash.
  ///
  /// In zh_TW, this message translates to:
  /// **'現金'**
  String get cash;

  /// No description provided for @creditCard.
  ///
  /// In zh_TW, this message translates to:
  /// **'信用卡'**
  String get creditCard;

  /// No description provided for @linePay.
  ///
  /// In zh_TW, this message translates to:
  /// **'LINE Pay'**
  String get linePay;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
