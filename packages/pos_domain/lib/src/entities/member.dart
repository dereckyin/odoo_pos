class MemberLevel {
  const MemberLevel({
    required this.id,
    required this.name,
    required this.discountRate,
    this.minSpend = 0,
    this.minPoints = 0,
    this.color,
  });

  final String id;
  final String name;

  /// 0..1; 0.95 = 95 折
  final double discountRate;
  final num minSpend;
  final int minPoints;
  final String? color;
}

class Member {
  const Member({
    required this.id,
    required this.phone,
    required this.name,
    this.email,
    this.birthday,
    this.points = 0,
    this.totalSpentMajor = 0,
    this.level,
    this.qrCode,
    this.joinedAt,
    this.lastVisitAt,
    this.note,
  });

  final String id;
  final String phone;
  final String name;
  final String? email;
  final DateTime? birthday;
  final int points;
  final num totalSpentMajor;
  final MemberLevel? level;
  final String? qrCode;
  final DateTime? joinedAt;
  final DateTime? lastVisitAt;
  final String? note;

  Member copyWith({int? points, num? totalSpentMajor, MemberLevel? level, DateTime? lastVisitAt}) =>
      Member(
        id: id,
        phone: phone,
        name: name,
        email: email,
        birthday: birthday,
        points: points ?? this.points,
        totalSpentMajor: totalSpentMajor ?? this.totalSpentMajor,
        level: level ?? this.level,
        qrCode: qrCode,
        joinedAt: joinedAt,
        lastVisitAt: lastVisitAt ?? this.lastVisitAt,
        note: note,
      );
}

class PointTransaction {
  const PointTransaction({
    required this.id,
    required this.memberId,
    required this.delta,
    required this.reason,
    required this.createdAt,
    this.orderId,
    this.expiresAt,
  });

  final String id;
  final String memberId;
  final int delta;
  final String reason;
  final DateTime createdAt;
  final String? orderId;
  final DateTime? expiresAt;
}
