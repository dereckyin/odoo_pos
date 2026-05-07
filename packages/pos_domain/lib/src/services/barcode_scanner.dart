class BarcodeEvent {
  const BarcodeEvent({required this.code, required this.format, required this.timestamp});
  final String code;
  final String format;
  final DateTime timestamp;
}

abstract interface class BarcodeScanner {
  Stream<BarcodeEvent> get scans;
  Future<void> start();
  Future<void> stop();
}
