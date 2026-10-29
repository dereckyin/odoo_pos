import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

bool get _isSimulatorOrDesktop {
  if (kIsWeb) return false;
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) return true;
  return false;
}

/// Full-screen camera scanner. Pops with the scanned barcode string.
/// Used by App 收款 / 寄賣入庫 — prefer QR for payment codes.
class BarcodeScanPage extends StatefulWidget {
  const BarcodeScanPage({super.key});

  @override
  State<BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<BarcodeScanPage> {
  MobileScannerController? _ctl;
  bool _processing = false;
  String? _error;
  int _emptyHits = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<bool> _ensureCameraPermission() async {
    if (_isSimulatorOrDesktop) return false;
    var status = await Permission.camera.status;
    if (status.isGranted) return true;
    status = await Permission.camera.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied || status.isRestricted) {
      if (mounted) {
        setState(
          () => _error = '未授權相機權限。\n請至系統設定開啟相機後再試。',
        );
      }
      return false;
    }
    if (mounted) {
      setState(() => _error = '需要相機權限才能掃碼。');
    }
    return false;
  }

  Future<void> _initCamera() async {
    if (_isSimulatorOrDesktop) {
      setState(() => _error = '桌面版不支援相機掃碼，\n請使用條碼槍或手動輸入條碼。');
      return;
    }
    final ok = await _ensureCameraPermission();
    if (!ok) return;
    try {
      // App 付款碼為 QR；同時開常見一維碼以免誤掃其他條碼時完全無回饋。
      _ctl = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        formats: const [
          BarcodeFormat.qrCode,
          BarcodeFormat.code128,
          BarcodeFormat.code39,
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
        ],
      );
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
    if (code == null || code.isEmpty) {
      _emptyHits++;
      if (_emptyHits == 8 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已對準但讀不到內容，請掃顧客 App 的付款 QR（或手打 6 碼）'),
            duration: Duration(seconds: 3),
          ),
        );
        _emptyHits = 0;
      }
      return;
    }
    _processing = true;
    context.pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('掃描付款 QR'),
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
                      icon: const Icon(Icons.settings),
                      label: const Text('開啟系統設定'),
                      onPressed: () => openAppSettings(),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('重試'),
                      onPressed: () {
                        setState(() => _error = null);
                        _initCamera();
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
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
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(controller: _ctl!, onDetect: _onDetect),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        color: Colors.black54,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                        child: const Text(
                          '請對準顧客 App「櫃台付款」畫面的 QR Code\n（物流條碼／書背條碼無法收款）',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
