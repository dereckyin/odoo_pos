import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_domain/pos_domain.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../cashier/providers/cart_controller.dart';
import '../book_local_store.dart';
import '../providers/book_providers.dart';
import '../../../core/providers.dart';

class BookSearchPage extends ConsumerStatefulWidget {
  const BookSearchPage({super.key});

  @override
  ConsumerState<BookSearchPage> createState() => _BookSearchPageState();
}

class _BookSearchPageState extends ConsumerState<BookSearchPage> {
  final _queryCtl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryCtl.dispose();
    super.dispose();
  }

  Future<void> _addBook(Product product) async {
    await ref.read(cartControllerProvider.notifier).addProduct(product);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已加入：${product.name}')),
    );
  }

  Future<void> _scanRemote(String code) async {
    try {
      final api = ref.read(posApiProvider);
      final store = ref.read(bookLocalStoreProvider);
      final dto = await api.scanBook(code);
      await store.upsertFromDto(dto);
      await _addBook(store.toProduct(dto));
      setState(() => _query = code);
      _queryCtl.text = code;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('查無書籍：$code')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(bookSearchProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('寄賣書籍查詢'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _queryCtl,
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: '書名 / 作者 / 條碼',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner_outlined),
                  onPressed: () => context.push('/scan'),
                ),
              ),
              onSubmitted: (v) => setState(() => _query = v.trim()),
              onChanged: (v) {
                if (v.trim().length >= 2) setState(() => _query = v.trim());
              },
            ),
          ),
          Expanded(
            child: booksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('查詢失敗：$e')),
              data: (books) {
                if (_query.isEmpty) {
                  return const Center(child: Text('輸入關鍵字搜尋寄賣書籍'));
                }
                if (books.isEmpty) {
                  final looksBarcode = RegExp(r'^\d{8,11}$').hasMatch(_query);
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('本地無結果'),
                        if (looksBarcode) ...[
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => _scanRemote(_query),
                            child: Text('向伺服器查詢條碼 $_query'),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: books.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final b = books[i];
                    return ListTile(
                      leading: const Icon(Icons.menu_book_outlined),
                      title: Text(b.name),
                      subtitle: Text(
                        [if (b.bookAuthor != null) b.bookAuthor, if (b.barcodes.isNotEmpty) b.barcodes.first]
                            .whereType<String>()
                            .join(' · '),
                      ),
                      trailing: MoneyText(b.price),
                      onTap: () => _addBook(b),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
