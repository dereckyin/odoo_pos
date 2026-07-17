import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../data/scanner/barcode_listener.dart';
import '../../../data/api/dto.dart';
import '../../../data/sync/sync_providers.dart';
import '../../books/book_local_store.dart';

class BookReceivePage extends ConsumerStatefulWidget {
  const BookReceivePage({super.key});

  @override
  ConsumerState<BookReceivePage> createState() => _BookReceivePageState();
}

class _BookReceivePageState extends ConsumerState<BookReceivePage> {
  final _barcodeCtl = TextEditingController();
  BookLookupDto? _preview;
  bool _lookingUp = false;
  bool _saving = false;
  double _qty = 1;

  @override
  void dispose() {
    _barcodeCtl.dispose();
    super.dispose();
  }

  Future<void> _applyBarcode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    _barcodeCtl.text = trimmed;
    await _lookup();
  }

  Future<void> _openCameraScan() async {
    final code = await context.push<String>('/barcode-scan');
    if (!mounted || code == null) return;
    await _applyBarcode(code);
  }

  Future<void> _lookup() async {
    final code = _barcodeCtl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _lookingUp = true;
      _preview = null;
    });
    try {
      final api = ref.read(posApiProvider);
      final dto = await api.lookupBook(code);
      if (!mounted) return;
      setState(() => _preview = dto);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('查無書目：$code')),
      );
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  Future<void> _submit() async {
    if (_preview == null) return;
    setState(() => _saving = true);
    try {
      final api = ref.read(posApiProvider);
      final store = BookLocalStore(ref.read(databaseProvider));
      final dto = await api.receiveBook(barcode: _preview!.barcode, qty: _qty);
      await store.upsertFromDto(dto);
      await ref.read(deltaPullerProvider).pullAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('入庫成功：${dto.name}（庫存 ${dto.onHand ?? _qty}）')),
      );
      _barcodeCtl.clear();
      setState(() {
        _preview = null;
        _qty = 1;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('入庫失敗：$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _money(int? cents) {
    if (cents == null) return '—';
    return cents.toString();
  }

  @override
  Widget build(BuildContext context) {
    return BarcodeKeyboardListener(
      onBarcode: _applyBarcode,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('寄賣入庫'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _barcodeCtl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '條碼',
                hintText: '掃碼或輸入 11 碼 TAAZE 商品編號',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: '相機掃碼',
                      icon: const Icon(Icons.qr_code_scanner_outlined),
                      onPressed: _lookingUp ? null : _openCameraScan,
                    ),
                    IconButton(
                      tooltip: '查詢書目',
                      icon: const Icon(Icons.search),
                      onPressed: _lookingUp ? null : _lookup,
                    ),
                  ],
                ),
              ),
              onSubmitted: (_) => _lookup(),
            ),
            const SizedBox(height: 4),
            Text(
              '可使用 USB 條碼槍掃描（掃完自動查詢），手機／平板可點相機圖示掃碼。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 12),
            if (_lookingUp) const LinearProgressIndicator(),
            if (_preview != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_preview!.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('作者：${_preview!.author}'),
                    Text('出版社：${_preview!.publisher}'),
                    Text('牌價：${_money(_preview!.listPriceCents)}'),
                    Text('售價：${_money(_preview!.salePriceCents)}'),
                    if (_preview!.saleDisc != null) Text('折扣：${_preview!.saleDisc}折'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('入庫數量'),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _qty > 1 ? () => setState(() => _qty -= 1) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(_qty.toStringAsFixed(0)),
                IconButton(
                  onPressed: () => setState(() => _qty += 1),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('確認入庫'),
            ),
            ],
          ],
        ),
      ),
    );
  }
}
