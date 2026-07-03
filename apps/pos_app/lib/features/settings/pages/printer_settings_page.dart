import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../../data/printer/printer_providers.dart';
import '../../../data/printer/remote_print_job_worker.dart';

class PrinterSettingsPage extends ConsumerWidget {
  const PrinterSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workstation = ref.watch(printWorkstationEnabledProvider);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('印表機設定'),
          bottom: const TabBar(tabs: [
            Tab(text: '收銀（前場）'),
            Tab(text: '廚房（後場）'),
            Tab(text: '標籤機'),
          ]),
        ),
        body: Column(
          children: [
            SwitchListTile(
              title: const Text('作為列印工作站'),
              subtitle: const Text('接收網頁版 POS 的列印工作並轉發至本機印表機（需保持登入）'),
              value: workstation,
              onChanged: (v) => ref.read(printWorkstationEnabledProvider.notifier).setEnabled(v),
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(children: [
          _EscPosForm(
            key: const ValueKey('front'),
            label: '收銀印表機',
            provider: printerPrefsProvider,
            isKitchen: false,
          ),
          _EscPosForm(
            key: const ValueKey('kitchen'),
            label: '廚房印表機',
            provider: kitchenPrinterPrefsProvider,
            isKitchen: true,
            description: '桌邊訂單接受後會列印製作單到此印表機。若未啟用，KDS 流程仍可運作（僅省略列印）。',
          ),
          _LabelForm(key: const ValueKey('label')),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _EscPosForm extends ConsumerStatefulWidget {
  const _EscPosForm({
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
  ConsumerState<_EscPosForm> createState() => _EscPosFormState();
}

class _EscPosFormState extends ConsumerState<_EscPosForm> {
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
              widget.isKitchen ? '關閉時接單仍會成功，但不會列印製作單' : '關閉時結帳仍會成功，但不會列印收據',
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
          const Spacer(),
          BigButton(
            icon: Icons.print_outlined,
            label: _testing ? '測試列印中…' : '測試列印',
            onPressed: _testing ? null : _testPrint,
          ),
          const SizedBox(height: 12),
          BigButton(icon: Icons.save, label: '儲存', onPressed: _save),
        ],
      ),
    );
  }
}

class _LabelForm extends ConsumerStatefulWidget {
  const _LabelForm({super.key});

  @override
  ConsumerState<_LabelForm> createState() => _LabelFormState();
}

class _LabelFormState extends ConsumerState<_LabelForm> {
  late final TextEditingController _host;
  late final TextEditingController _port;
  late int _labelW;
  late int _labelH;
  late double _gap;
  late bool _enabled;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(labelPrinterPrefsProvider);
    _host = TextEditingController(text: p.host);
    _port = TextEditingController(text: p.port.toString());
    _labelW = p.labelWidthMm;
    _labelH = p.labelHeightMm;
    _gap = p.gapMm;
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
        enabled: _enabled,
        kind: PrinterKind.tspl,
        labelWidthMm: _labelW,
        labelHeightMm: _labelH,
        gapMm: _gap,
      );

  Future<void> _save() async {
    await ref.read(labelPrinterPrefsProvider.notifier).save(_draft);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已儲存')));
  }

  Future<void> _testPrint() async {
    final host = _host.text.trim();
    if (host.isEmpty) return;
    setState(() => _testing = true);
    try {
      await _save();
      await ref.read(labelPrinterServiceProvider).printTestLabel(
            host: host,
            port: int.tryParse(_port.text) ?? 9100,
            labelWidthMm: _labelW,
            labelHeightMm: _labelH,
            gapMm: _gap,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('標籤測試列印已送出')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('測試列印失敗：$e')));
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
          Text('TSC / Godex 標籤機（TSPL，建議 40×30mm 貼紙）',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('啟用標籤機'),
            subtitle: const Text('飲料等標記「列印標籤」的品項會逐杯出標籤'),
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
          ),
          TextField(controller: _host, decoration: const InputDecoration(labelText: '印表機 IP')),
          const SizedBox(height: 12),
          TextField(
            controller: _port,
            decoration: const InputDecoration(labelText: 'TCP Port'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _labelW,
                decoration: const InputDecoration(labelText: '寬 mm'),
                items: const [
                  DropdownMenuItem(value: 40, child: Text('40')),
                  DropdownMenuItem(value: 50, child: Text('50')),
                ],
                onChanged: (v) => setState(() => _labelW = v ?? 40),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _labelH,
                decoration: const InputDecoration(labelText: '高 mm'),
                items: const [
                  DropdownMenuItem(value: 30, child: Text('30')),
                  DropdownMenuItem(value: 25, child: Text('25')),
                ],
                onChanged: (v) => setState(() => _labelH = v ?? 30),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<double>(
            value: _gap,
            decoration: const InputDecoration(labelText: '標籤間距 GAP (mm)'),
            items: const [
              DropdownMenuItem(value: 2, child: Text('2')),
              DropdownMenuItem(value: 3, child: Text('3')),
            ],
            onChanged: (v) => setState(() => _gap = v ?? 2),
          ),
          const Spacer(),
          BigButton(
            icon: Icons.label_outlined,
            label: _testing ? '測試列印中…' : '測試標籤',
            onPressed: _testing ? null : _testPrint,
          ),
          const SizedBox(height: 12),
          BigButton(icon: Icons.save, label: '儲存', onPressed: _save),
        ],
      ),
    );
  }
}
