import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/api/dto.dart';
import '../providers/guest_orders_controller.dart';
import '../widgets/guest_order_card.dart';

/// Three-column kitchen display:
///  待接受 (submitted) -> 烹調中 (accepted) -> 待結帳 (ready)
class KdsBoardPage extends ConsumerStatefulWidget {
  const KdsBoardPage({super.key});

  @override
  ConsumerState<KdsBoardPage> createState() => _KdsBoardPageState();
}

class _KdsBoardPageState extends ConsumerState<KdsBoardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(guestOrdersControllerProvider.notifier).startPolling();
    });
  }

  @override
  void dispose() {
    ref.read(guestOrdersControllerProvider.notifier).stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authStateProvider).session;
    final snapshot = ref.watch(guestOrdersControllerProvider);

    final submitted = snapshot.ofStatus('submitted');
    final accepted = snapshot.ofStatus('accepted');
    final ready = snapshot.ofStatus('ready');

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.restaurant),
          const SizedBox(width: 8),
          const Text('廚房 KDS'),
          const SizedBox(width: 12),
          if (session != null)
            Chip(
                label: Text(
                    '店 ${_shortIdChip(session.storeId)}・${session.displayName}')),
        ]),
        actions: [
          IconButton(
            tooltip: '重新整理',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(guestOrdersControllerProvider.notifier).refresh(),
          ),
          IconButton(
            tooltip: '設定',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
          IconButton(
            tooltip: '登出',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (snapshot.lastError != null)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.all(8),
              child: Text(
                '同步失敗：${snapshot.lastError}',
                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
              ),
            ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _Column(
                    title: '待接受',
                    color: Colors.orange.shade50,
                    accent: Colors.orange,
                    items: submitted,
                    primaryLabel: '接受並印單',
                    onPrimary: (o) => _accept(o),
                    secondaryLabel: '取消',
                    onSecondary: (o) => _cancel(o),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _Column(
                    title: '烹調中',
                    color: Colors.blue.shade50,
                    accent: Colors.blue,
                    items: accepted,
                    primaryLabel: '完成',
                    onPrimary: (o) => _ready(o),
                    secondaryLabel: '取消',
                    onSecondary: (o) => _cancel(o),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _Column(
                    title: '待結帳',
                    color: Colors.green.shade50,
                    accent: Colors.green,
                    items: ready,
                    primaryLabel: null,
                    onPrimary: null,
                    secondaryLabel: '取消',
                    onSecondary: (o) => _cancel(o),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _accept(GuestOrderDto o) async {
    try {
      await ref.read(guestOrdersControllerProvider.notifier).accept(o);
      _toast('已接受並送出至廚房印表機');
    } catch (e) {
      _toast('接受失敗：$e', error: true);
    }
  }

  Future<void> _ready(GuestOrderDto o) async {
    try {
      await ref.read(guestOrdersControllerProvider.notifier).markReady(o);
    } catch (e) {
      _toast('更新失敗：$e', error: true);
    }
  }

  Future<void> _cancel(GuestOrderDto o) async {
    final reason = await _askReason();
    if (reason == null) return;
    try {
      await ref.read(guestOrdersControllerProvider.notifier).cancel(o, reason: reason);
    } catch (e) {
      _toast('取消失敗：$e', error: true);
    }
  }

  Future<String?> _askReason() async {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('取消原因'),
        content: TextField(
          autofocus: true,
          controller: c,
          decoration: const InputDecoration(hintText: '例：缺料、客人取消'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('放棄')),
          FilledButton(
            onPressed: () => Navigator.pop(context, c.text.trim()),
            child: const Text('確認取消'),
          ),
        ],
      ),
    );
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({
    required this.title,
    required this.color,
    required this.accent,
    required this.items,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final String title;
  final Color color;
  final Color accent;
  final List<GuestOrderDto> items;
  final String? primaryLabel;
  final void Function(GuestOrderDto)? onPrimary;
  final String? secondaryLabel;
  final void Function(GuestOrderDto)? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: accent,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                '$title (${items.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      '目前無訂單',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    children: items
                        .map((o) => GuestOrderCard(
                              order: o,
                              primaryLabel: primaryLabel,
                              onPrimary: onPrimary != null ? () => onPrimary!(o) : null,
                              secondaryLabel: secondaryLabel,
                              onSecondary:
                                  onSecondary != null ? () => onSecondary!(o) : null,
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

String _shortIdChip(String? id) {
  if (id == null || id.isEmpty) return '—';
  return id.length < 6 ? id : id.substring(0, 6);
}
