enum PrinterKind { escpos, tspl }

enum PrinterConnectionType { network, bluetooth }

class PrinterPreferences {
  PrinterPreferences({
    this.host = '192.168.1.100',
    this.port = 9100,
    this.paperWidth = 80,
    this.enabled = false,
    this.kind = PrinterKind.escpos,
    this.labelWidthMm = 40,
    this.labelHeightMm = 30,
    this.gapMm = 2.0,
    this.connectionType = PrinterConnectionType.network,
    this.bluetoothAddress,
    this.bluetoothName,
    this.bluetoothIsBle = false,
  });

  final String host;
  final int port;
  final int paperWidth;
  final bool enabled;
  final PrinterKind kind;
  final int labelWidthMm;
  final int labelHeightMm;
  final double gapMm;
  final PrinterConnectionType connectionType;
  final String? bluetoothAddress;
  final String? bluetoothName;

  /// iOS / BLE printers only; classic SPP thermal printers use `false` on Android.
  final bool bluetoothIsBle;

  bool get usesBluetooth => connectionType == PrinterConnectionType.bluetooth;

  bool get hasEndpoint {
    if (usesBluetooth) {
      return bluetoothAddress?.trim().isNotEmpty ?? false;
    }
    return host.trim().isNotEmpty;
  }

  Map<String, dynamic> toJson() => {
        'host': host,
        'port': port,
        'paperWidth': paperWidth,
        'enabled': enabled,
        'kind': kind.name,
        'labelWidthMm': labelWidthMm,
        'labelHeightMm': labelHeightMm,
        'gapMm': gapMm,
        'connectionType': connectionType.name,
        'bluetoothAddress': bluetoothAddress,
        'bluetoothName': bluetoothName,
        'bluetoothIsBle': bluetoothIsBle,
      };

  factory PrinterPreferences.fromJson(Map<String, dynamic> j) => PrinterPreferences(
        host: j['host'] as String? ?? '192.168.1.100',
        port: (j['port'] as num?)?.toInt() ?? 9100,
        paperWidth: (j['paperWidth'] as num?)?.toInt() ?? 80,
        enabled: j['enabled'] as bool? ?? false,
        kind: PrinterKind.values.byName(j['kind'] as String? ?? 'escpos'),
        labelWidthMm: (j['labelWidthMm'] as num?)?.toInt() ?? 40,
        labelHeightMm: (j['labelHeightMm'] as num?)?.toInt() ?? 30,
        gapMm: (j['gapMm'] as num?)?.toDouble() ?? 2.0,
        connectionType: PrinterConnectionType.values.byName(
          j['connectionType'] as String? ?? 'network',
        ),
        bluetoothAddress: j['bluetoothAddress'] as String?,
        bluetoothName: j['bluetoothName'] as String?,
        bluetoothIsBle: j['bluetoothIsBle'] as bool? ?? false,
      );

  PrinterPreferences copyWith({
    String? host,
    int? port,
    int? paperWidth,
    bool? enabled,
    PrinterKind? kind,
    int? labelWidthMm,
    int? labelHeightMm,
    double? gapMm,
    PrinterConnectionType? connectionType,
    String? bluetoothAddress,
    String? bluetoothName,
    bool? bluetoothIsBle,
    bool clearBluetooth = false,
  }) =>
      PrinterPreferences(
        host: host ?? this.host,
        port: port ?? this.port,
        paperWidth: paperWidth ?? this.paperWidth,
        enabled: enabled ?? this.enabled,
        kind: kind ?? this.kind,
        labelWidthMm: labelWidthMm ?? this.labelWidthMm,
        labelHeightMm: labelHeightMm ?? this.labelHeightMm,
        gapMm: gapMm ?? this.gapMm,
        connectionType: connectionType ?? this.connectionType,
        bluetoothAddress: clearBluetooth ? null : (bluetoothAddress ?? this.bluetoothAddress),
        bluetoothName: clearBluetooth ? null : (bluetoothName ?? this.bluetoothName),
        bluetoothIsBle: bluetoothIsBle ?? this.bluetoothIsBle,
      );
}
