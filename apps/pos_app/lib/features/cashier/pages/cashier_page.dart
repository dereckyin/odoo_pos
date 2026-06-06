import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_domain/pos_domain.dart';

import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/scanner/barcode_listener.dart';
import '../../../core/roles.dart';
import '../../books/providers/consignment_providers.dart';
import '../../../data/sync/sync_providers.dart';
import '../../sync/widgets/master_data_sync_button.dart';
import '../../kds/providers/guest_orders_controller.dart';
import '../../products/providers/product_providers.dart';
import '../providers/cart_controller.dart';
import '../providers/held_cart_repository.dart';
import '../widgets/cart_panel.dart';
import '../widgets/category_bar.dart';
import '../widgets/option_picker_sheet.dart';
import '../widgets/product_grid.dart';

class CashierPage extends ConsumerStatefulWidget {
  const CashierPage({super.key});

  @override
  ConsumerState<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends ConsumerState<CashierPage> {
  final _searchCtl = TextEditingController();
  String _query = '';
  String? _categoryId;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(guestOrdersControllerProvider.notifier).startPolling();
      ref.read(consignmentPosConfigProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _debounce?.cancel();
    ref.read(guestOrdersControllerProvider.notifier).stopPolling();
    super.dispose();
  }

  void _setQuery(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      setState(() => _query = q.trim());
    });
  }

  Future<void> _onBarcode(String code) async {
    final err = await ref.read(cartControllerProvider.notifier).scanBarcode(code);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authStateProvider).session;
    final pendingCount = ref.watch(pendingSyncCountProvider).maybeWhen(data: (v) => v, orElse: () => 0);
    final guestOrders = ref.watch(guestOrdersControllerProvider);
    final pendingTableOrders = guestOrders.ofStatus('submitted').length;
    final cart = ref.watch(cartControllerProvider);
    final heldCount = ref.watch(heldCartSummariesProvider).maybeWhen(data: (v) => v.length, orElse: () => 0);
    final l10n = AppLocalizations.of(context)!;

    return BarcodeKeyboardListener(
      onBarcode: _onBarcode,
      child: Scaffold(
        appBar: AppBar(
          title: Row(children: [
            const Icon(Icons.point_of_sale),
            const SizedBox(width: 8),
            const Text('收銀'),
            const SizedBox(width: 12),
            if (session != null)
              Chip(
                  label: Text(
                      '店 ${_shortIdChip(session.storeId)} / 機 ${_shortIdChip(session.terminalId)}')),
          ]),
          actions: [
            const MasterDataSyncButton(),
            if (pendingCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Tooltip(
                    message: '尚有 $pendingCount 筆待同步',
                    child: Chip(
                      avatar: const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: Text('待同步 $pendingCount'),
                    ),
                  ),
                ),
              ),
            if (ref.watch(consignmentPosConfigProvider).enabled) ...[
              IconButton(
                tooltip: '寄賣書籍查詢',
                icon: const Icon(Icons.menu_book_outlined),
                onPressed: () => context.push('/books/search'),
              ),
              if (session != null && isStoreAdminRole(session.role))
                IconButton(
                  tooltip: '寄賣入庫',
                  icon: const Icon(Icons.inventory_outlined),
                  onPressed: () => context.push('/books/receive'),
                ),
            ],
            IconButton(
              tooltip: '商品管理',
              icon: const Icon(Icons.inventory_2_outlined),
              onPressed: () => context.push('/products'),
            ),
            IconButton(
              tooltip: '會員',
              icon: const Icon(Icons.badge_outlined),
              onPressed: () => context.push('/members'),
            ),
            IconButton(
              tooltip: '庫存',
              icon: const Icon(Icons.warehouse_outlined),
              onPressed: () => context.push('/inventory'),
            ),
            IconButton(
              tooltip: '行銷',
              icon: const Icon(Icons.campaign_outlined),
              onPressed: () => context.push('/promotions'),
            ),
            IconButton(
              tooltip: l10n.parkOrder,
              icon: const Icon(Icons.pause_circle_outline),
              onPressed: cart.isEmpty
                  ? null
                  : () async {
                      try {
                        await ref.read(cartControllerProvider.notifier).park();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.parkSuccess)),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$e'),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    },
            ),
            IconButton(
              tooltip: l10n.recallHeldOrders,
              onPressed: () => context.push('/held-orders'),
              icon: Badge(
                isLabelVisible: heldCount > 0,
                label: Text('$heldCount'),
                child: const Icon(Icons.playlist_play_outlined),
              ),
            ),
            IconButton(
              tooltip: pendingTableOrders > 0
                  ? '桌邊訂單（$pendingTableOrders 筆待接單）'
                  : '桌邊訂單',
              onPressed: () => context.push('/table-orders'),
              icon: Badge(
                isLabelVisible: pendingTableOrders > 0,
                label: Text('$pendingTableOrders'),
                child: const Icon(Icons.table_restaurant_outlined),
              ),
            ),
            IconButton(
              tooltip: '訂單記錄',
              icon: const Icon(Icons.receipt_long_outlined),
              onPressed: () => context.push('/history'),
            ),
            IconButton(
              tooltip: '設定',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push('/settings'),
            ),
          ],
        ),
        body: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  _SearchBar(
                    controller: _searchCtl,
                    onChanged: _setQuery,
                    onScan: () => context.push('/scan'),
                  ),
                  CategoryBar(
                    selectedId: _categoryId,
                    onSelected: (id) => setState(() => _categoryId = id),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ProductGrid(
                      query: _query,
                      categoryId: _categoryId,
                      onTap: (Product p) async {
                        final repo = ref.read(productRepositoryProvider);
                        final product = await repo.findById(p.id) ?? p;
                        if (!context.mounted) return;
                        final ctl = ref.read(cartControllerProvider.notifier);
                        if (product.isWeighted) {
                          final qty = await _promptDecimal(context, '輸入重量 (${product.unit})');
                          if (qty != null && qty > 0) await ctl.addProduct(product, qty: qty);
                        } else if (product.hasOptions) {
                          final options = await OptionPickerSheet.show(context, product: product);
                          if (!context.mounted) return;
                          if (options != null) {
                            await ctl.addProductWithOptions(product, options);
                          }
                        } else {
                          await ctl.addProduct(product);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            CartPanel(
              onCheckout: () => context.push('/checkout'),
              onMember: () => context.push('/members/select'),
            ),
          ],
        ),
      ),
    );
  }

  Future<double?> _promptDecimal(BuildContext context, String title) async {
    final c = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          autofocus: true,
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(c.text);
              Navigator.pop(context, v);
            },
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged, required this.onScan});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: '搜尋名稱 / SKU / 條碼',
          suffixIcon: IconButton(
            tooltip: '相機掃碼',
            icon: const Icon(Icons.qr_code_scanner_outlined),
            onPressed: onScan,
          ),
        ),
      ),
    );
  }
}

String _shortIdChip(String? id) {
  if (id == null || id.isEmpty) return '—';
  return id.length < 6 ? id : id.substring(0, 6);
}
