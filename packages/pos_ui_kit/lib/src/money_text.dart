import 'package:flutter/material.dart';
import 'package:pos_core/pos_core.dart';

class MoneyText extends StatelessWidget {
  const MoneyText(this.amount, {super.key, this.style, this.withSymbol = true, this.locale = 'zh_TW'});
  final Money amount;
  final TextStyle? style;
  final bool withSymbol;
  final String locale;

  @override
  Widget build(BuildContext context) =>
      Text(amount.format(locale: locale, withSymbol: withSymbol), style: style);
}
