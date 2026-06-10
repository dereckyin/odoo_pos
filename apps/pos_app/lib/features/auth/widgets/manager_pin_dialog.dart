import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/roles.dart';
import '../../../core/user_facing_error.dart';

/// Prompt for a store-manager-or-above PIN to authorise a sensitive action
/// (refund / void / discount) started by a cashier.
///
/// Returns the approver info map on success, or null if cancelled/failed.
/// When the current session is already a store-admin role we short-circuit and
/// return a synthetic approval without prompting.
Future<Map<String, dynamic>?> requestManagerApproval(
  BuildContext context,
  WidgetRef ref, {
  required String action,
  String? title,
}) async {
  final session = ref.read(authStateProvider).session;
  if (session != null && isStoreAdminRole(session.role)) {
    return {
      'approved': true,
      'approver_id': session.userId,
      'approver_name': session.displayName,
      'approver_role': session.role,
      'self': true,
    };
  }

  return showDialog<Map<String, dynamic>?>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _ManagerPinDialog(action: action, title: title),
  );
}

class _ManagerPinDialog extends ConsumerStatefulWidget {
  const _ManagerPinDialog({required this.action, this.title});
  final String action;
  final String? title;

  @override
  ConsumerState<_ManagerPinDialog> createState() => _ManagerPinDialogState();
}

class _ManagerPinDialogState extends ConsumerState<_ManagerPinDialog> {
  final _empId = TextEditingController();
  final _pin = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _empId.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ref.read(posApiProvider);
      final res = await api.pinVerify(
        employeeId: _empId.text.trim(),
        pin: _pin.text.trim(),
        action: widget.action,
      );
      if (mounted) Navigator.of(context).pop(res);
    } catch (e) {
      setState(() => _error = formatUserFacingError(e, scene: UserErrorScene.general));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title ?? '店長授權'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('此操作需店長（或以上）以員工 ID + PIN 核可。'),
          const SizedBox(height: 12),
          TextField(
            controller: _empId,
            decoration: const InputDecoration(labelText: '店長員工 ID'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'PIN'),
            onSubmitted: (_) => _busy ? null : _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(null),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? '驗證中…' : '核可'),
        ),
      ],
    );
  }
}
