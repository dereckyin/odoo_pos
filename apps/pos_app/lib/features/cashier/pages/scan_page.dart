import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
          ? Center(
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
            )
          : _ctl == null
              ? const Center(child: CircularProgressIndicator())
              : MobileScanner(
                  controller: _ctl!,
                  onDetect: _onDetect,
                ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;
    _processing = true;
    final ok = await ref.read(cartControllerProvider.notifier).scanBarcode(code);
    if (!mounted) return;
    if (ok) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('找不到: $code')));
      Future.delayed(const Duration(seconds: 1), () => _processing = false);
    }
  }
}
