import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

bool get _isSimulatorOrDesktop {
  if (kIsWeb) return false;
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) return true;
  return false;
}

/// Full-screen camera scanner. Pops with the scanned barcode string.
class BarcodeScanPage extends StatefulWidget {
  const BarcodeScanPage({super.key});

  @override
  State<BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<BarcodeScanPage> {
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
      setState(() => _error = '桌面版不支援相機掃碼，\n請使用條碼槍或手動輸入條碼。');
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

  void _onDetect(BarcodeCapture capture) {
    if (_processing) return;
    final code = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (code == null || code.isEmpty) return;
    _processing = true;
    context.pop(code);
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
                  onPressed: () => _ctl!.toggleTorch(),
                ),
                IconButton(
                  icon: const Icon(Icons.cameraswitch_outlined),
                  onPressed: () => _ctl!.switchCamera(),
                ),
              ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.no_photography_outlined,
                      size: 72,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
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
              : MobileScanner(controller: _ctl!, onDetect: _onDetect),
    );
  }
}
