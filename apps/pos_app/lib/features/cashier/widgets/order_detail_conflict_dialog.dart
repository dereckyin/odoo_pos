import 'package:flutter/material.dart';

/// When importing a table order or restoring a held cart while the order
/// detail panel already has lines.
enum OrderDetailConflictAction { cancel, parkAndContinue, replace }

Future<OrderDetailConflictAction?> showOrderDetailConflictDialog(
  BuildContext context, {
  required String title,
  required String message,
  bool showParkOption = true,
  String parkLabel = '掛單保留並繼續',
  String replaceLabel = '覆蓋並繼續',
}) {
  return showDialog<OrderDetailConflictAction>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, OrderDetailConflictAction.cancel),
          child: const Text('取消'),
        ),
        if (showParkOption)
          TextButton(
            onPressed: () => Navigator.pop(context, OrderDetailConflictAction.parkAndContinue),
            child: Text(parkLabel),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(context, OrderDetailConflictAction.replace),
          child: Text(replaceLabel),
        ),
      ],
    ),
  );
}
