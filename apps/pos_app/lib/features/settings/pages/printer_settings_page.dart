import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../../data/printer/printer_providers.dart';

class PrinterSettingsPage extends ConsumerStatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  ConsumerState<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends ConsumerState<PrinterSettingsPage> {
  late final TextEditingController _host;
  late final TextEditingController _port;
  late int _paperWidth;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    final p = ref.read(printerPrefsProvider);
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
    return Scaffold(
      appBar: AppBar(title: const Text('印表機設定')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              title: const Text('啟用 ESC/POS 列印'),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
            const SizedBox(height: 12),
            TextField(controller: _host, decoration: const InputDecoration(labelText: '印表機 IP / Hostname')),
            const SizedBox(height: 12),
            TextField(controller: _port, decoration: const InputDecoration(labelText: 'TCP Port (預設 9100)'), keyboardType: TextInputType.number),
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
                await ref.read(printerPrefsProvider.notifier).save(PrinterPreferences(
                      host: _host.text.trim(),
                      port: int.tryParse(_port.text) ?? 9100,
                      paperWidth: _paperWidth,
                      enabled: _enabled,
                    ));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已儲存')));
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
