import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/api/dto.dart';
import '../../../data/printer/print_orchestrator.dart';

Future<void> showOpenTableQrSheet(BuildContext context, WidgetRef ref) async {
  final session = ref.read(authStateProvider).session;
  if (session?.storeId == null) return;

  try {
    final api = ref.read(posApiProvider);
    final tables = await api.listDiningTables(storeId: session!.storeId!);
    if (!context.mounted) return;
    if (tables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('尚無桌位，請至後台建立')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('開桌並列印點餐 QR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: tables.length,
                itemBuilder: (_, i) {
                  final t = tables[i];
                  return ListTile(
                    leading: const Icon(Icons.table_restaurant_outlined),
                    title: Text('桌 ${t.label}'),
                    subtitle: t.seats != null ? Text('${t.seats} 人座') : null,
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        final opened = await api.openTableSession(t.id);
                        final orch = ref.read(printOrchestratorProvider);
                        await orch.printTableSessionQr(
                          tableLabel: opened.tableLabel,
                          orderUrl: opened.customerOrderUrl,
                          expiresAt: opened.session.expiresAt,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('已列印 ${opened.tableLabel} 點餐 QR')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('開桌失敗：$e')),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('載入桌位失敗：$e')),
      );
    }
  }
}
