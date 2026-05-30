import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../../data/printer/printer_providers.dart';

class PrinterSettingsPage extends ConsumerWidget {
  const PrinterSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('印表機設定'),
          bottom: const TabBar(tabs: [
            Tab(text: '收銀（前場）'),
            Tab(text: '廚房（後場）'),
          ]),
        ),
        body: TabBarView(children: [
          _PrinterForm(
            key: const ValueKey('front'),
            label: '收銀印表機',
            provider: printerPrefsProvider,
            isKitchen: false,
          ),
          _PrinterForm(
            key: const ValueKey('kitchen'),
            label: '廚房印表機',
            provider: kitchenPrinterPrefsProvider,
            isKitchen: true,
            description:
                '桌邊訂單接受後會列印製作單到此印表機。若未啟用，KDS 流程仍可運作（僅省略列印）。',
          ),
        ]),
      ),
    );
  }
}

class _PrinterForm extends ConsumerStatefulWidget {
  const _PrinterForm({
    super.key,
    required this.label,
    required this.provider,
    required this.isKitchen,
    this.description,
  });

  final String label;
  final StateNotifierProvider<PrinterPrefsController, PrinterPreferences> provider;
  final bool isKitchen;
  final String? description;

  @override
  ConsumerState<_PrinterForm> createState() => _PrinterFormState();
}

class _PrinterFormState extends ConsumerState<_PrinterForm> {
  late final TextEditingController _host;
  late final TextEditingController _port;
  late int _paperWidth;
  late bool _enabled;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(widget.provider);
    _host = TextEditingController(text: p.host);
    _port = TextEditingController(text: p.port.toString());
    _paperWidth = p.paperWidth;
    _enabled = p.enabled;
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    super.dispose();
  }

  PrinterPreferences get _draft => PrinterPreferences(
        host: _host.text.trim(),
        port: int.tryParse(_port.text) ?? 9100,
        paperWidth: _paperWidth,
        enabled: _enabled,
      );

  Future<void> _save() async {
    await ref.read(widget.provider.notifier).save(_draft);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已儲存')));
  }

  Future<void> _testPrint() async {
    final host = _host.text.trim();
    if (host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先填寫印表機 IP')),
      );
      return;
    }
    setState(() => _testing = true);
    try {
      await _save();
      final port = int.tryParse(_port.text) ?? 9100;
      if (widget.isKitchen) {
        await ref.read(kitchenPrinterServiceProvider).printTestTicket(
              host: host,
              port: port,
              paperWidth: _paperWidth,
            );
      } else {
        await ref.read(printerServiceProvider).printTestReceipt(
              host: host,
              port: port,
              paperWidth: _paperWidth,
            );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.label} 測試列印已送出')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('測試列印失敗：$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.description != null) ...[
            Text(widget.description!, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
          ],
          SwitchListTile(
            title: Text('啟用 ${widget.label}'),
            subtitle: Text(
              widget.isKitchen
                  ? '關閉時接單仍會成功，但不會列印製作單'
                  : '關閉時結帳仍會成功，但不會列印收據',
            ),
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
          ),
          const SizedBox(height: 12),
          TextField(controller: _host, decoration: const InputDecoration(labelText: '印表機 IP / Hostname')),
          const SizedBox(height: 12),
          TextField(
            controller: _port,
            decoration: const InputDecoration(labelText: 'TCP Port (預設 9100)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _paperWidth,
            decoration: const InputDecoration(labelText: '紙張寬度 (mm)'),
            items: const [
              DropdownMenuItem(value: 58, child: Text('58mm')),
              DropdownMenuItem(value: 80, child: Text('80mm')),
            ],
            onChanged: (v) => setState(() => _paperWidth = v ?? 80),
          ),
          const SizedBox(height: 8),
          Text(
            '印表機需支援 ESC/POS，並與本機在同一區網。可先「測試列印」確認連線，再依流程結帳或接單。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          BigButton(
            icon: Icons.print_outlined,
            label: _testing ? '測試列印中…' : '測試列印',
            onPressed: _testing ? null : _testPrint,
          ),
          const SizedBox(height: 12),
          BigButton(
            icon: Icons.save,
            label: '儲存',
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
