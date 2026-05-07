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
  /// **'企業 POS'**
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
  /// **'購物車'**
  String get cart;

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
