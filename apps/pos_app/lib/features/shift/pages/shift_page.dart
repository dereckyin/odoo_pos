import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../../core/providers.dart';
import '../../../core/user_facing_error.dart';
import '../../../data/printer/escpos_zh.dart';
import '../../../data/printer/printer_providers.dart';

/// Shift open + close (開班 / 交班結帳). On close we compare the cashier's
/// counted cash against the expected drawer and print a Z report.
class ShiftPage extends ConsumerStatefulWidget {
  const ShiftPage({super.key});

  @override
  ConsumerState<ShiftPage> createState() => _ShiftPageState();
}

class _ShiftPageState extends ConsumerState<ShiftPage> {
  bool _loading = true;
  bool _busy = false;
  Map<String, dynamic>? _shift;
  Map<String, dynamic>? _summary;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(posApiProvider);
      final shift = await api.currentShift();
      Map<String, dynamic>? summary;
      if (shift != null) {
        summary = await api.currentShiftSummary();
      }
      if (!mounted) return;
      setState(() {
        _shift = shift;
        _summary = summary;
      });
    } catch (e) {
      if (mounted) setState(() => _error = formatUserFacingError(e, scene: UserErrorScene.general));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _money(int cents) => 'NT\$ ${(cents / 100).toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('交班結帳'),
        actions: [
          IconButton(onPressed: _loading ? null : _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _shift == null
                  ? _buildOpen(context)
                  : _buildClose(context),
    );
  }

  Widget _buildOpen(BuildContext context) {
    final cashCtl = TextEditingController(text: '0');
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.point_of_sale, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text('目前尚未開班', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextField(
                controller: cashCtl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '開班備用金（元）'),
              ),
              const SizedBox(height: 16),
              BigButton(
                icon: Icons.play_arrow,
                label: _busy ? '處理中…' : '開班',
                onPressed: _busy
                    ? null
                    : () async {
                        final yuan = int.tryParse(cashCtl.text.trim()) ?? 0;
                        await _open(yuan * 100);
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClose(BuildContext context) {
    final s = _summary;
    final byMethod = (s?['by_method_cents'] as Map?)?.cast<String, dynamic>() ?? {};
    final countedCtl = TextEditingController();
    final opening = (_shift?['opening_cash_cents'] as num?)?.toInt() ?? 0;
    final expectedCash = (s?['expected_cash_cents'] as num?)?.toInt() ?? 0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('本班彙總', style: Theme.of(context).textTheme.titleMedium),
                const Divider(),
                _kv('開班備用金', _money(opening)),
                _kv('訂單數', '${(s?['order_count'] as num?)?.toInt() ?? 0} 筆'),
                _kv('銷售總額', _money((s?['sales_total_cents'] as num?)?.toInt() ?? 0)),
                _kv('退款總額', _money((s?['refund_total_cents'] as num?)?.toInt() ?? 0)),
                const Divider(),
                ...byMethod.entries.map((e) => _kv('  ${e.key}', _money((e.value as num).toInt()))),
                const Divider(),
                _kv('應有現金', _money(expectedCash), bold: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: countedCtl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '實點現金（元）'),
        ),
        const SizedBox(height: 16),
        BigButton(
          icon: Icons.stop_circle,
          label: _busy ? '結帳中…' : '交班結帳並列印 Z 報表',
          onPressed: _busy
              ? null
              : () async {
                  final yuan = int.tryParse(countedCtl.text.trim()) ?? 0;
                  await _close(yuan * 100);
                },
        ),
      ],
    );
  }

  Widget _kv(String k, String v, {bool bold = false}) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.w700) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(k, style: style)),
          Text(v, style: style),
        ],
      ),
    );
  }

  Future<void> _open(int openingCents) async {
    setState(() => _busy = true);
    try {
      await ref.read(posApiProvider).openShift(openingCashCents: openingCents);
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatUserFacingError(e, scene: UserErrorScene.general))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _close(int countedCents) async {
    setState(() => _busy = true);
    try {
      final closed = await ref.read(posApiProvider).closeShift(countedCashCents: countedCents);
      await _printZReport(closed);
      if (!mounted) return;
      final diff = (closed['diff_cents'] as num?)?.toInt() ?? 0;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('已交班'),
          content: Text(
            '應有現金 ${_money((closed['expected_cash_cents'] as num?)?.toInt() ?? 0)}\n'
            '實點現金 ${_money((closed['counted_cash_cents'] as num?)?.toInt() ?? 0)}\n'
            '差異 ${diff >= 0 ? '+' : ''}${_money(diff)}',
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('確定'))],
        ),
      );
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatUserFacingError(e, scene: UserErrorScene.general))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _printZReport(Map<String, dynamic> shift) async {
    final prefs = ref.read(printerPrefsProvider);
    if (!prefs.enabled) return; // no printer configured; on-screen summary only
    try {
      final profile = await CapabilityProfile.load();
      final gen = Generator(paperSizeFromMm(prefs.paperWidth), profile);
      final bytes = <int>[];
      final df = DateFormat('yyyy/MM/dd HH:mm:ss');
      final totals = (shift['totals_json'] as Map?)?.cast<String, dynamic>() ?? {};
      final byMethod = (totals['by_method'] as Map?)?.cast<String, dynamic>() ?? {};

      bytes.addAll(escText(gen, 'Z 報表 / 交班結帳',
          styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2)));
      bytes.addAll(escText(gen, '=' * 32, styles: const PosStyles(align: PosAlign.center)));
      bytes.addAll(escText(gen, '交班時間: ${df.format(DateTime.now())}'));
      bytes.addAll(escText(gen, '-' * 32, styles: const PosStyles(align: PosAlign.center)));
      bytes.addAll(_zrow(gen, '開班備用金', (shift['opening_cash_cents'] as num?)?.toInt() ?? 0));
      bytes.addAll(_zrow(gen, '訂單數', (totals['order_count'] as num?)?.toInt() ?? 0, raw: true));
      bytes.addAll(_zrow(gen, '銷售總額', (totals['sales_total'] as num?)?.toInt() ?? 0));
      bytes.addAll(_zrow(gen, '退款總額', (totals['refund_total'] as num?)?.toInt() ?? 0));
      bytes.addAll(escText(gen, '-' * 32, styles: const PosStyles(align: PosAlign.center)));
      for (final e in byMethod.entries) {
        bytes.addAll(_zrow(gen, e.key, (e.value as num).toInt()));
      }
      bytes.addAll(escText(gen, '-' * 32, styles: const PosStyles(align: PosAlign.center)));
      bytes.addAll(_zrow(gen, '應有現金', (shift['expected_cash_cents'] as num?)?.toInt() ?? 0));
      bytes.addAll(_zrow(gen, '實點現金', (shift['counted_cash_cents'] as num?)?.toInt() ?? 0));
      bytes.addAll(_zrow(gen, '差異', (shift['diff_cents'] as num?)?.toInt() ?? 0));
      bytes.addAll(gen.feed(2));
      bytes.addAll(gen.cut());

      await ref.read(rawPrinterDriverProvider).printBytes(prefs, Uint8List.fromList(bytes));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Z 報表列印失敗，請確認印表機設定')),
        );
      }
    }
  }

  List<int> _zrow(Generator gen, String k, int v, {bool raw = false}) => gen.row([
        escCol(k, width: 6),
        escCol(
          raw ? '$v' : 'NT\$ ${(v / 100).toStringAsFixed(0)}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
}
