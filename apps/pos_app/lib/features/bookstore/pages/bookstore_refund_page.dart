import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/user_facing_error.dart';

/// Floor staff: list paid App checkouts and refund (restock + MOF cancel queue).
class BookstoreRefundPage extends ConsumerStatefulWidget {
  const BookstoreRefundPage({super.key});

  @override
  ConsumerState<BookstoreRefundPage> createState() => _BookstoreRefundPageState();
}

class _BookstoreRefundPageState extends ConsumerState<BookstoreRefundPage> {
  bool _loading = true;
  bool _refunding = false;
  String? _hint;
  List<Map<String, dynamic>> _rows = const [];

  String? get _storeId => ref.read(authStateProvider).session?.storeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _hint = null;
    });
    try {
      final rows = await ref.read(posApiProvider).listBookstoreCheckouts(
            storeId: _storeId,
            status: 'paid',
            limit: 50,
          );
      if (!mounted) return;
      setState(() => _rows = rows);
    } catch (e) {
      if (!mounted) return;
      setState(() => _hint = formatUserFacingError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refund(Map<String, dynamic> checkout) async {
    final id = checkout['id']?.toString();
    final total = (checkout['total_cents'] as num?)?.toInt() ?? 0;
    final orderNo = checkout['order_no']?.toString() ?? id ?? '';
    if (id == null) return;

    final reasonCtl = TextEditingController(text: '顧客退貨');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('確認退貨'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('訂單 $orderNo'),
            Text('退還現金 NT\$$total', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('會回補庫存，並作廢本站發票（送上傳佇列）。'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtl,
              decoration: const InputDecoration(
                labelText: '退貨原因',
                border: OutlineInputBorder(),
              ),
              maxLength: 500,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (reasonCtl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('確認退貨'),
          ),
        ],
      ),
    );
    final reason = reasonCtl.text.trim();
    reasonCtl.dispose();
    if (ok != true || reason.isEmpty || !mounted) return;

    setState(() {
      _refunding = true;
      _hint = null;
    });
    try {
      final data = await ref.read(posApiProvider).refundBookstoreCheckout(
            checkoutId: id,
            reason: reason,
          );
      if (!mounted) return;
      final message = data['message']?.toString() ?? '已退貨';
      setState(() => _hint = message);
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _hint = formatUserFacingError(e));
    } finally {
      if (mounted) setState(() => _refunding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App 退貨'),
        actions: [
          IconButton(
            tooltip: '重新整理',
            onPressed: _loading || _refunding ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              '選擇已付款的 App 訂單退貨。現金請於櫃檯退還顧客。',
              style: TextStyle(fontSize: 16),
            ),
          ),
          if (_hint != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(_hint!, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _rows.isEmpty
                    ? const Center(child: Text('目前沒有可退貨的已付款訂單'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _rows.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final c = _rows[i];
                          final lines = (c['lines'] as List? ?? [])
                              .whereType<Map>()
                              .map((ln) => '${ln['product_name']} × ${ln['qty']}')
                              .join('、');
                          final total = (c['total_cents'] as num?)?.toInt() ?? 0;
                          final method = c['payment_method']?.toString() == 'cash' ? '現金' : '線上';
                          return ListTile(
                            title: Text(c['order_no']?.toString() ?? c['id']?.toString() ?? ''),
                            subtitle: Text(
                              [
                                if ((c['member_label'] as String?)?.isNotEmpty == true) c['member_label'],
                                if (lines.isNotEmpty) lines,
                                method,
                              ].whereType<String>().join(' · '),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('NT\$$total', style: const TextStyle(fontWeight: FontWeight.bold)),
                                TextButton(
                                  onPressed: _refunding ? null : () => _refund(c),
                                  child: const Text('退貨'),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
