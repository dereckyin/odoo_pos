import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../../data/printer/printer_providers.dart';
import '../../../data/printer/raw_printer_driver.dart';
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
  late PrinterConnectionType _connectionType;
  String? _btAddress;
  String? _btName;
  late bool _btIsBle;
  bool _testing = false;
  bool _scanning = false;
  List<PrinterDevice> _btDevices = const [];

  @override
  void initState() {
    super.initState();
    final p = ref.read(widget.provider);
    _host = TextEditingController(text: p.host);
    _port = TextEditingController(text: p.port.toString());
    _paperWidth = p.paperWidth;
    _enabled = p.enabled;
    _connectionType = p.connectionType;
    _btAddress = p.bluetoothAddress;
    _btName = p.bluetoothName;
    _btIsBle = p.bluetoothIsBle || defaultTargetPlatform == TargetPlatform.iOS;
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
        connectionType: _connectionType,
        bluetoothAddress: _btAddress,
        bluetoothName: _btName,
        bluetoothIsBle: _btIsBle,
      );

  Future<void> _save() async {
    final draft = _draft;
    if (draft.enabled && !draft.hasEndpoint) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            draft.usesBluetooth ? '請先掃描並選擇藍牙印表機' : '請先填寫印表機 IP',
          ),
        ),
      );
      return;
    }
    await ref.read(widget.provider.notifier).save(draft);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已儲存')));
  }

  Future<void> _scanBluetooth() async {
    setState(() {
      _scanning = true;
      _btDevices = const [];
    });
    try {
      final devices = await BluetoothPrinterScanner().scan(isBle: _btIsBle);
      if (!mounted) return;
      setState(() => _btDevices = devices);
      if (devices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未找到藍牙裝置，請確認印表機已開機並可被搜尋')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('藍牙掃描失敗：$e')),
      );
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _testPrint() async {
    final draft = _draft;
    if (!draft.hasEndpoint) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            draft.usesBluetooth ? '請先選擇藍牙印表機' : '請先填寫印表機 IP',
          ),
        ),
      );
      return;
    }
    setState(() => _testing = true);
    try {
      await _save();
      if (widget.isKitchen) {
        await ref.read(kitchenPrinterServiceProvider).printTestTicket(draft.copyWith(enabled: true));
      } else {
        await ref.read(printerServiceProvider).printTestReceipt(draft.copyWith(enabled: true));
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
    final btOk = bluetoothPrintingSupported;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.description != null) ...[
          Text(widget.description!, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
        ],
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('啟用 ${widget.label}'),
          subtitle: Text(
            widget.isKitchen ? '關閉時接單仍會成功，但不會列印製作單' : '關閉時結帳仍會成功，但不會列印收據',
          ),
          value: _enabled,
          onChanged: (v) => setState(() => _enabled = v),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<PrinterConnectionType>(
          value: _connectionType,
          decoration: const InputDecoration(labelText: '連線方式'),
          items: [
            const DropdownMenuItem(
              value: PrinterConnectionType.network,
              child: Text('網路（TCP / Wi‑Fi / 網路線）'),
            ),
            DropdownMenuItem(
              value: PrinterConnectionType.bluetooth,
              enabled: btOk,
              child: Text(btOk ? '藍牙' : '藍牙（僅 Android / iOS）'),
            ),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _connectionType = v);
          },
        ),
        const SizedBox(height: 12),
        if (_connectionType == PrinterConnectionType.network) ...[
          TextField(controller: _host, decoration: const InputDecoration(labelText: '印表機 IP / Hostname')),
          const SizedBox(height: 12),
          TextField(
            controller: _port,
            decoration: const InputDecoration(labelText: 'TCP Port（預設 9100）'),
            keyboardType: TextInputType.number,
          ),
        ] else ...[
          Text(
            _btName == null
                ? '尚未選擇藍牙印表機'
                : '已選擇：$_btName${_btAddress != null ? '（$_btAddress）' : ''}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          if (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.android)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('使用 BLE（低功耗藍牙）'),
              subtitle: Text(
                defaultTargetPlatform == TargetPlatform.iOS
                    ? 'iOS 僅支援 BLE'
                    : '多數熱感機為經典藍牙，請保持關閉；若連線一直斷開再嘗試開啟',
              ),
              value: _btIsBle,
              onChanged: defaultTargetPlatform == TargetPlatform.iOS
                  ? null
                  : (v) => setState(() => _btIsBle = v),
            ),
            const SizedBox(height: 4),
            Text(
              '提示：請先在系統「設定 → 藍牙」與印表機完成配對，再開 App 掃描。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _scanning ? null : _scanBluetooth,
            icon: _scanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bluetooth_searching),
            label: Text(_scanning ? '掃描中…' : '掃描藍牙印表機'),
          ),
          if (_btDevices.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._btDevices.map(
              (d) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.print),
                title: Text(d.name.isEmpty ? '(未命名裝置)' : d.name),
                subtitle: Text(d.address ?? ''),
                selected: d.address == _btAddress,
                onTap: () => setState(() {
                  _btAddress = normalizeBluetoothAddress(d.address) ?? d.address;
                  _btName = d.name.isEmpty ? d.address : d.name;
                }),
              ),
            ),
          ],
        ],
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
        const SizedBox(height: 24),
        BigButton(
          icon: Icons.print_outlined,
          label: _testing ? '測試列印中…' : '測試列印',
          onPressed: _testing ? null : _testPrint,
        ),
        const SizedBox(height: 12),
        BigButton(icon: Icons.save, label: '儲存', onPressed: _save),
      ],
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
  late PrinterConnectionType _connectionType;
  String? _btAddress;
  String? _btName;
  late bool _btIsBle;
  bool _testing = false;
  bool _scanning = false;
  List<PrinterDevice> _btDevices = const [];

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
    _connectionType = p.connectionType;
    _btAddress = p.bluetoothAddress;
    _btName = p.bluetoothName;
    _btIsBle = p.bluetoothIsBle || defaultTargetPlatform == TargetPlatform.iOS;
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
        connectionType: _connectionType,
        bluetoothAddress: _btAddress,
        bluetoothName: _btName,
        bluetoothIsBle: _btIsBle,
      );

  Future<void> _save() async {
    final draft = _draft;
    if (draft.enabled && !draft.hasEndpoint) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(draft.usesBluetooth ? '請先選擇藍牙印表機' : '請先填寫印表機 IP'),
        ),
      );
      return;
    }
    await ref.read(labelPrinterPrefsProvider.notifier).save(draft);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已儲存')));
  }

  Future<void> _scanBluetooth() async {
    setState(() {
      _scanning = true;
      _btDevices = const [];
    });
    try {
      final devices = await BluetoothPrinterScanner().scan(isBle: _btIsBle);
      if (!mounted) return;
      setState(() => _btDevices = devices);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('藍牙掃描失敗：$e')));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _testPrint() async {
    final draft = _draft;
    if (!draft.hasEndpoint) return;
    setState(() => _testing = true);
    try {
      await _save();
      await ref.read(labelPrinterServiceProvider).printTestLabel(draft.copyWith(enabled: true));
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
    final btOk = bluetoothPrintingSupported;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('TSC / Godex 標籤機（TSPL，建議 40×30mm 貼紙）',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('啟用標籤機'),
          subtitle: const Text('飲料等標記「列印標籤」的品項會逐杯出標籤'),
          value: _enabled,
          onChanged: (v) => setState(() => _enabled = v),
        ),
        DropdownButtonFormField<PrinterConnectionType>(
          value: _connectionType,
          decoration: const InputDecoration(labelText: '連線方式'),
          items: [
            const DropdownMenuItem(
              value: PrinterConnectionType.network,
              child: Text('網路（TCP）'),
            ),
            DropdownMenuItem(
              value: PrinterConnectionType.bluetooth,
              enabled: btOk,
              child: Text(btOk ? '藍牙' : '藍牙（僅 Android / iOS）'),
            ),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _connectionType = v);
          },
        ),
        const SizedBox(height: 12),
        if (_connectionType == PrinterConnectionType.network) ...[
          TextField(controller: _host, decoration: const InputDecoration(labelText: '印表機 IP')),
          const SizedBox(height: 12),
          TextField(
            controller: _port,
            decoration: const InputDecoration(labelText: 'TCP Port'),
            keyboardType: TextInputType.number,
          ),
        ] else ...[
          Text(
            _btName == null
                ? '尚未選擇藍牙印表機'
                : '已選擇：$_btName${_btAddress != null ? '（$_btAddress）' : ''}',
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _scanning ? null : _scanBluetooth,
            icon: const Icon(Icons.bluetooth_searching),
            label: Text(_scanning ? '掃描中…' : '掃描藍牙印表機'),
          ),
          ..._btDevices.map(
            (d) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(d.name.isEmpty ? '(未命名裝置)' : d.name),
              subtitle: Text(d.address ?? ''),
              selected: d.address == _btAddress,
              onTap: () => setState(() {
                _btAddress = normalizeBluetoothAddress(d.address) ?? d.address;
                _btName = d.name.isEmpty ? d.address : d.name;
              }),
            ),
          ),
        ],
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
        const SizedBox(height: 24),
        BigButton(
          icon: Icons.label_outlined,
          label: _testing ? '測試列印中…' : '測試標籤',
          onPressed: _testing ? null : _testPrint,
        ),
        const SizedBox(height: 12),
        BigButton(icon: Icons.save, label: '儲存', onPressed: _save),
      ],
    );
  }
}
