/// Operation kinds enqueued for outbound sync.
enum SyncOpKind {
  uploadOrder,
  uploadRefund,
  uploadInventoryMovement,
  issueInvoice,
  voidInvoice,
  capturePayment,
  refundPayment,
  upsertMember,
  recordPoints,
}

extension SyncOpKindCode on SyncOpKind {
  String get code => name;
  static SyncOpKind fromCode(String c) =>
      SyncOpKind.values.firstWhere((k) => k.name == c, orElse: () => SyncOpKind.uploadOrder);
}

class RetryPolicy {
  static Duration nextBackoff(int retries) {
    const seconds = [1, 5, 30, 5 * 60, 30 * 60, 60 * 60];
    final i = retries.clamp(0, seconds.length - 1);
    return Duration(seconds: seconds[i]);
  }

  static const maxRetriesBeforeAlert = 6;
}
