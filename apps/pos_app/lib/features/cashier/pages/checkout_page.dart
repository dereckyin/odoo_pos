import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../../core/providers.dart';
import '../../../data/printer/print_orchestrator.dart';
import '../../../data/api/dto.dart';
import '../../products/providers/product_providers.dart';
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
  final NumPadBuffer _pointsBuffer = NumPadBuffer(maxLength: 6);
  final _couponCtl = TextEditingController();
  bool _busy = false;
  InvoiceCarrierType _carrierType = InvoiceCarrierType.none;
  final _carrierCtl = TextEditingController();
  final _taxIdCtl = TextEditingController();

  int _pointValue = 1;
  int _couponDiscountCents = 0;
  String? _couponMsg;

  int get _pointsToRedeem => _pointsBuffer.asNum.toInt();
  int get _pointsDiscountCents => _pointsToRedeem * _pointValue;

  Money _payable(Cart cart) =>
      cart.total - Money(_pointsDiscountCents) - Money(_couponDiscountCents);

  @override
  void dispose() {
    _carrierCtl.dispose();
    _taxIdCtl.dispose();
    _couponCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartControllerProvider);
    final theme = Theme.of(context);
    final settings = ref.watch(loyaltySettingsProvider).valueOrNull;
    final categoryTree = ref.watch(categoryTreeProvider);
    _pointValue = math.max(1, settings?.pointValueCents ?? 1);
    final redeemEnabled = settings?.redeemEnabled ?? true;
    final maxRedeemPct = settings?.maxRedeemPct ?? 50;

    // Points may only offset the redeem-eligible portion of the cart.
    var redeemableCents = 0;
    for (final line in cart.lines) {
      if (PromotionEngine.pointsRedeemEligibleFor(line.product, categoryTree)) {
        redeemableCents += line.net.cents;
      }
    }
    final maxByPct = (redeemableCents * maxRedeemPct ~/ 100) ~/ _pointValue;
    final maxPoints = redeemEnabled
        ? math.min(cart.member?.points ?? 0, math.max(0, maxByPct))
        : 0;
    if (_pointsToRedeem > maxPoints) {
      _pointsBuffer.set(maxPoints.toString());
    }

    final payable = _payable(cart);
    final tendered = Money.fromMajor(_tenderedBuffer.asNum);
    final change = (tendered - payable);
    final canPay = _method != PaymentMethod.cash || tendered >= payable;

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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionHeader(title: '應付金額', actions: [
                        MoneyText(payable,
                            style: theme.textTheme.displayLarge?.copyWith(color: theme.colorScheme.primary)),
                      ]),
                      if (ref.watch(importedGuestOrderProvider)?.isMarketplace == true) ...[
                        const SizedBox(height: 12),
                        _MarketplaceCustomerCard(
                          order: ref.watch(importedGuestOrderProvider)!,
                        ),
                      ],
                      if (cart.member != null) ...[
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('會員 ${cart.member!.name}（${cart.member!.points} 點）'),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _couponCtl,
                                        decoration: const InputDecoration(
                                          labelText: '優惠券代碼',
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: () => _applyCoupon(cart),
                                      child: const Text('套用'),
                                    ),
                                  ],
                                ),
                                if (_couponMsg != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      _couponMsg!,
                                      style: TextStyle(
                                        color: _couponDiscountCents > 0
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.error,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text('兌換點數'),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _pointsBuffer.value.isEmpty ? '0' : _pointsBuffer.value,
                                        textAlign: TextAlign.right,
                                        style: theme.textTheme.titleLarge,
                                      ),
                                    ),
                                  ],
                                ),
                                NumPad(
                                  allowDecimal: false,
                                  onKey: (k) => setState(() {
                                    _pointsBuffer.apply(k);
                                    if (_pointsToRedeem > maxPoints) {
                                      _pointsBuffer.set(maxPoints.toString());
                                    }
                                  }),
                                  onClear: () => setState(() => _pointsBuffer.reset()),
                                ),
                                if (_pointsDiscountCents > 0)
                                  Text('點數折抵 ${Money(_pointsDiscountCents).format()}',
                                      style: TextStyle(color: theme.colorScheme.primary)),
                              ],
                            ),
                          ),
                        ),
                      ],
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
                      if (_method == PaymentMethod.cash) ..._buildCash(cart, payable, tendered, change),
                      if (_method == PaymentMethod.creditCard) _buildCreditNotice(),
                      if (_method == PaymentMethod.linePay) _buildLinePayNotice(),
                      const SizedBox(height: 16),
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
                              label: '確認結帳 ${payable.format()}',
                              onPressed: !canPay || _busy ? null : () => _doCheckout(cart, payable, tendered, change),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            VerticalDivider(width: 1, color: theme.dividerColor),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
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
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCash(Cart cart, Money payable, Money tendered, Money change) {
    final pre = [
      ('100', () => _setTendered(100)),
      ('500', () => _setTendered(500)),
      ('1000', () => _setTendered(1000)),
      ('剛好', () => _setTendered(payable.major.toDouble())),
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

  Future<void> _applyCoupon(Cart cart) async {
    final code = _couponCtl.text.trim();
    if (code.isEmpty) {
      setState(() {
        _couponDiscountCents = 0;
        _couponMsg = null;
      });
      return;
    }
    try {
      final preview = await ref.read(posApiProvider).previewCoupon(
            code: code,
            orderTotalCents: cart.total.cents,
            memberId: cart.member?.id,
          );
      if (!mounted) return;
      setState(() {
        _couponDiscountCents = preview.discountCents;
        _couponMsg = preview.discountCents > 0
            ? '優惠券折抵 ${Money(preview.discountCents).format()}'
            : '優惠券已套用（無折抵金額）';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _couponDiscountCents = 0;
        _couponMsg = '優惠券無效或不適用';
      });
    }
  }

  Future<void> _doCheckout(Cart cart, Money payable, Money tendered, Money change) async {
    setState(() => _busy = true);
    try {
      final payment = Payment(
        id: newUuid(),
        method: _method,
        amount: payable,
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

      final guestOrder = ref.read(importedGuestOrderProvider);
      final tableLabel = guestOrder?.displayTitle;

      final result = await ref.read(checkoutControllerProvider).finalize(
        payments: [payment],
        carrier: carrier,
        taxId: _taxIdCtl.text.trim().isEmpty ? null : _taxIdCtl.text.trim(),
        invoiceGateway: 'ezpay',
        pointsRedeemed: _pointsToRedeem,
        pointsDiscountCents: _pointsDiscountCents,
        couponDiscountCents: _couponDiscountCents,
        couponCode: _couponCtl.text.trim().isEmpty ? null : _couponCtl.text.trim(),
        note: cart.note,
      );

      try {
        await ref.read(printOrchestratorProvider).onCheckout(
              order: result.order,
              cart: cart,
              invoiceJson: result.invoiceJson,
              tableLabel: tableLabel,
              carrier: carrier,
              donationCode: null,
            );
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

class _MarketplaceCustomerCard extends StatelessWidget {
  const _MarketplaceCustomerCard({required this.order});
  final GuestOrderDto order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('市集訂單', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if ((order.customerName ?? '').isNotEmpty)
              Text('姓名：${order.customerName}'),
            if ((order.customerPhone ?? '').isNotEmpty)
              Text('電話：${order.customerPhone}'),
            Text('取餐：${order.fulfillmentLabel}'),
            if (order.paymentLabel.isNotEmpty) Text('付款：${order.paymentLabel}'),
            if (order.isDelivery && (order.deliveryAddress ?? '').isNotEmpty)
              Text('地址：${order.deliveryAddress}'),
            if (order.isDelivery && (order.deliveryNote ?? '').isNotEmpty)
              Text('外送備註：${order.deliveryNote}'),
          ],
        ),
      ),
    );
  }
}
