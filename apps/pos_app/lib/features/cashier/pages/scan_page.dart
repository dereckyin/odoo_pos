import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../demo/book_sale_demo.dart';
import '../demo/book_sale_demo_providers.dart';
import '../providers/cart_controller.dart';

bool get _isSimulatorOrDesktop {
  if (kIsWeb) return false;
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) return true;
  return false;
}

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  MobileScannerController? _ctl;
  bool _processing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (_isSimulatorOrDesktop) {
      setState(() => _error = '桌面版 / 模擬器不支援相機掃碼，\n請使用搜尋欄手動輸入條碼或使用條碼槍。');
      return;
    }
    try {
      _ctl = MobileScannerController();
      await _ctl!.start();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = '無法啟動相機：$e');
    }
  }

  @override
  void dispose() {
    _ctl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('掃描條碼'),
        actions: _ctl == null
            ? null
            : [
                IconButton(
                    icon: const Icon(Icons.flash_on_outlined),
                    onPressed: () => _ctl!.toggleTorch()),
                IconButton(
                    icon: const Icon(Icons.cameraswitch_outlined),
                    onPressed: () => _ctl!.switchCamera()),
              ],
      ),
      body: _error != null
          ? Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.no_photography_outlined,
                              size: 72, color: Theme.of(context).colorScheme.outline),
                          const SizedBox(height: 16),
                          Text(_error!, textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('返回'),
                            onPressed: () => context.pop(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (BookSaleDemo.enabled) const _BookDemoScanPanel(),
              ],
            )
          : _ctl == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _ctl!,
                      onDetect: _onDetect,
                    ),
                    if (BookSaleDemo.enabled) const _BookDemoScanPanel(),
                  ],
                ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;
    _processing = true;
    final err = await ref.read(cartControllerProvider.notifier).scanBarcode(code);
    if (!mounted) return;
    if (err == null) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      Future.delayed(const Duration(seconds: 1), () => _processing = false);
    }
  }
}

class _BookDemoScanPanel extends ConsumerWidget {
  const _BookDemoScanPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final booksAsync = ref.watch(bookSaleDemoBooksProvider);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        elevation: 8,
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: booksAsync.when(
              loading: () => Row(
                children: [
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 12),
                  Text('載入 TAAZE 書目…', style: theme.textTheme.labelLarge),
                ],
              ),
              error: (_, __) => Text('書目載入失敗', style: theme.textTheme.labelLarge),
              data: (books) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('TAAZE 最新書 · 點擊模擬掃碼', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: books.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final book = books[i];
                        return ActionChip(
                          avatar: const Icon(Icons.menu_book, size: 18),
                          label: Text(book.title, overflow: TextOverflow.ellipsis),
                          onPressed: () async {
                            final err = await ref
                                .read(cartControllerProvider.notifier)
                                .scanBarcode(book.barcode);
                            if (!context.mounted) return;
                            if (err == null) {
                              context.pop();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(err)),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
