class Store {
  const Store({
    required this.id,
    required this.code,
    required this.name,
    this.taxId,
    this.address,
    this.phone,
  });

  final String id;
  final String code;
  final String name;
  final String? taxId;
  final String? address;
  final String? phone;
}

class Terminal {
  const Terminal({
    required this.id,
    required this.storeId,
    required this.code,
    this.lastSeenAt,
  });

  final String id;
  final String storeId;
  final String code;
  final DateTime? lastSeenAt;
}
