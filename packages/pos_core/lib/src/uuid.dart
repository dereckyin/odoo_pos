import 'package:uuid/uuid.dart';

/// Single Uuid v7 generator used across the app for offline-safe primary keys.
///
/// v7 is monotonic time-ordered which is friendlier for B-tree indexes than v4.
final _uuid = const Uuid();

String newUuid() => _uuid.v7();

/// For tests / deterministic seeds.
String namedUuid(String namespace, String name) =>
    _uuid.v5(Namespace.url.value, '$namespace:$name');
