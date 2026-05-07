import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_domain/pos_domain.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../../core/providers.dart';
import 'terminal_register_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _user = TextEditingController(text: 'admin');
  final _pass = TextEditingController(text: 'admin123');
  final _terminal = TextEditingController(text: 'T01');
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final creds = await ref.read(sessionStorageProvider).loadTerminalCreds();
      if (creds != null && mounted) {
        _terminal.text = creds['terminalCode'] as String;
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
                    child: Text('企業 POS 系統',
                        style: Theme.of(context).textTheme.headlineMedium)),
                const SizedBox(height: 32),
                TextField(controller: _user, decoration: const InputDecoration(labelText: '帳號')),
                const SizedBox(height: 12),
                TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: '密碼')),
                const SizedBox(height: 12),
                TextField(controller: _terminal, decoration: const InputDecoration(labelText: '終端機代號')),
                const SizedBox(height: 16),
                if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 16),
                BigButton(
                  icon: Icons.login,
                  label: _busy ? '登入中…' : '登入',
                  onPressed: _busy ? null : _login,
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(Icons.app_registration),
                  label: const Text('終端機註冊'),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TerminalRegisterPage()),
                    );
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
      final dto = await api.login(_user.text.trim(), _pass.text, _terminal.text.trim());
      await ref.read(authStateProvider.notifier).setSession(Session(
            userId: dto.userId,
            username: dto.username,
            displayName: dto.displayName,
            role: dto.role,
            storeId: dto.storeId,
            terminalId: dto.terminalId,
            accessToken: dto.accessToken,
            refreshToken: dto.refreshToken,
            expiresAt: dto.expiresAt,
          ));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
