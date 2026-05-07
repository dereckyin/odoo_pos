import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../../core/providers.dart';

class TerminalRegisterPage extends ConsumerStatefulWidget {
  const TerminalRegisterPage({super.key});

  @override
  ConsumerState<TerminalRegisterPage> createState() => _TerminalRegisterPageState();
}

class _TerminalRegisterPageState extends ConsumerState<TerminalRegisterPage> {
  final _store = TextEditingController(text: 'S001');
  final _terminal = TextEditingController(text: 'T01');
  bool _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('終端機註冊')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('將此裝置註冊為店面收銀機', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(controller: _store, decoration: const InputDecoration(labelText: '店別代號')),
                const SizedBox(height: 12),
                TextField(controller: _terminal, decoration: const InputDecoration(labelText: '終端機代號')),
                const SizedBox(height: 16),
                if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 16),
                BigButton(
                  icon: Icons.app_registration,
                  label: _busy ? '註冊中…' : '註冊',
                  onPressed: _busy ? null : _register,
                ),
              ],
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
    });
    try {
      final api = ref.read(posApiProvider);
      final res = await api.registerTerminal(_store.text.trim(), _terminal.text.trim());
      await ref.read(sessionStorageProvider).saveTerminalCreds(
            _store.text.trim(),
            _terminal.text.trim(),
            res['api_key'] as String,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
