import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_domain/pos_domain.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../../core/providers.dart';
import '../../../core/user_facing_error.dart';
import 'terminal_register_page.dart';

/// Tenant-aware POS login.
///
/// Most fields are pre-populated from the locally-stored ``TerminalCreds``
/// (which the operator filled in once during registration). The cashier
/// only needs to type their username and password each shift.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _tenant = TextEditingController();
  final _store = TextEditingController();
  final _terminal = TextEditingController();
  String _apiKey = '';
  final _user = TextEditingController(text: 'cashier');
  final _pass = TextEditingController();
  final _empId = TextEditingController();
  final _pin = TextEditingController();
  bool _busy = false;
  bool _terminalReady = false;
  bool _pinMode = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final creds = await ref.read(sessionStorageProvider).loadTerminalCreds();
      if (creds != null && mounted) {
        _tenant.text = (creds['tenantCode'] as String?) ?? '';
        _store.text = (creds['storeCode'] as String?) ?? '';
        _terminal.text = (creds['terminalCode'] as String?) ?? '';
        _apiKey = (creds['apiKey'] as String?) ?? '';
        setState(() => _terminalReady = _apiKey.isNotEmpty);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.point_of_sale, size: 72, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Center(
                      child: Text('點餐趣',
                          style: Theme.of(context).textTheme.headlineMedium)),
                  const SizedBox(height: 8),
                  if (!_terminalReady)
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          '此裝置尚未註冊，請先點擊下方「終端機註冊」並由店家管理員完成設定。',
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tenant,
                    enabled: !_terminalReady,
                    decoration: const InputDecoration(labelText: '租戶代號 (tenant_code)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _store,
                    enabled: !_terminalReady,
                    decoration: const InputDecoration(labelText: '店別代號 (store_code)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _terminal,
                    enabled: !_terminalReady,
                    decoration: const InputDecoration(labelText: '終端機代號'),
                  ),
                  const Divider(height: 28),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('帳號密碼'), icon: Icon(Icons.password)),
                      ButtonSegment(value: true, label: Text('員工 PIN'), icon: Icon(Icons.pin)),
                    ],
                    selected: {_pinMode},
                    onSelectionChanged: (s) => setState(() {
                      _pinMode = s.first;
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: 16),
                  if (!_pinMode) ...[
                    TextField(controller: _user, decoration: const InputDecoration(labelText: '帳號')),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pass,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: '密碼'),
                    ),
                  ] else ...[
                    TextField(
                      controller: _empId,
                      decoration: const InputDecoration(labelText: '員工 ID'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pin,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'PIN（4-12 位數字）'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_error != null)
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  BigButton(
                    icon: Icons.login,
                    label: _busy ? '登入中…' : '登入',
                    onPressed: (_busy || !_terminalReady) ? null : (_pinMode ? _pinLogin : _login),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    icon: const Icon(Icons.app_registration),
                    label: const Text('終端機註冊 / 重新註冊'),
                    onPressed: () async {
                      final ok = await Navigator.push<bool?>(
                        context,
                        MaterialPageRoute(builder: (_) => const TerminalRegisterPage()),
                      );
                      if (ok == true) {
                        final creds =
                            await ref.read(sessionStorageProvider).loadTerminalCreds();
                        if (creds != null && mounted) {
                          _tenant.text = (creds['tenantCode'] as String?) ?? '';
                          _store.text = (creds['storeCode'] as String?) ?? '';
                          _terminal.text = (creds['terminalCode'] as String?) ?? '';
                          _apiKey = (creds['apiKey'] as String?) ?? '';
                          setState(() => _terminalReady = _apiKey.isNotEmpty);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ref.read(posApiProvider);
      final dto = await api.login(
        tenantCode: _tenant.text.trim(),
        storeCode: _store.text.trim(),
        terminalCode: _terminal.text.trim(),
        terminalApiKey: _apiKey,
        username: _user.text.trim(),
        password: _pass.text,
      );
      await ref.read(authStateProvider.notifier).setSession(Session(
            userId: dto.userId,
            username: dto.username,
            displayName: dto.displayName,
            role: dto.role,
            tenantId: dto.tenantId,
            tenantCode: dto.tenantCode,
            storeId: dto.storeId,
            terminalId: dto.terminalId,
            accessToken: dto.accessToken,
            refreshToken: dto.refreshToken,
            expiresAt: dto.expiresAt,
          ));
    } catch (e) {
      setState(() => _error = formatUserFacingError(e, scene: UserErrorScene.login));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pinLogin() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ref.read(posApiProvider);
      final dto = await api.pinLogin(
        tenantCode: _tenant.text.trim(),
        storeCode: _store.text.trim(),
        terminalCode: _terminal.text.trim(),
        terminalApiKey: _apiKey,
        employeeId: _empId.text.trim(),
        pin: _pin.text.trim(),
      );
      await ref.read(authStateProvider.notifier).setSession(Session(
            userId: dto.userId,
            username: dto.username,
            displayName: dto.displayName,
            role: dto.role,
            tenantId: dto.tenantId,
            tenantCode: dto.tenantCode,
            storeId: dto.storeId,
            terminalId: dto.terminalId,
            accessToken: dto.accessToken,
            refreshToken: dto.refreshToken,
            expiresAt: dto.expiresAt,
          ));
    } catch (e) {
      setState(() => _error = formatUserFacingError(e, scene: UserErrorScene.login));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
