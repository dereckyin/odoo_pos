import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../../data/printer/printer_providers.dart';
import '../providers/cart_controller.dart';
import '../providers/checkout_controller.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  PaymentMethod _method = PaymentMethod.cash;
  final NumPadBuffer _tenderedBuffer = NumPadBuffer(maxLength: 8);
  bool _busy = false;
  InvoiceCarrierType _carrierType = InvoiceCarrierType.none;
  final _carrierCtl = TextEditingController();
  final _taxIdCtl = TextEditingController();

  @override
  void dispose() {
    _carrierCtl.dispose();
    _taxIdCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartControllerProvider);
    final theme = Theme.of(context);
    final tendered = Money.fromMajor(_tenderedBuffer.asNum);
    final change = (tendered - cart.total);
    final canPay = _method != PaymentMethod.cash || tendered >= cart.total;

    return LoadingOverlay(
      busy: _busy,
      message: '處理結帳中…',
      child: Scaffold(
        appBar: AppBar(title: const Text('結帳')),
        body: Row(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(title: '應付金額', actions: [
                      MoneyText(cart.total,
                          style: theme.textTheme.displayLarge?.copyWith(color: theme.colorScheme.primary)),
                    ]),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: PaymentMethod.values
                          .where((m) => m != PaymentMethod.points && m != PaymentMethod.voucher && m != PaymentMethod.other)
                          .map((m) {
                        final selected = _method == m;
                        return ChoiceChip(
                          label: Text(m.label),
                          selected: selected,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          onSelected: (_) => setState(() => _method = m),
                        );
                      }).toList(),
                    ),
                    const Divider(height: 32),
                    if (_method == PaymentMethod.cash) ..._buildCash(cart, tendered, change),
                    if (_method == PaymentMethod.creditCard) _buildCreditNotice(),
                    if (_method == PaymentMethod.linePay) _buildLinePayNotice(),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('返回'),
                            onPressed: _busy ? null : () => context.pop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: BigButton(
                            icon: Icons.check_circle_outline,
                            label: '確認結帳 ${cart.total.format()}',
                            onPressed: !canPay || _busy ? null : () => _doCheckout(cart, tendered, change),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            VerticalDivider(width: 1, color: theme.dividerColor),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(title: '電子發票'),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final t in InvoiceCarrierType.values)
                          ChoiceChip(
                            label: Text(_carrierLabel(t)),
                            selected: _carrierType == t,
                            onSelected: (_) => setState(() => _carrierType = t),
                          ),
                      ],
                    ),
                    if (_carrierType == InvoiceCarrierType.mobile ||
                        _carrierType == InvoiceCarrierType.citizenDigital ||
                        _carrierType == InvoiceCarrierType.member) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _carrierCtl,
                        decoration: InputDecoration(
                          labelText: _carrierType == InvoiceCarrierType.mobile
                              ? '手機條碼 (e.g. /ABC1234)'
                              : '載具碼',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _taxIdCtl,
                      decoration: const InputDecoration(labelText: '統一編號 (B2B 三聯式)'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCash(Cart cart, Money tendered, Money change) {
    final pre = [
      ('100', () => _setTendered(100)),
      ('500', () => _setTendered(500)),
      ('1000', () => _setTendered(1000)),
      ('剛好', () => _setTendered(cart.total.major.toDouble())),
    ];
    return [
      Row(
        children: [
          const Text('收款 ', style: TextStyle(fontSize: 18)),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.centerRight,
              child: Text(_tenderedBuffer.value, style: Theme.of(context).textTheme.headlineMedium),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          for (final (label, fn) in pre)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OutlinedButton(onPressed: fn, child: Text(label)),
            ),
        ],
      ),
      const SizedBox(height: 12),
      NumPad(
        allowDecimal: false,
        onKey: (k) => setState(() => _tenderedBuffer.apply(k)),
        onClear: () => setState(() => _tenderedBuffer.reset()),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(children: [
          const Text('找零', style: TextStyle(fontSize: 18)),
          const Spacer(),
          MoneyText(change.cents > 0 ? change : Money.zero(),
              style: Theme.of(context).textTheme.headlineMedium),
        ]),
      ),
    ];
  }

  void _setTendered(double v) => setState(() => _tenderedBuffer.set(v.toStringAsFixed(0)));

  Widget _buildCreditNotice() => const Card(
        child: ListTile(
          leading: Icon(Icons.credit_card),
          title: Text('刷卡：請於信用卡終端機輸入金額'),
          subtitle: Text('系統會記錄成功授權的卡片末四碼與授權碼'),
        ),
      );

  Widget _buildLinePayNotice() => const Card(
        child: ListTile(
          leading: Icon(Icons.qr_code_2),
          title: Text('LINE Pay：將顯示 QR 給顧客掃描'),
          subtitle: Text('交易結果將透過 webhook 自動回填'),
        ),
      );

  Future<void> _doCheckout(Cart cart, Money tendered, Money change) async {
    setState(() => _busy = true);
    try {
      final payment = Payment(
        id: newUuid(),
        method: _method,
        amount: cart.total,
        status: PaymentStatus.captured,
        tendered: _method == PaymentMethod.cash ? tendered : null,
        changeDue: _method == PaymentMethod.cash && change.isPositive ? change : null,
        createdAt: DateTime.now(),
      );

      final carrier = _carrierType == InvoiceCarrierType.none
          ? null
          : InvoiceCarrier(
              type: _carrierType,
              code: _carrierCtl.text.trim().isEmpty ? null : _carrierCtl.text.trim(),
            );

      final result = await ref.read(checkoutControllerProvider).finalize(
        payments: [payment],
        carrier: carrier,
        taxId: _taxIdCtl.text.trim().isEmpty ? null : _taxIdCtl.text.trim(),
        invoiceGateway: 'ezpay',
      );

      try {
        await ref.read(printerServiceProvider).printReceipt(result.order);
      } catch (_) {/* non-fatal */}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('結帳完成 ${payment.amount.format()}')),
      );
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('結帳失敗: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _carrierLabel(InvoiceCarrierType t) => switch (t) {
        InvoiceCarrierType.none => '雲端發票',
        InvoiceCarrierType.mobile => '手機條碼',
        InvoiceCarrierType.citizenDigital => '自然人憑證',
        InvoiceCarrierType.member => '會員載具',
      };
}
