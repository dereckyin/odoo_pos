import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../providers/member_providers.dart';

class MembersPage extends ConsumerStatefulWidget {
  const MembersPage({super.key});

  @override
  ConsumerState<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends ConsumerState<MembersPage> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(memberSearchProvider(_q));
    return Scaffold(
      appBar: AppBar(title: const Text('會員')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: '搜尋姓名 / 手機',
            ),
            onChanged: (v) => setState(() => _q = v.trim()),
          ),
        ),
        Expanded(
          child: asyncList.when(
            data: (list) {
              if (list.isEmpty) {
                return const EmptyState(icon: Icons.people_outline, title: '尚無會員');
              }
              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final m = list[i];
                  return ListTile(
                    title: Text(m.name),
                    subtitle: Text('${m.phone}・${m.points}點${m.level == null ? '' : '・${m.level!.name}'}'),
                    trailing: Text('累積消費 ${m.totalSpentMajor.toStringAsFixed(0)}'),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('錯誤: $e')),
          ),
        ),
      ]),
    );
  }
}
