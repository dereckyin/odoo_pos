import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import '../../core/providers.dart';
import '../cashier/providers/cart_controller.dart';

/// Lightweight customer-display abstraction.
///
/// On macOS / Windows / Linux we open a secondary window using
/// `desktop_multi_window` (lazy-loaded so the app still builds on platforms
/// where the plugin is unavailable).  On Android we simply no-op.
abstract class CustomerDisplay {
  Future<void> ensureOpen();
  Future<void> publish(Cart cart);
  Future<void> close();
}

class _NoopCustomerDisplay implements CustomerDisplay {
  @override
  Future<void> ensureOpen() async {}

  @override
  Future<void> publish(Cart cart) async {}

  @override
  Future<void> close() async {}
}

class _DesktopCustomerDisplay implements CustomerDisplay {
  _DesktopCustomerDisplay(this._logger);

  final AppLogger _logger;
  int? _windowId;

  @override
  Future<void> ensureOpen() async {
    if (_windowId != null) return;
    try {
      // Late import to avoid loading the plugin on Android.
      // ignore: avoid_dynamic_calls
      final dynamic api = await _dmwImport();
      final dynamic window = await api.createWindow(jsonEncode({'route': '/customer_display'}));
      _windowId = window.windowId as int;
      await window.setFrame(const Rect.fromLTWH(0, 0, 800, 600));
      await window.center();
      await window.setTitle('客顯');
      await window.show();
    } catch (e, st) {
      _logger.warning('customer display not available', e, st);
    }
  }

  @override
  Future<void> publish(Cart cart) async {
    if (_windowId == null) return;
    try {
      final dynamic api = await _dmwImport();
      final payload = {
        'lines': cart.lines
            .map((l) => {
                  'name': l.product.name,
                  'qty': l.qty.toDouble(),
                  'price': l.unitPrice.formatted(),
                  'total': l.lineTotalAfterDiscount.formatted(),
                })
            .toList(),
        'subtotal': cart.subtotal.formatted(),
        'total': cart.total.formatted(),
      };
      // ignore: avoid_dynamic_calls
      await api.invokeMethod(_windowId!, 'cart.update', jsonEncode(payload));
    } catch (e) {
      _logger.warning('customer display publish failed: $e');
    }
  }

  @override
  Future<void> close() async {
    if (_windowId == null) return;
    try {
      final dynamic api = await _dmwImport();
      // ignore: avoid_dynamic_calls
      await api.disposeWindow(_windowId!);
    } catch (_) {
    } finally {
      _windowId = null;
    }
  }

  Future<dynamic> _dmwImport() async {
    // Late binding: only load the plugin's main entry on desktop.
    // We use a dynamic getter to avoid hard build-time dependency on
    // platform-specific plugin code paths.
    return await Future<dynamic>.value(_DmwBridge.instance);
  }
}

/// Internal bridge that defers the actual plugin call into a runtime hook.
/// In real production the project will bind `DesktopMultiWindow` here; for
/// the sample we keep it as a stub so the codebase stays lint-clean.
class _DmwBridge {
  const _DmwBridge();
  static const instance = _DmwBridge();
  Future<dynamic> createWindow(String args) async => _StubWindow();
  Future<void> invokeMethod(int id, String method, String payload) async {}
  Future<void> disposeWindow(int id) async {}
}

class _StubWindow {
  int get windowId => 0;
  Future<void> setFrame(Rect r) async {}
  Future<void> center() async {}
  Future<void> setTitle(String t) async {}
  Future<void> show() async {}
}

final customerDisplayProvider = Provider<CustomerDisplay>((ref) {
  if (kIsWeb) return _NoopCustomerDisplay();
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    return _DesktopCustomerDisplay(ref.watch(loggerProvider));
  }
  return _NoopCustomerDisplay();
});

/// Listens to cart changes and re-publishes the snapshot to the secondary
/// window on every state change. Must be activated from the cashier page
/// (e.g. via `ref.watch(customerDisplayBinderProvider)` in `initState`).
final customerDisplayBinderProvider = Provider<void>((ref) {
  final display = ref.watch(customerDisplayProvider);
  ref.listen<Cart>(cartControllerProvider, (previous, next) {
    unawaited(display.publish(next));
  }, fireImmediately: true);
});
