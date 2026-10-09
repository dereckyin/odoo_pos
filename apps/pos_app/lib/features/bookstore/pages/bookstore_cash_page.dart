import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/user_facing_error.dart';
import '../../../data/scanner/barcode_listener.dart';

/// Floor cashier: scan App cash QR / 6-digit code and confirm payment.
/// Cash confirm also releases the books — no separate exit scan.
class BookstoreCashPage extends ConsumerStatefulWidget {
  const BookstoreCashPage({super.key});

  @override
  ConsumerState<BookstoreCashPage> createState() => _BookstoreCashPageState();
}

class _BookstoreCashPageState extends ConsumerState<BookstoreCashPage> {
  final _cashCtl = TextEditingController();
  bool _looking = false;
  bool _confirming = false;
  Map<String, dynamic>? _cash;
  String? _hint;

  @override
  void dispose() {
    _cashCtl.dispose();
    super.dispose();
  }

  String? get _storeId => ref.read(authStateProvider).session?.storeId;

  void _onScan(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return;
    _cashCtl.text = v;
    _lookup(v);
  }

  Future<void> _lookup([String? raw]) async {
    final value = (raw ?? _cashCtl.text).trim();
    if (value.isEmpty) return;
    setState(() {
      _looking = true;
      _cash = null;
      _hint = null;
    });
    try {
      final isCode = RegExp(r'^\d{6}$').hasMatch(value);
      final data = await ref.read(posApiProvider).lookupBookstoreCash(
            token: isCode ? null : value,
            code: isCode ? value : null,
            storeId: _storeId,
          );
      if (!mounted) return;
      final result = data['result']?.toString() ?? 'invalid';
      setState(() {
        _cash = data;
        _hint = switch (result) {
          'found' => null,
          'already_paid' => '這筆已經收過款了',
          'closed' => '這筆已取消或退貨，請顧客重新結帳',
          _ => '找不到這筆現金付款，請確認付款碼',
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _hint = formatUserFacingError(e));
    } finally {
      if (mounted) setState(() => _looking = false);
    }
  }

  Future<void> _confirm() async {
    final checkout = _cash?['checkout'];
    if (checkout is! Map) return;
    final id = checkout['id']?.toString();
    final total = (checkout['total_cents'] as num?)?.toInt();
    if (id == null || total == null) return;
    setState(() => _confirming = true);
    try {
      await ref.read(posApiProvider).confirmBookstoreCash(checkoutId: id, expectedTotalCents: total);
      if (!mounted) return;
      setState(() {
        _cash = null;
        _cashCtl.clear();
        _hint = '已收款 NT\$$total，訂單完成，顧客可以帶書離開';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _hint = formatUserFacingError(e));
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Future<void> _openCamera() async {
    final code = await context.push<String>('/barcode-scan');
    if (code != null && mounted) _onScan(code);
  }

  @override
  Widget build(BuildContext context) {
    final checkout = _cash?['checkout'];
    final found = _cash?['result'] == 'found' && checkout is Map;
    return BarcodeKeyboardListener(
      onBarcode: _onScan,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('App 收款'),
          actions: [
            IconButton(
              tooltip: '相機掃碼',
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _openCamera,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('掃描顧客 App 付款 QR，或輸入 6 位數付款碼。確認收款後即可帶書離開。', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _cashCtl,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '付款碼 / QR',
              ),
              inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
              onSubmitted: (_) => _lookup(),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _looking ? null : _lookup,
              child: _looking
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('查詢'),
            ),
            if (_hint != null) ...[
              const SizedBox(height: 16),
              Text(_hint!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
            if (found) ...[
              const SizedBox(height: 16),
              for (final ln in (checkout['lines'] as List? ?? []))
                if (ln is Map) Text('${ln['product_name']} × ${ln['qty']}　NT\$${ln['line_total_cents']}'),
              if ((checkout['discount_cents'] as num? ?? 0) > 0)
                Text('折扣 −NT\$${checkout['discount_cents']}', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 8),
              Text('應收現金 NT\$${checkout['total_cents']}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _confirming ? null : _confirm,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: _confirming
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('確認已收現金 NT\$${checkout['total_cents']}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
