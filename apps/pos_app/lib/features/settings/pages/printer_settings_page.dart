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
          ),
          _PrinterForm(
            key: const ValueKey('kitchen'),
            label: '廚房印表機',
            provider: kitchenPrinterPrefsProvider,
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
    this.description,
  });

  final String label;
  final StateNotifierProvider<PrinterPrefsController, PrinterPreferences> provider;
  final String? description;

  @override
  ConsumerState<_PrinterForm> createState() => _PrinterFormState();
}

class _PrinterFormState extends ConsumerState<_PrinterForm> {
  late final TextEditingController _host;
  late final TextEditingController _port;
  late int _paperWidth;
  late bool _enabled;

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
          const Spacer(),
          BigButton(
            icon: Icons.save,
            label: '儲存',
            onPressed: () async {
              await ref.read(widget.provider.notifier).save(PrinterPreferences(
                    host: _host.text.trim(),
                    port: int.tryParse(_port.text) ?? 9100,
                    paperWidth: _paperWidth,
                    enabled: _enabled,
                  ));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已儲存')));
            },
          ),
        ],
      ),
    );
  }
}
