import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../../core/providers.dart';
import '../../../data/sync/sync_providers.dart';

/// Two-step registration flow:
///   1. Operator authenticates with their tenant_admin / store_manager
///      browser-style account → we get a short-lived admin JWT.
///   2. Operator names the terminal → backend issues a one-shot api_key
///      that we persist locally and use on every subsequent /auth/login.
class TerminalRegisterPage extends ConsumerStatefulWidget {
  const TerminalRegisterPage({super.key});

  @override
  ConsumerState<TerminalRegisterPage> createState() => _TerminalRegisterPageState();
}

class _TerminalRegisterPageState extends ConsumerState<TerminalRegisterPage> {
  final _tenant = TextEditingController(text: 'demo');
  final _adminUser = TextEditingController(text: 'admin');
  final _adminPass = TextEditingController(text: 'admin123');
  final _store = TextEditingController(text: 'S001');
  final _terminal = TextEditingController(text: 'T01');
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('終端機註冊')),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('將此裝置註冊為店面收銀機',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text('需店家管理員 (tenant_admin / store_manager) 身份才能註冊。',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  TextField(controller: _tenant, decoration: const InputDecoration(labelText: '租戶代號 (tenant_code)')),
                  const SizedBox(height: 12),
                  TextField(controller: _adminUser, decoration: const InputDecoration(labelText: '管理員帳號')),
                  const SizedBox(height: 12),
                  TextField(controller: _adminPass, obscureText: true, decoration: const InputDecoration(labelText: '管理員密碼')),
                  const Divider(height: 32),
                  TextField(controller: _store, decoration: const InputDecoration(labelText: '店別代號 (store_code)')),
                  const SizedBox(height: 12),
                  TextField(controller: _terminal, decoration: const InputDecoration(labelText: '終端機代號')),
                  const SizedBox(height: 16),
                  if (_info != null) Text(_info!, style: const TextStyle(color: Colors.green)),
                  if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 16),
                  BigButton(
                    icon: Icons.app_registration,
                    label: _busy ? '註冊中…' : '取得 API Key 並儲存',
                    onPressed: _busy ? null : _register,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      final api = ref.read(posApiProvider);
      final adminSession = await api.adminLogin(
        tenantCode: _tenant.text.trim(),
        username: _adminUser.text.trim(),
        password: _adminPass.text,
      );
      final res = await api.registerTerminal(
        storeCode: _store.text.trim(),
        terminalCode: _terminal.text.trim(),
        adminToken: adminSession.accessToken,
      );
      final tenantCode = _tenant.text.trim();
      final storeCode = _store.text.trim();
      final terminalCode = _terminal.text.trim();
      final previous = await ref.read(sessionStorageProvider).loadTerminalCreds();
      final identityChanged = previous == null ||
          previous['tenantCode'] != tenantCode ||
          previous['storeCode'] != storeCode ||
          previous['terminalCode'] != terminalCode;
      if (identityChanged) {
        await ref.read(databaseProvider).clearMasterData();
        await ref.read(masterDataScopeStoreProvider).clearScope();
      }
      await ref.read(sessionStorageProvider).saveTerminalCreds(
            tenantCode: tenantCode,
            storeCode: storeCode,
            terminalCode: terminalCode,
            apiKey: res['api_key'] as String,
          );
      setState(() {
        _info = '註冊完成，可回到登入頁開始使用。';
      });
      if (!mounted) return;
      // Give the user a beat to see the success message before popping.
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
