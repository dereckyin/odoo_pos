import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_domain/pos_domain.dart';

import '../../../core/providers.dart';
import '../../../data/scanner/barcode_listener.dart';
import '../../../data/sync/delta_puller.dart';
import '../../../data/sync/sync_providers.dart';
import '../providers/cart_controller.dart';
import '../widgets/cart_panel.dart';
import '../widgets/category_bar.dart';
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
      final storeId = ref.read(authStateProvider).session?.storeId;
      ref.read(syncWorkerProvider).start();
      ref.read(deltaPullerProvider).start(storeId: storeId);
    });
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _setQuery(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      setState(() => _query = q.trim());
    });
  }

  Future<void> _onBarcode(String code) async {
    final ok = await ref.read(cartControllerProvider.notifier).scanBarcode(code);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('找不到條碼: $code')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authStateProvider).session;
    final pendingCount = ref.watch(pendingSyncCountProvider).maybeWhen(data: (v) => v, orElse: () => 0);

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
              Chip(label: Text('店 ${session.storeId.substring(0, 6)} / 機 ${session.terminalId.substring(0, 6)}')),
          ]),
          actions: [
            _SyncIndicator(),
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
                        final ctl = ref.read(cartControllerProvider.notifier);
                        if (p.isWeighted) {
                          final qty = await _promptDecimal(context, '輸入重量 (${p.unit})');
                          if (qty != null && qty > 0) await ctl.addProduct(p, qty: qty);
                        } else {
                          await ctl.addProduct(p);
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

class _SyncIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(deltaPullStatusProvider);
    return status.when(
      data: (s) {
        final isSyncing = s.state == DeltaPullState.syncing;
        final tooltip = s.lastPullAt != null
            ? '上次同步: ${_formatTime(s.lastPullAt!)}'
            : '尚未同步';
        return IconButton(
          tooltip: isSyncing ? '同步中…' : '$tooltip（點擊立即同步）',
          icon: isSyncing
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(
                  s.state == DeltaPullState.error
                      ? Icons.sync_problem
                      : Icons.sync,
                  color: s.state == DeltaPullState.error
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
          onPressed: isSyncing ? null : () => ref.read(deltaPullerProvider).pullAll(),
        );
      },
      loading: () => const SizedBox(
        width: 20, height: 20,
        child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => IconButton(
        tooltip: '同步失敗，點擊重試',
        icon: Icon(Icons.sync_problem, color: Theme.of(context).colorScheme.error),
        onPressed: () => ref.read(deltaPullerProvider).pullAll(),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
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
