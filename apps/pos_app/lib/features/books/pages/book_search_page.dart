import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_domain/pos_domain.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../cashier/providers/cart_controller.dart';
import '../providers/book_providers.dart';

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
    final err = await ref.read(cartControllerProvider.notifier).scanBarcode(
          product.barcodes.isNotEmpty ? product.barcodes.first : product.sku,
        );
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已加入：${product.name}')),
    );
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
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '書名 / 作者 / 條碼（僅已入庫書籍）',
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
                  return const Center(child: Text('輸入關鍵字搜尋已入庫的寄賣書籍'));
                }
                if (books.isEmpty) {
                  return const Center(child: Text('找不到書籍，請確認已入庫並完成同步'));
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
