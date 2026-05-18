import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../demo/book_sale_demo.dart';
import '../demo/book_sale_demo_providers.dart';
import '../providers/cart_controller.dart';

/// Demo flow: scan (or tap) books → review cart → checkout.
class BookScanDemoPage extends ConsumerStatefulWidget {
  const BookScanDemoPage({super.key});

  @override
  ConsumerState<BookScanDemoPage> createState() => _BookScanDemoPageState();
}

class _BookScanDemoPageState extends ConsumerState<BookScanDemoPage> {
  String? _lastScanned;

  Future<void> _addBook(DemoBook book) async {
    final product = BookSaleDemo.toProduct(book);
    await ref.read(cartControllerProvider.notifier).addProduct(product);
    if (!mounted) return;
    setState(() => _lastScanned = book.title);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已加入：${book.title}'),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!BookSaleDemo.enabled) {
      return Scaffold(
        appBar: AppBar(title: const Text('書籍售賣 Demo')),
        body: const Center(child: Text('Demo 已關閉（BOOK_SALE_DEMO=false）')),
      );
    }

    final cart = ref.watch(cartControllerProvider);
    final booksAsync = ref.watch(bookSaleDemoBooksProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('書籍售賣 Demo'),
        actions: [
          IconButton(
            tooltip: '重新載入書目',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(bookSaleDemoBooksProvider),
          ),
          if (!cart.isEmpty)
            TextButton.icon(
              onPressed: () => context.push('/checkout'),
              icon: const Icon(Icons.point_of_sale),
              label: Text('結帳 ${cart.total.format()}'),
            ),
        ],
      ),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入書目失敗：$e')),
        data: (books) => Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Material(
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.menu_book,
                                  color: theme.colorScheme.onPrimaryContainer),
                              const SizedBox(width: 8),
                              Text(
                                '掃書結帳示範',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Chip(
                                label: const Text('TAAZE API'),
                                visualDensity: VisualDensity.compact,
                                backgroundColor: theme.colorScheme.tertiaryContainer,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '書目來自 TAAZE 最新上架。點選書籍模擬掃碼，或掃商品條碼（API 的 id）。\n'
                            '書籍不會出現在「全部」餐飲網格。',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          if (_lastScanned != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '最近掃入：$_lastScanned',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/scan'),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('開啟相機掃碼'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: SectionHeader(title: '最新書目（${books.length} 本 · 點擊＝掃碼）'),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: books.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final book = books[i];
                        return _BookTile(book: book, onTap: () => _addBook(book));
                      },
                    ),
                  ),
                ],
              ),
            ),
            VerticalDivider(width: 1, color: theme.dividerColor),
            SizedBox(
              width: 360,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_cart_outlined),
                        const SizedBox(width: 8),
                        Text('購物車', style: theme.textTheme.titleMedium),
                        const Spacer(),
                        if (!cart.isEmpty)
                          TextButton(
                            onPressed: () => ref.read(cartControllerProvider.notifier).clear(),
                            child: const Text('清空'),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: cart.isEmpty
                        ? const EmptyState(
                            icon: Icons.qr_code_scanner,
                            title: '尚未掃書',
                            subtitle: '點左側書籍或掃條碼',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(8),
                            itemCount: cart.lines.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final line = cart.lines[i];
                              return ListTile(
                                dense: true,
                                leading: BookCoverThumb(
                                  imageUrl: line.product.imageUrl,
                                  width: 36,
                                  height: 48,
                                ),
                                title: Text(line.product.name,
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                                subtitle: Text('${line.qty.toInt()} 本 · ${line.unitPrice.format()}'),
                                trailing: MoneyText(line.net),
                              );
                            },
                          ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Text('應付'),
                            const Spacer(),
                            MoneyText(
                              cart.total,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        BigButton(
                          icon: Icons.point_of_sale,
                          label: cart.isEmpty ? '請先掃書' : '前往結帳 ${cart.total.format()}',
                          onPressed: cart.isEmpty ? null : () => context.push('/checkout'),
                          minHeight: 64,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.book, required this.onTap});
  final DemoBook book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              BookCoverThumb(imageUrl: book.imageUrl, width: 48, height: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(book.displaySubtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MoneyText(book.price, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '模擬掃碼',
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Book cover from [imageUrl] with placeholder on load/error.
class BookCoverThumb extends StatelessWidget {
  const BookCoverThumb({
    super.key,
    required this.imageUrl,
    this.width = 48,
    this.height = 64,
  });

  final String? imageUrl;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = imageUrl?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: width,
        height: height,
        child: url == null || url.isEmpty
            ? ColoredBox(
                color: theme.colorScheme.secondaryContainer,
                child: Icon(Icons.menu_book, color: theme.colorScheme.onSecondaryContainer),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => ColoredBox(
                  color: theme.colorScheme.secondaryContainer,
                  child: Icon(Icons.broken_image_outlined,
                      color: theme.colorScheme.onSecondaryContainer),
                ),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                  );
                },
              ),
      ),
    );
  }
}
