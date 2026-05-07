import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_domain/pos_domain.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../cashier/providers/cart_controller.dart';
import '../../../core/providers.dart';
import '../providers/member_providers.dart';

class MemberSelectPage extends ConsumerStatefulWidget {
  const MemberSelectPage({super.key});

  @override
  ConsumerState<MemberSelectPage> createState() => _MemberSelectPageState();
}

class _MemberSelectPageState extends ConsumerState<MemberSelectPage> {
  final _ctl = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(memberSearchProvider(_query));
    return Scaffold(
      appBar: AppBar(title: const Text('選擇會員')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _ctl,
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '輸入手機/姓名（也接受 QR）',
              ),
              onSubmitted: (v) async {
                final api = ref.read(posApiProvider);
                final q = v.trim();
                if (q.isEmpty) return;
                final remote =
                    await api.findMemberByPhone(q) ?? await api.findMemberByQr(q);
                if (!mounted) return;
                if (remote != null) {
                  _bindAndPop(_dtoToDomain(remote));
                  return;
                }
                setState(() => _query = q);
              },
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: asyncList.when(
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.person_search,
                    title: '尚無會員',
                    subtitle: '可在後台新增會員，或於此處新增',
                    action: FilledButton.icon(
                      onPressed: () => _showCreate(context),
                      icon: const Icon(Icons.person_add),
                      label: const Text('新增會員'),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final m = list[i];
                    return ListTile(
                      title: Text(m.name),
                      subtitle: Text('${m.phone}・${m.points}點${m.level == null ? '' : '・${m.level!.name}'}'),
                      onTap: () => _bindAndPop(m),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('錯誤: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreate(context),
        icon: const Icon(Icons.person_add),
        label: const Text('新會員'),
      ),
    );
  }

  void _bindAndPop(Member m) {
    ref.read(cartControllerProvider.notifier).setMember(m);
    if (mounted) context.pop();
  }

  Member _dtoToDomain(dynamic d) => Member(
        id: d.id, phone: d.phone, name: d.name, email: d.email,
        birthday: d.birthday, points: d.points, totalSpentMajor: 0,
        qrCode: d.qrCode, joinedAt: d.joinedAt, lastVisitAt: d.lastVisitAt,
      );

  Future<void> _showCreate(BuildContext context) async {
    final phone = TextEditingController();
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('新增會員'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: phone, decoration: const InputDecoration(labelText: '手機')),
            TextField(controller: name, decoration: const InputDecoration(labelText: '姓名')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('建立')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final api = ref.read(posApiProvider);
      final m = await api.createMember({'phone': phone.text.trim(), 'name': name.text.trim()});
      _bindAndPop(_dtoToDomain(m));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('錯誤: $e')));
    }
  }
}
