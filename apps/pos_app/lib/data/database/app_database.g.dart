// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $StoresTable extends Stores with TableInfo<$StoresTable, StoreRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _taxIdMeta = const VerificationMeta('taxId');
  @override
  late final GeneratedColumn<String> taxId = GeneratedColumn<String>(
      'tax_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, code, name, taxId, address, phone, updatedAt, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stores';
  @override
  VerificationContext validateIntegrity(Insertable<StoreRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('tax_id')) {
      context.handle(
          _taxIdMeta, taxId.isAcceptableOrUnknown(data['tax_id']!, _taxIdMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoreRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoreRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      taxId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tax_id']),
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $StoresTable createAlias(String alias) {
    return $StoresTable(attachedDatabase, alias);
  }
}

class StoreRow extends DataClass implements Insertable<StoreRow> {
  final String id;
  final String code;
  final String name;
  final String? taxId;
  final String? address;
  final String? phone;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const StoreRow(
      {required this.id,
      required this.code,
      required this.name,
      this.taxId,
      this.address,
      this.phone,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || taxId != null) {
      map['tax_id'] = Variable<String>(taxId);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  StoresCompanion toCompanion(bool nullToAbsent) {
    return StoresCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      taxId:
          taxId == null && nullToAbsent ? const Value.absent() : Value(taxId),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory StoreRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoreRow(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      taxId: serializer.fromJson<String?>(json['taxId']),
      address: serializer.fromJson<String?>(json['address']),
      phone: serializer.fromJson<String?>(json['phone']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'taxId': serializer.toJson<String?>(taxId),
      'address': serializer.toJson<String?>(address),
      'phone': serializer.toJson<String?>(phone),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  StoreRow copyWith(
          {String? id,
          String? code,
          String? name,
          Value<String?> taxId = const Value.absent(),
          Value<String?> address = const Value.absent(),
          Value<String?> phone = const Value.absent(),
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      StoreRow(
        id: id ?? this.id,
        code: code ?? this.code,
        name: name ?? this.name,
        taxId: taxId.present ? taxId.value : this.taxId,
        address: address.present ? address.value : this.address,
        phone: phone.present ? phone.value : this.phone,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  StoreRow copyWithCompanion(StoresCompanion data) {
    return StoreRow(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      taxId: data.taxId.present ? data.taxId.value : this.taxId,
      address: data.address.present ? data.address.value : this.address,
      phone: data.phone.present ? data.phone.value : this.phone,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoreRow(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('taxId: $taxId, ')
          ..write('address: $address, ')
          ..write('phone: $phone, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, code, name, taxId, address, phone, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoreRow &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.taxId == this.taxId &&
          other.address == this.address &&
          other.phone == this.phone &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class StoresCompanion extends UpdateCompanion<StoreRow> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> name;
  final Value<String?> taxId;
  final Value<String?> address;
  final Value<String?> phone;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const StoresCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.taxId = const Value.absent(),
    this.address = const Value.absent(),
    this.phone = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoresCompanion.insert({
    required String id,
    required String code,
    required String name,
    this.taxId = const Value.absent(),
    this.address = const Value.absent(),
    this.phone = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        code = Value(code),
        name = Value(name),
        updatedAt = Value(updatedAt);
  static Insertable<StoreRow> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? taxId,
    Expression<String>? address,
    Expression<String>? phone,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (taxId != null) 'tax_id': taxId,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoresCompanion copyWith(
      {Value<String>? id,
      Value<String>? code,
      Value<String>? name,
      Value<String?>? taxId,
      Value<String?>? address,
      Value<String?>? phone,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return StoresCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      taxId: taxId ?? this.taxId,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (taxId.present) {
      map['tax_id'] = Variable<String>(taxId.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoresCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('taxId: $taxId, ')
          ..write('address: $address, ')
          ..write('phone: $phone, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TerminalsTable extends Terminals
    with TableInfo<$TerminalsTable, TerminalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TerminalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _storeIdMeta =
      const VerificationMeta('storeId');
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
      'store_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES stores (id)'));
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastSeenAtMeta =
      const VerificationMeta('lastSeenAt');
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
      'last_seen_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, storeId, code, lastSeenAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'terminals';
  @override
  VerificationContext validateIntegrity(Insertable<TerminalRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(_storeIdMeta,
          storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta));
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
          _lastSeenAtMeta,
          lastSeenAt.isAcceptableOrUnknown(
              data['last_seen_at']!, _lastSeenAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TerminalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TerminalRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      storeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}store_id'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      lastSeenAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_seen_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TerminalsTable createAlias(String alias) {
    return $TerminalsTable(attachedDatabase, alias);
  }
}

class TerminalRow extends DataClass implements Insertable<TerminalRow> {
  final String id;
  final String storeId;
  final String code;
  final DateTime? lastSeenAt;
  final DateTime updatedAt;
  const TerminalRow(
      {required this.id,
      required this.storeId,
      required this.code,
      this.lastSeenAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['store_id'] = Variable<String>(storeId);
    map['code'] = Variable<String>(code);
    if (!nullToAbsent || lastSeenAt != null) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TerminalsCompanion toCompanion(bool nullToAbsent) {
    return TerminalsCompanion(
      id: Value(id),
      storeId: Value(storeId),
      code: Value(code),
      lastSeenAt: lastSeenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TerminalRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TerminalRow(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String>(json['storeId']),
      code: serializer.fromJson<String>(json['code']),
      lastSeenAt: serializer.fromJson<DateTime?>(json['lastSeenAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'storeId': serializer.toJson<String>(storeId),
      'code': serializer.toJson<String>(code),
      'lastSeenAt': serializer.toJson<DateTime?>(lastSeenAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TerminalRow copyWith(
          {String? id,
          String? storeId,
          String? code,
          Value<DateTime?> lastSeenAt = const Value.absent(),
          DateTime? updatedAt}) =>
      TerminalRow(
        id: id ?? this.id,
        storeId: storeId ?? this.storeId,
        code: code ?? this.code,
        lastSeenAt: lastSeenAt.present ? lastSeenAt.value : this.lastSeenAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  TerminalRow copyWithCompanion(TerminalsCompanion data) {
    return TerminalRow(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      code: data.code.present ? data.code.value : this.code,
      lastSeenAt:
          data.lastSeenAt.present ? data.lastSeenAt.value : this.lastSeenAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TerminalRow(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('code: $code, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, storeId, code, lastSeenAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TerminalRow &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.code == this.code &&
          other.lastSeenAt == this.lastSeenAt &&
          other.updatedAt == this.updatedAt);
}

class TerminalsCompanion extends UpdateCompanion<TerminalRow> {
  final Value<String> id;
  final Value<String> storeId;
  final Value<String> code;
  final Value<DateTime?> lastSeenAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TerminalsCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.code = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TerminalsCompanion.insert({
    required String id,
    required String storeId,
    required String code,
    this.lastSeenAt = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        storeId = Value(storeId),
        code = Value(code),
        updatedAt = Value(updatedAt);
  static Insertable<TerminalRow> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? code,
    Expression<DateTime>? lastSeenAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (code != null) 'code': code,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TerminalsCompanion copyWith(
      {Value<String>? id,
      Value<String>? storeId,
      Value<String>? code,
      Value<DateTime?>? lastSeenAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return TerminalsCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      code: code ?? this.code,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TerminalsCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('code: $code, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _hideFromPublicOrderingMeta =
      const VerificationMeta('hideFromPublicOrdering');
  @override
  late final GeneratedColumn<bool> hideFromPublicOrdering =
      GeneratedColumn<bool>('hide_from_public_ordering', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("hide_from_public_ordering" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _hideFromPosBrowseMeta =
      const VerificationMeta('hideFromPosBrowse');
  @override
  late final GeneratedColumn<bool> hideFromPosBrowse = GeneratedColumn<bool>(
      'hide_from_pos_browse', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("hide_from_pos_browse" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _memberDiscountEligibleMeta =
      const VerificationMeta('memberDiscountEligible');
  @override
  late final GeneratedColumn<bool> memberDiscountEligible =
      GeneratedColumn<bool>('member_discount_eligible', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("member_discount_eligible" IN (0, 1))'),
          defaultValue: const Constant(true));
  static const VerificationMeta _pointsEarnEligibleMeta =
      const VerificationMeta('pointsEarnEligible');
  @override
  late final GeneratedColumn<bool> pointsEarnEligible = GeneratedColumn<bool>(
      'points_earn_eligible', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("points_earn_eligible" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _pointsRedeemEligibleMeta =
      const VerificationMeta('pointsRedeemEligible');
  @override
  late final GeneratedColumn<bool> pointsRedeemEligible = GeneratedColumn<bool>(
      'points_redeem_eligible', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("points_redeem_eligible" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        parentId,
        sortOrder,
        color,
        icon,
        hideFromPublicOrdering,
        hideFromPosBrowse,
        memberDiscountEligible,
        pointsEarnEligible,
        pointsRedeemEligible,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<CategoryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('hide_from_public_ordering')) {
      context.handle(
          _hideFromPublicOrderingMeta,
          hideFromPublicOrdering.isAcceptableOrUnknown(
              data['hide_from_public_ordering']!, _hideFromPublicOrderingMeta));
    }
    if (data.containsKey('hide_from_pos_browse')) {
      context.handle(
          _hideFromPosBrowseMeta,
          hideFromPosBrowse.isAcceptableOrUnknown(
              data['hide_from_pos_browse']!, _hideFromPosBrowseMeta));
    }
    if (data.containsKey('member_discount_eligible')) {
      context.handle(
          _memberDiscountEligibleMeta,
          memberDiscountEligible.isAcceptableOrUnknown(
              data['member_discount_eligible']!, _memberDiscountEligibleMeta));
    }
    if (data.containsKey('points_earn_eligible')) {
      context.handle(
          _pointsEarnEligibleMeta,
          pointsEarnEligible.isAcceptableOrUnknown(
              data['points_earn_eligible']!, _pointsEarnEligibleMeta));
    }
    if (data.containsKey('points_redeem_eligible')) {
      context.handle(
          _pointsRedeemEligibleMeta,
          pointsRedeemEligible.isAcceptableOrUnknown(
              data['points_redeem_eligible']!, _pointsRedeemEligibleMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_id']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon']),
      hideFromPublicOrdering: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}hide_from_public_ordering'])!,
      hideFromPosBrowse: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}hide_from_pos_browse'])!,
      memberDiscountEligible: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}member_discount_eligible'])!,
      pointsEarnEligible: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}points_earn_eligible'])!,
      pointsRedeemEligible: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}points_redeem_eligible'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String name;
  final String? parentId;
  final int sortOrder;
  final String? color;
  final String? icon;
  final bool hideFromPublicOrdering;
  final bool hideFromPosBrowse;
  final bool memberDiscountEligible;
  final bool pointsEarnEligible;
  final bool pointsRedeemEligible;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const CategoryRow(
      {required this.id,
      required this.name,
      this.parentId,
      required this.sortOrder,
      this.color,
      this.icon,
      required this.hideFromPublicOrdering,
      required this.hideFromPosBrowse,
      required this.memberDiscountEligible,
      required this.pointsEarnEligible,
      required this.pointsRedeemEligible,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['hide_from_public_ordering'] = Variable<bool>(hideFromPublicOrdering);
    map['hide_from_pos_browse'] = Variable<bool>(hideFromPosBrowse);
    map['member_discount_eligible'] = Variable<bool>(memberDiscountEligible);
    map['points_earn_eligible'] = Variable<bool>(pointsEarnEligible);
    map['points_redeem_eligible'] = Variable<bool>(pointsRedeemEligible);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      sortOrder: Value(sortOrder),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      hideFromPublicOrdering: Value(hideFromPublicOrdering),
      hideFromPosBrowse: Value(hideFromPosBrowse),
      memberDiscountEligible: Value(memberDiscountEligible),
      pointsEarnEligible: Value(pointsEarnEligible),
      pointsRedeemEligible: Value(pointsRedeemEligible),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory CategoryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      color: serializer.fromJson<String?>(json['color']),
      icon: serializer.fromJson<String?>(json['icon']),
      hideFromPublicOrdering:
          serializer.fromJson<bool>(json['hideFromPublicOrdering']),
      hideFromPosBrowse: serializer.fromJson<bool>(json['hideFromPosBrowse']),
      memberDiscountEligible:
          serializer.fromJson<bool>(json['memberDiscountEligible']),
      pointsEarnEligible: serializer.fromJson<bool>(json['pointsEarnEligible']),
      pointsRedeemEligible:
          serializer.fromJson<bool>(json['pointsRedeemEligible']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<String?>(parentId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'color': serializer.toJson<String?>(color),
      'icon': serializer.toJson<String?>(icon),
      'hideFromPublicOrdering': serializer.toJson<bool>(hideFromPublicOrdering),
      'hideFromPosBrowse': serializer.toJson<bool>(hideFromPosBrowse),
      'memberDiscountEligible': serializer.toJson<bool>(memberDiscountEligible),
      'pointsEarnEligible': serializer.toJson<bool>(pointsEarnEligible),
      'pointsRedeemEligible': serializer.toJson<bool>(pointsRedeemEligible),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  CategoryRow copyWith(
          {String? id,
          String? name,
          Value<String?> parentId = const Value.absent(),
          int? sortOrder,
          Value<String?> color = const Value.absent(),
          Value<String?> icon = const Value.absent(),
          bool? hideFromPublicOrdering,
          bool? hideFromPosBrowse,
          bool? memberDiscountEligible,
          bool? pointsEarnEligible,
          bool? pointsRedeemEligible,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      CategoryRow(
        id: id ?? this.id,
        name: name ?? this.name,
        parentId: parentId.present ? parentId.value : this.parentId,
        sortOrder: sortOrder ?? this.sortOrder,
        color: color.present ? color.value : this.color,
        icon: icon.present ? icon.value : this.icon,
        hideFromPublicOrdering:
            hideFromPublicOrdering ?? this.hideFromPublicOrdering,
        hideFromPosBrowse: hideFromPosBrowse ?? this.hideFromPosBrowse,
        memberDiscountEligible:
            memberDiscountEligible ?? this.memberDiscountEligible,
        pointsEarnEligible: pointsEarnEligible ?? this.pointsEarnEligible,
        pointsRedeemEligible: pointsRedeemEligible ?? this.pointsRedeemEligible,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      hideFromPublicOrdering: data.hideFromPublicOrdering.present
          ? data.hideFromPublicOrdering.value
          : this.hideFromPublicOrdering,
      hideFromPosBrowse: data.hideFromPosBrowse.present
          ? data.hideFromPosBrowse.value
          : this.hideFromPosBrowse,
      memberDiscountEligible: data.memberDiscountEligible.present
          ? data.memberDiscountEligible.value
          : this.memberDiscountEligible,
      pointsEarnEligible: data.pointsEarnEligible.present
          ? data.pointsEarnEligible.value
          : this.pointsEarnEligible,
      pointsRedeemEligible: data.pointsRedeemEligible.present
          ? data.pointsRedeemEligible.value
          : this.pointsRedeemEligible,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('hideFromPublicOrdering: $hideFromPublicOrdering, ')
          ..write('hideFromPosBrowse: $hideFromPosBrowse, ')
          ..write('memberDiscountEligible: $memberDiscountEligible, ')
          ..write('pointsEarnEligible: $pointsEarnEligible, ')
          ..write('pointsRedeemEligible: $pointsRedeemEligible, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      parentId,
      sortOrder,
      color,
      icon,
      hideFromPublicOrdering,
      hideFromPosBrowse,
      memberDiscountEligible,
      pointsEarnEligible,
      pointsRedeemEligible,
      updatedAt,
      deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.sortOrder == this.sortOrder &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.hideFromPublicOrdering == this.hideFromPublicOrdering &&
          other.hideFromPosBrowse == this.hideFromPosBrowse &&
          other.memberDiscountEligible == this.memberDiscountEligible &&
          other.pointsEarnEligible == this.pointsEarnEligible &&
          other.pointsRedeemEligible == this.pointsRedeemEligible &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<int> sortOrder;
  final Value<String?> color;
  final Value<String?> icon;
  final Value<bool> hideFromPublicOrdering;
  final Value<bool> hideFromPosBrowse;
  final Value<bool> memberDiscountEligible;
  final Value<bool> pointsEarnEligible;
  final Value<bool> pointsRedeemEligible;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.hideFromPublicOrdering = const Value.absent(),
    this.hideFromPosBrowse = const Value.absent(),
    this.memberDiscountEligible = const Value.absent(),
    this.pointsEarnEligible = const Value.absent(),
    this.pointsRedeemEligible = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    this.parentId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.hideFromPublicOrdering = const Value.absent(),
    this.hideFromPosBrowse = const Value.absent(),
    this.memberDiscountEligible = const Value.absent(),
    this.pointsEarnEligible = const Value.absent(),
    this.pointsRedeemEligible = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        updatedAt = Value(updatedAt);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<int>? sortOrder,
    Expression<String>? color,
    Expression<String>? icon,
    Expression<bool>? hideFromPublicOrdering,
    Expression<bool>? hideFromPosBrowse,
    Expression<bool>? memberDiscountEligible,
    Expression<bool>? pointsEarnEligible,
    Expression<bool>? pointsRedeemEligible,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (hideFromPublicOrdering != null)
        'hide_from_public_ordering': hideFromPublicOrdering,
      if (hideFromPosBrowse != null) 'hide_from_pos_browse': hideFromPosBrowse,
      if (memberDiscountEligible != null)
        'member_discount_eligible': memberDiscountEligible,
      if (pointsEarnEligible != null)
        'points_earn_eligible': pointsEarnEligible,
      if (pointsRedeemEligible != null)
        'points_redeem_eligible': pointsRedeemEligible,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? parentId,
      Value<int>? sortOrder,
      Value<String?>? color,
      Value<String?>? icon,
      Value<bool>? hideFromPublicOrdering,
      Value<bool>? hideFromPosBrowse,
      Value<bool>? memberDiscountEligible,
      Value<bool>? pointsEarnEligible,
      Value<bool>? pointsRedeemEligible,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      sortOrder: sortOrder ?? this.sortOrder,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      hideFromPublicOrdering:
          hideFromPublicOrdering ?? this.hideFromPublicOrdering,
      hideFromPosBrowse: hideFromPosBrowse ?? this.hideFromPosBrowse,
      memberDiscountEligible:
          memberDiscountEligible ?? this.memberDiscountEligible,
      pointsEarnEligible: pointsEarnEligible ?? this.pointsEarnEligible,
      pointsRedeemEligible: pointsRedeemEligible ?? this.pointsRedeemEligible,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (hideFromPublicOrdering.present) {
      map['hide_from_public_ordering'] =
          Variable<bool>(hideFromPublicOrdering.value);
    }
    if (hideFromPosBrowse.present) {
      map['hide_from_pos_browse'] = Variable<bool>(hideFromPosBrowse.value);
    }
    if (memberDiscountEligible.present) {
      map['member_discount_eligible'] =
          Variable<bool>(memberDiscountEligible.value);
    }
    if (pointsEarnEligible.present) {
      map['points_earn_eligible'] = Variable<bool>(pointsEarnEligible.value);
    }
    if (pointsRedeemEligible.present) {
      map['points_redeem_eligible'] =
          Variable<bool>(pointsRedeemEligible.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('hideFromPublicOrdering: $hideFromPublicOrdering, ')
          ..write('hideFromPosBrowse: $hideFromPosBrowse, ')
          ..write('memberDiscountEligible: $memberDiscountEligible, ')
          ..write('pointsEarnEligible: $pointsEarnEligible, ')
          ..write('pointsRedeemEligible: $pointsRedeemEligible, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products
    with TableInfo<$ProductsTable, ProductRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
      'sku', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priceCentsMeta =
      const VerificationMeta('priceCents');
  @override
  late final GeneratedColumn<int> priceCents = GeneratedColumn<int>(
      'price_cents', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _costCentsMeta =
      const VerificationMeta('costCents');
  @override
  late final GeneratedColumn<int> costCents = GeneratedColumn<int>(
      'cost_cents', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imageUrlMeta =
      const VerificationMeta('imageUrl');
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
      'image_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _taxRateMeta =
      const VerificationMeta('taxRate');
  @override
  late final GeneratedColumn<double> taxRate = GeneratedColumn<double>(
      'tax_rate', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.05));
  static const VerificationMeta _isWeightedMeta =
      const VerificationMeta('isWeighted');
  @override
  late final GeneratedColumn<bool> isWeighted = GeneratedColumn<bool>(
      'is_weighted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_weighted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('個'));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _hideFromPublicOrderingMeta =
      const VerificationMeta('hideFromPublicOrdering');
  @override
  late final GeneratedColumn<bool> hideFromPublicOrdering =
      GeneratedColumn<bool>('hide_from_public_ordering', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("hide_from_public_ordering" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _hideFromPosBrowseMeta =
      const VerificationMeta('hideFromPosBrowse');
  @override
  late final GeneratedColumn<bool> hideFromPosBrowse = GeneratedColumn<bool>(
      'hide_from_pos_browse', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("hide_from_pos_browse" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _trackInventoryMeta =
      const VerificationMeta('trackInventory');
  @override
  late final GeneratedColumn<bool> trackInventory = GeneratedColumn<bool>(
      'track_inventory', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("track_inventory" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _productKindMeta =
      const VerificationMeta('productKind');
  @override
  late final GeneratedColumn<String> productKind = GeneratedColumn<String>(
      'product_kind', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('regular'));
  static const VerificationMeta _memberDiscountEligibleMeta =
      const VerificationMeta('memberDiscountEligible');
  @override
  late final GeneratedColumn<bool> memberDiscountEligible =
      GeneratedColumn<bool>('member_discount_eligible', aliasedName, true,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("member_discount_eligible" IN (0, 1))'));
  static const VerificationMeta _pointsEarnEligibleMeta =
      const VerificationMeta('pointsEarnEligible');
  @override
  late final GeneratedColumn<bool> pointsEarnEligible = GeneratedColumn<bool>(
      'points_earn_eligible', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("points_earn_eligible" IN (0, 1))'));
  static const VerificationMeta _pointsRedeemEligibleMeta =
      const VerificationMeta('pointsRedeemEligible');
  @override
  late final GeneratedColumn<bool> pointsRedeemEligible = GeneratedColumn<bool>(
      'points_redeem_eligible', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("points_redeem_eligible" IN (0, 1))'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sku,
        name,
        priceCents,
        costCents,
        categoryId,
        imageUrl,
        taxRate,
        isWeighted,
        unit,
        isActive,
        description,
        hideFromPublicOrdering,
        hideFromPosBrowse,
        trackInventory,
        productKind,
        memberDiscountEligible,
        pointsEarnEligible,
        pointsRedeemEligible,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(Insertable<ProductRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
          _skuMeta, sku.isAcceptableOrUnknown(data['sku']!, _skuMeta));
    } else if (isInserting) {
      context.missing(_skuMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price_cents')) {
      context.handle(
          _priceCentsMeta,
          priceCents.isAcceptableOrUnknown(
              data['price_cents']!, _priceCentsMeta));
    }
    if (data.containsKey('cost_cents')) {
      context.handle(_costCentsMeta,
          costCents.isAcceptableOrUnknown(data['cost_cents']!, _costCentsMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('image_url')) {
      context.handle(_imageUrlMeta,
          imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta));
    }
    if (data.containsKey('tax_rate')) {
      context.handle(_taxRateMeta,
          taxRate.isAcceptableOrUnknown(data['tax_rate']!, _taxRateMeta));
    }
    if (data.containsKey('is_weighted')) {
      context.handle(
          _isWeightedMeta,
          isWeighted.isAcceptableOrUnknown(
              data['is_weighted']!, _isWeightedMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('hide_from_public_ordering')) {
      context.handle(
          _hideFromPublicOrderingMeta,
          hideFromPublicOrdering.isAcceptableOrUnknown(
              data['hide_from_public_ordering']!, _hideFromPublicOrderingMeta));
    }
    if (data.containsKey('hide_from_pos_browse')) {
      context.handle(
          _hideFromPosBrowseMeta,
          hideFromPosBrowse.isAcceptableOrUnknown(
              data['hide_from_pos_browse']!, _hideFromPosBrowseMeta));
    }
    if (data.containsKey('track_inventory')) {
      context.handle(
          _trackInventoryMeta,
          trackInventory.isAcceptableOrUnknown(
              data['track_inventory']!, _trackInventoryMeta));
    }
    if (data.containsKey('product_kind')) {
      context.handle(
          _productKindMeta,
          productKind.isAcceptableOrUnknown(
              data['product_kind']!, _productKindMeta));
    }
    if (data.containsKey('member_discount_eligible')) {
      context.handle(
          _memberDiscountEligibleMeta,
          memberDiscountEligible.isAcceptableOrUnknown(
              data['member_discount_eligible']!, _memberDiscountEligibleMeta));
    }
    if (data.containsKey('points_earn_eligible')) {
      context.handle(
          _pointsEarnEligibleMeta,
          pointsEarnEligible.isAcceptableOrUnknown(
              data['points_earn_eligible']!, _pointsEarnEligibleMeta));
    }
    if (data.containsKey('points_redeem_eligible')) {
      context.handle(
          _pointsRedeemEligibleMeta,
          pointsRedeemEligible.isAcceptableOrUnknown(
              data['points_redeem_eligible']!, _pointsRedeemEligibleMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sku: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sku'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      priceCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}price_cents'])!,
      costCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cost_cents']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      imageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_url']),
      taxRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tax_rate'])!,
      isWeighted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_weighted'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      hideFromPublicOrdering: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}hide_from_public_ordering'])!,
      hideFromPosBrowse: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}hide_from_pos_browse'])!,
      trackInventory: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}track_inventory'])!,
      productKind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_kind'])!,
      memberDiscountEligible: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}member_discount_eligible']),
      pointsEarnEligible: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}points_earn_eligible']),
      pointsRedeemEligible: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}points_redeem_eligible']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class ProductRow extends DataClass implements Insertable<ProductRow> {
  final String id;
  final String sku;
  final String name;
  final int priceCents;
  final int? costCents;
  final String? categoryId;
  final String? imageUrl;
  final double taxRate;
  final bool isWeighted;
  final String unit;
  final bool isActive;
  final String? description;
  final bool hideFromPublicOrdering;
  final bool hideFromPosBrowse;
  final bool trackInventory;
  final String productKind;
  final bool? memberDiscountEligible;
  final bool? pointsEarnEligible;
  final bool? pointsRedeemEligible;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const ProductRow(
      {required this.id,
      required this.sku,
      required this.name,
      required this.priceCents,
      this.costCents,
      this.categoryId,
      this.imageUrl,
      required this.taxRate,
      required this.isWeighted,
      required this.unit,
      required this.isActive,
      this.description,
      required this.hideFromPublicOrdering,
      required this.hideFromPosBrowse,
      required this.trackInventory,
      required this.productKind,
      this.memberDiscountEligible,
      this.pointsEarnEligible,
      this.pointsRedeemEligible,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sku'] = Variable<String>(sku);
    map['name'] = Variable<String>(name);
    map['price_cents'] = Variable<int>(priceCents);
    if (!nullToAbsent || costCents != null) {
      map['cost_cents'] = Variable<int>(costCents);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['tax_rate'] = Variable<double>(taxRate);
    map['is_weighted'] = Variable<bool>(isWeighted);
    map['unit'] = Variable<String>(unit);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['hide_from_public_ordering'] = Variable<bool>(hideFromPublicOrdering);
    map['hide_from_pos_browse'] = Variable<bool>(hideFromPosBrowse);
    map['track_inventory'] = Variable<bool>(trackInventory);
    map['product_kind'] = Variable<String>(productKind);
    if (!nullToAbsent || memberDiscountEligible != null) {
      map['member_discount_eligible'] = Variable<bool>(memberDiscountEligible);
    }
    if (!nullToAbsent || pointsEarnEligible != null) {
      map['points_earn_eligible'] = Variable<bool>(pointsEarnEligible);
    }
    if (!nullToAbsent || pointsRedeemEligible != null) {
      map['points_redeem_eligible'] = Variable<bool>(pointsRedeemEligible);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      sku: Value(sku),
      name: Value(name),
      priceCents: Value(priceCents),
      costCents: costCents == null && nullToAbsent
          ? const Value.absent()
          : Value(costCents),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      taxRate: Value(taxRate),
      isWeighted: Value(isWeighted),
      unit: Value(unit),
      isActive: Value(isActive),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      hideFromPublicOrdering: Value(hideFromPublicOrdering),
      hideFromPosBrowse: Value(hideFromPosBrowse),
      trackInventory: Value(trackInventory),
      productKind: Value(productKind),
      memberDiscountEligible: memberDiscountEligible == null && nullToAbsent
          ? const Value.absent()
          : Value(memberDiscountEligible),
      pointsEarnEligible: pointsEarnEligible == null && nullToAbsent
          ? const Value.absent()
          : Value(pointsEarnEligible),
      pointsRedeemEligible: pointsRedeemEligible == null && nullToAbsent
          ? const Value.absent()
          : Value(pointsRedeemEligible),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ProductRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductRow(
      id: serializer.fromJson<String>(json['id']),
      sku: serializer.fromJson<String>(json['sku']),
      name: serializer.fromJson<String>(json['name']),
      priceCents: serializer.fromJson<int>(json['priceCents']),
      costCents: serializer.fromJson<int?>(json['costCents']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      taxRate: serializer.fromJson<double>(json['taxRate']),
      isWeighted: serializer.fromJson<bool>(json['isWeighted']),
      unit: serializer.fromJson<String>(json['unit']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      description: serializer.fromJson<String?>(json['description']),
      hideFromPublicOrdering:
          serializer.fromJson<bool>(json['hideFromPublicOrdering']),
      hideFromPosBrowse: serializer.fromJson<bool>(json['hideFromPosBrowse']),
      trackInventory: serializer.fromJson<bool>(json['trackInventory']),
      productKind: serializer.fromJson<String>(json['productKind']),
      memberDiscountEligible:
          serializer.fromJson<bool?>(json['memberDiscountEligible']),
      pointsEarnEligible:
          serializer.fromJson<bool?>(json['pointsEarnEligible']),
      pointsRedeemEligible:
          serializer.fromJson<bool?>(json['pointsRedeemEligible']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sku': serializer.toJson<String>(sku),
      'name': serializer.toJson<String>(name),
      'priceCents': serializer.toJson<int>(priceCents),
      'costCents': serializer.toJson<int?>(costCents),
      'categoryId': serializer.toJson<String?>(categoryId),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'taxRate': serializer.toJson<double>(taxRate),
      'isWeighted': serializer.toJson<bool>(isWeighted),
      'unit': serializer.toJson<String>(unit),
      'isActive': serializer.toJson<bool>(isActive),
      'description': serializer.toJson<String?>(description),
      'hideFromPublicOrdering': serializer.toJson<bool>(hideFromPublicOrdering),
      'hideFromPosBrowse': serializer.toJson<bool>(hideFromPosBrowse),
      'trackInventory': serializer.toJson<bool>(trackInventory),
      'productKind': serializer.toJson<String>(productKind),
      'memberDiscountEligible':
          serializer.toJson<bool?>(memberDiscountEligible),
      'pointsEarnEligible': serializer.toJson<bool?>(pointsEarnEligible),
      'pointsRedeemEligible': serializer.toJson<bool?>(pointsRedeemEligible),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  ProductRow copyWith(
          {String? id,
          String? sku,
          String? name,
          int? priceCents,
          Value<int?> costCents = const Value.absent(),
          Value<String?> categoryId = const Value.absent(),
          Value<String?> imageUrl = const Value.absent(),
          double? taxRate,
          bool? isWeighted,
          String? unit,
          bool? isActive,
          Value<String?> description = const Value.absent(),
          bool? hideFromPublicOrdering,
          bool? hideFromPosBrowse,
          bool? trackInventory,
          String? productKind,
          Value<bool?> memberDiscountEligible = const Value.absent(),
          Value<bool?> pointsEarnEligible = const Value.absent(),
          Value<bool?> pointsRedeemEligible = const Value.absent(),
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      ProductRow(
        id: id ?? this.id,
        sku: sku ?? this.sku,
        name: name ?? this.name,
        priceCents: priceCents ?? this.priceCents,
        costCents: costCents.present ? costCents.value : this.costCents,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
        taxRate: taxRate ?? this.taxRate,
        isWeighted: isWeighted ?? this.isWeighted,
        unit: unit ?? this.unit,
        isActive: isActive ?? this.isActive,
        description: description.present ? description.value : this.description,
        hideFromPublicOrdering:
            hideFromPublicOrdering ?? this.hideFromPublicOrdering,
        hideFromPosBrowse: hideFromPosBrowse ?? this.hideFromPosBrowse,
        trackInventory: trackInventory ?? this.trackInventory,
        productKind: productKind ?? this.productKind,
        memberDiscountEligible: memberDiscountEligible.present
            ? memberDiscountEligible.value
            : this.memberDiscountEligible,
        pointsEarnEligible: pointsEarnEligible.present
            ? pointsEarnEligible.value
            : this.pointsEarnEligible,
        pointsRedeemEligible: pointsRedeemEligible.present
            ? pointsRedeemEligible.value
            : this.pointsRedeemEligible,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  ProductRow copyWithCompanion(ProductsCompanion data) {
    return ProductRow(
      id: data.id.present ? data.id.value : this.id,
      sku: data.sku.present ? data.sku.value : this.sku,
      name: data.name.present ? data.name.value : this.name,
      priceCents:
          data.priceCents.present ? data.priceCents.value : this.priceCents,
      costCents: data.costCents.present ? data.costCents.value : this.costCents,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      taxRate: data.taxRate.present ? data.taxRate.value : this.taxRate,
      isWeighted:
          data.isWeighted.present ? data.isWeighted.value : this.isWeighted,
      unit: data.unit.present ? data.unit.value : this.unit,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      description:
          data.description.present ? data.description.value : this.description,
      hideFromPublicOrdering: data.hideFromPublicOrdering.present
          ? data.hideFromPublicOrdering.value
          : this.hideFromPublicOrdering,
      hideFromPosBrowse: data.hideFromPosBrowse.present
          ? data.hideFromPosBrowse.value
          : this.hideFromPosBrowse,
      trackInventory: data.trackInventory.present
          ? data.trackInventory.value
          : this.trackInventory,
      productKind:
          data.productKind.present ? data.productKind.value : this.productKind,
      memberDiscountEligible: data.memberDiscountEligible.present
          ? data.memberDiscountEligible.value
          : this.memberDiscountEligible,
      pointsEarnEligible: data.pointsEarnEligible.present
          ? data.pointsEarnEligible.value
          : this.pointsEarnEligible,
      pointsRedeemEligible: data.pointsRedeemEligible.present
          ? data.pointsRedeemEligible.value
          : this.pointsRedeemEligible,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductRow(')
          ..write('id: $id, ')
          ..write('sku: $sku, ')
          ..write('name: $name, ')
          ..write('priceCents: $priceCents, ')
          ..write('costCents: $costCents, ')
          ..write('categoryId: $categoryId, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('taxRate: $taxRate, ')
          ..write('isWeighted: $isWeighted, ')
          ..write('unit: $unit, ')
          ..write('isActive: $isActive, ')
          ..write('description: $description, ')
          ..write('hideFromPublicOrdering: $hideFromPublicOrdering, ')
          ..write('hideFromPosBrowse: $hideFromPosBrowse, ')
          ..write('trackInventory: $trackInventory, ')
          ..write('productKind: $productKind, ')
          ..write('memberDiscountEligible: $memberDiscountEligible, ')
          ..write('pointsEarnEligible: $pointsEarnEligible, ')
          ..write('pointsRedeemEligible: $pointsRedeemEligible, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        sku,
        name,
        priceCents,
        costCents,
        categoryId,
        imageUrl,
        taxRate,
        isWeighted,
        unit,
        isActive,
        description,
        hideFromPublicOrdering,
        hideFromPosBrowse,
        trackInventory,
        productKind,
        memberDiscountEligible,
        pointsEarnEligible,
        pointsRedeemEligible,
        updatedAt,
        deletedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductRow &&
          other.id == this.id &&
          other.sku == this.sku &&
          other.name == this.name &&
          other.priceCents == this.priceCents &&
          other.costCents == this.costCents &&
          other.categoryId == this.categoryId &&
          other.imageUrl == this.imageUrl &&
          other.taxRate == this.taxRate &&
          other.isWeighted == this.isWeighted &&
          other.unit == this.unit &&
          other.isActive == this.isActive &&
          other.description == this.description &&
          other.hideFromPublicOrdering == this.hideFromPublicOrdering &&
          other.hideFromPosBrowse == this.hideFromPosBrowse &&
          other.trackInventory == this.trackInventory &&
          other.productKind == this.productKind &&
          other.memberDiscountEligible == this.memberDiscountEligible &&
          other.pointsEarnEligible == this.pointsEarnEligible &&
          other.pointsRedeemEligible == this.pointsRedeemEligible &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ProductsCompanion extends UpdateCompanion<ProductRow> {
  final Value<String> id;
  final Value<String> sku;
  final Value<String> name;
  final Value<int> priceCents;
  final Value<int?> costCents;
  final Value<String?> categoryId;
  final Value<String?> imageUrl;
  final Value<double> taxRate;
  final Value<bool> isWeighted;
  final Value<String> unit;
  final Value<bool> isActive;
  final Value<String?> description;
  final Value<bool> hideFromPublicOrdering;
  final Value<bool> hideFromPosBrowse;
  final Value<bool> trackInventory;
  final Value<String> productKind;
  final Value<bool?> memberDiscountEligible;
  final Value<bool?> pointsEarnEligible;
  final Value<bool?> pointsRedeemEligible;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.sku = const Value.absent(),
    this.name = const Value.absent(),
    this.priceCents = const Value.absent(),
    this.costCents = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.isWeighted = const Value.absent(),
    this.unit = const Value.absent(),
    this.isActive = const Value.absent(),
    this.description = const Value.absent(),
    this.hideFromPublicOrdering = const Value.absent(),
    this.hideFromPosBrowse = const Value.absent(),
    this.trackInventory = const Value.absent(),
    this.productKind = const Value.absent(),
    this.memberDiscountEligible = const Value.absent(),
    this.pointsEarnEligible = const Value.absent(),
    this.pointsRedeemEligible = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String sku,
    required String name,
    this.priceCents = const Value.absent(),
    this.costCents = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.isWeighted = const Value.absent(),
    this.unit = const Value.absent(),
    this.isActive = const Value.absent(),
    this.description = const Value.absent(),
    this.hideFromPublicOrdering = const Value.absent(),
    this.hideFromPosBrowse = const Value.absent(),
    this.trackInventory = const Value.absent(),
    this.productKind = const Value.absent(),
    this.memberDiscountEligible = const Value.absent(),
    this.pointsEarnEligible = const Value.absent(),
    this.pointsRedeemEligible = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        sku = Value(sku),
        name = Value(name),
        updatedAt = Value(updatedAt);
  static Insertable<ProductRow> custom({
    Expression<String>? id,
    Expression<String>? sku,
    Expression<String>? name,
    Expression<int>? priceCents,
    Expression<int>? costCents,
    Expression<String>? categoryId,
    Expression<String>? imageUrl,
    Expression<double>? taxRate,
    Expression<bool>? isWeighted,
    Expression<String>? unit,
    Expression<bool>? isActive,
    Expression<String>? description,
    Expression<bool>? hideFromPublicOrdering,
    Expression<bool>? hideFromPosBrowse,
    Expression<bool>? trackInventory,
    Expression<String>? productKind,
    Expression<bool>? memberDiscountEligible,
    Expression<bool>? pointsEarnEligible,
    Expression<bool>? pointsRedeemEligible,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sku != null) 'sku': sku,
      if (name != null) 'name': name,
      if (priceCents != null) 'price_cents': priceCents,
      if (costCents != null) 'cost_cents': costCents,
      if (categoryId != null) 'category_id': categoryId,
      if (imageUrl != null) 'image_url': imageUrl,
      if (taxRate != null) 'tax_rate': taxRate,
      if (isWeighted != null) 'is_weighted': isWeighted,
      if (unit != null) 'unit': unit,
      if (isActive != null) 'is_active': isActive,
      if (description != null) 'description': description,
      if (hideFromPublicOrdering != null)
        'hide_from_public_ordering': hideFromPublicOrdering,
      if (hideFromPosBrowse != null) 'hide_from_pos_browse': hideFromPosBrowse,
      if (trackInventory != null) 'track_inventory': trackInventory,
      if (productKind != null) 'product_kind': productKind,
      if (memberDiscountEligible != null)
        'member_discount_eligible': memberDiscountEligible,
      if (pointsEarnEligible != null)
        'points_earn_eligible': pointsEarnEligible,
      if (pointsRedeemEligible != null)
        'points_redeem_eligible': pointsRedeemEligible,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith(
      {Value<String>? id,
      Value<String>? sku,
      Value<String>? name,
      Value<int>? priceCents,
      Value<int?>? costCents,
      Value<String?>? categoryId,
      Value<String?>? imageUrl,
      Value<double>? taxRate,
      Value<bool>? isWeighted,
      Value<String>? unit,
      Value<bool>? isActive,
      Value<String?>? description,
      Value<bool>? hideFromPublicOrdering,
      Value<bool>? hideFromPosBrowse,
      Value<bool>? trackInventory,
      Value<String>? productKind,
      Value<bool?>? memberDiscountEligible,
      Value<bool?>? pointsEarnEligible,
      Value<bool?>? pointsRedeemEligible,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return ProductsCompanion(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      priceCents: priceCents ?? this.priceCents,
      costCents: costCents ?? this.costCents,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      taxRate: taxRate ?? this.taxRate,
      isWeighted: isWeighted ?? this.isWeighted,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      hideFromPublicOrdering:
          hideFromPublicOrdering ?? this.hideFromPublicOrdering,
      hideFromPosBrowse: hideFromPosBrowse ?? this.hideFromPosBrowse,
      trackInventory: trackInventory ?? this.trackInventory,
      productKind: productKind ?? this.productKind,
      memberDiscountEligible:
          memberDiscountEligible ?? this.memberDiscountEligible,
      pointsEarnEligible: pointsEarnEligible ?? this.pointsEarnEligible,
      pointsRedeemEligible: pointsRedeemEligible ?? this.pointsRedeemEligible,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (priceCents.present) {
      map['price_cents'] = Variable<int>(priceCents.value);
    }
    if (costCents.present) {
      map['cost_cents'] = Variable<int>(costCents.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (taxRate.present) {
      map['tax_rate'] = Variable<double>(taxRate.value);
    }
    if (isWeighted.present) {
      map['is_weighted'] = Variable<bool>(isWeighted.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (hideFromPublicOrdering.present) {
      map['hide_from_public_ordering'] =
          Variable<bool>(hideFromPublicOrdering.value);
    }
    if (hideFromPosBrowse.present) {
      map['hide_from_pos_browse'] = Variable<bool>(hideFromPosBrowse.value);
    }
    if (trackInventory.present) {
      map['track_inventory'] = Variable<bool>(trackInventory.value);
    }
    if (productKind.present) {
      map['product_kind'] = Variable<String>(productKind.value);
    }
    if (memberDiscountEligible.present) {
      map['member_discount_eligible'] =
          Variable<bool>(memberDiscountEligible.value);
    }
    if (pointsEarnEligible.present) {
      map['points_earn_eligible'] = Variable<bool>(pointsEarnEligible.value);
    }
    if (pointsRedeemEligible.present) {
      map['points_redeem_eligible'] =
          Variable<bool>(pointsRedeemEligible.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('sku: $sku, ')
          ..write('name: $name, ')
          ..write('priceCents: $priceCents, ')
          ..write('costCents: $costCents, ')
          ..write('categoryId: $categoryId, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('taxRate: $taxRate, ')
          ..write('isWeighted: $isWeighted, ')
          ..write('unit: $unit, ')
          ..write('isActive: $isActive, ')
          ..write('description: $description, ')
          ..write('hideFromPublicOrdering: $hideFromPublicOrdering, ')
          ..write('hideFromPosBrowse: $hideFromPosBrowse, ')
          ..write('trackInventory: $trackInventory, ')
          ..write('productKind: $productKind, ')
          ..write('memberDiscountEligible: $memberDiscountEligible, ')
          ..write('pointsEarnEligible: $pointsEarnEligible, ')
          ..write('pointsRedeemEligible: $pointsRedeemEligible, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookDetailsTable extends BookDetails
    with TableInfo<$BookDetailsTable, BookDetailRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookDetailsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
      'author', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _publisherMeta =
      const VerificationMeta('publisher');
  @override
  late final GeneratedColumn<String> publisher = GeneratedColumn<String>(
      'publisher', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isbnMeta = const VerificationMeta('isbn');
  @override
  late final GeneratedColumn<String> isbn = GeneratedColumn<String>(
      'isbn', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [productId, barcode, author, publisher, isbn, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_details';
  @override
  VerificationContext validateIntegrity(Insertable<BookDetailRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    } else if (isInserting) {
      context.missing(_barcodeMeta);
    }
    if (data.containsKey('author')) {
      context.handle(_authorMeta,
          author.isAcceptableOrUnknown(data['author']!, _authorMeta));
    }
    if (data.containsKey('publisher')) {
      context.handle(_publisherMeta,
          publisher.isAcceptableOrUnknown(data['publisher']!, _publisherMeta));
    }
    if (data.containsKey('isbn')) {
      context.handle(
          _isbnMeta, isbn.isAcceptableOrUnknown(data['isbn']!, _isbnMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {productId};
  @override
  BookDetailRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookDetailRow(
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode'])!,
      author: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}author']),
      publisher: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}publisher']),
      isbn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}isbn']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BookDetailsTable createAlias(String alias) {
    return $BookDetailsTable(attachedDatabase, alias);
  }
}

class BookDetailRow extends DataClass implements Insertable<BookDetailRow> {
  final String productId;
  final String barcode;
  final String? author;
  final String? publisher;
  final String? isbn;
  final DateTime updatedAt;
  const BookDetailRow(
      {required this.productId,
      required this.barcode,
      this.author,
      this.publisher,
      this.isbn,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['product_id'] = Variable<String>(productId);
    map['barcode'] = Variable<String>(barcode);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || publisher != null) {
      map['publisher'] = Variable<String>(publisher);
    }
    if (!nullToAbsent || isbn != null) {
      map['isbn'] = Variable<String>(isbn);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BookDetailsCompanion toCompanion(bool nullToAbsent) {
    return BookDetailsCompanion(
      productId: Value(productId),
      barcode: Value(barcode),
      author:
          author == null && nullToAbsent ? const Value.absent() : Value(author),
      publisher: publisher == null && nullToAbsent
          ? const Value.absent()
          : Value(publisher),
      isbn: isbn == null && nullToAbsent ? const Value.absent() : Value(isbn),
      updatedAt: Value(updatedAt),
    );
  }

  factory BookDetailRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookDetailRow(
      productId: serializer.fromJson<String>(json['productId']),
      barcode: serializer.fromJson<String>(json['barcode']),
      author: serializer.fromJson<String?>(json['author']),
      publisher: serializer.fromJson<String?>(json['publisher']),
      isbn: serializer.fromJson<String?>(json['isbn']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'productId': serializer.toJson<String>(productId),
      'barcode': serializer.toJson<String>(barcode),
      'author': serializer.toJson<String?>(author),
      'publisher': serializer.toJson<String?>(publisher),
      'isbn': serializer.toJson<String?>(isbn),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BookDetailRow copyWith(
          {String? productId,
          String? barcode,
          Value<String?> author = const Value.absent(),
          Value<String?> publisher = const Value.absent(),
          Value<String?> isbn = const Value.absent(),
          DateTime? updatedAt}) =>
      BookDetailRow(
        productId: productId ?? this.productId,
        barcode: barcode ?? this.barcode,
        author: author.present ? author.value : this.author,
        publisher: publisher.present ? publisher.value : this.publisher,
        isbn: isbn.present ? isbn.value : this.isbn,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  BookDetailRow copyWithCompanion(BookDetailsCompanion data) {
    return BookDetailRow(
      productId: data.productId.present ? data.productId.value : this.productId,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      author: data.author.present ? data.author.value : this.author,
      publisher: data.publisher.present ? data.publisher.value : this.publisher,
      isbn: data.isbn.present ? data.isbn.value : this.isbn,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookDetailRow(')
          ..write('productId: $productId, ')
          ..write('barcode: $barcode, ')
          ..write('author: $author, ')
          ..write('publisher: $publisher, ')
          ..write('isbn: $isbn, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(productId, barcode, author, publisher, isbn, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookDetailRow &&
          other.productId == this.productId &&
          other.barcode == this.barcode &&
          other.author == this.author &&
          other.publisher == this.publisher &&
          other.isbn == this.isbn &&
          other.updatedAt == this.updatedAt);
}

class BookDetailsCompanion extends UpdateCompanion<BookDetailRow> {
  final Value<String> productId;
  final Value<String> barcode;
  final Value<String?> author;
  final Value<String?> publisher;
  final Value<String?> isbn;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BookDetailsCompanion({
    this.productId = const Value.absent(),
    this.barcode = const Value.absent(),
    this.author = const Value.absent(),
    this.publisher = const Value.absent(),
    this.isbn = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookDetailsCompanion.insert({
    required String productId,
    required String barcode,
    this.author = const Value.absent(),
    this.publisher = const Value.absent(),
    this.isbn = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : productId = Value(productId),
        barcode = Value(barcode),
        updatedAt = Value(updatedAt);
  static Insertable<BookDetailRow> custom({
    Expression<String>? productId,
    Expression<String>? barcode,
    Expression<String>? author,
    Expression<String>? publisher,
    Expression<String>? isbn,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (productId != null) 'product_id': productId,
      if (barcode != null) 'barcode': barcode,
      if (author != null) 'author': author,
      if (publisher != null) 'publisher': publisher,
      if (isbn != null) 'isbn': isbn,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookDetailsCompanion copyWith(
      {Value<String>? productId,
      Value<String>? barcode,
      Value<String?>? author,
      Value<String?>? publisher,
      Value<String?>? isbn,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return BookDetailsCompanion(
      productId: productId ?? this.productId,
      barcode: barcode ?? this.barcode,
      author: author ?? this.author,
      publisher: publisher ?? this.publisher,
      isbn: isbn ?? this.isbn,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (publisher.present) {
      map['publisher'] = Variable<String>(publisher.value);
    }
    if (isbn.present) {
      map['isbn'] = Variable<String>(isbn.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookDetailsCompanion(')
          ..write('productId: $productId, ')
          ..write('barcode: $barcode, ')
          ..write('author: $author, ')
          ..write('publisher: $publisher, ')
          ..write('isbn: $isbn, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductBarcodesTable extends ProductBarcodes
    with TableInfo<$ProductBarcodesTable, ProductBarcodeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductBarcodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [productId, barcode];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_barcodes';
  @override
  VerificationContext validateIntegrity(Insertable<ProductBarcodeRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    } else if (isInserting) {
      context.missing(_barcodeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {barcode};
  @override
  ProductBarcodeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductBarcodeRow(
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode'])!,
    );
  }

  @override
  $ProductBarcodesTable createAlias(String alias) {
    return $ProductBarcodesTable(attachedDatabase, alias);
  }
}

class ProductBarcodeRow extends DataClass
    implements Insertable<ProductBarcodeRow> {
  final String productId;
  final String barcode;
  const ProductBarcodeRow({required this.productId, required this.barcode});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['product_id'] = Variable<String>(productId);
    map['barcode'] = Variable<String>(barcode);
    return map;
  }

  ProductBarcodesCompanion toCompanion(bool nullToAbsent) {
    return ProductBarcodesCompanion(
      productId: Value(productId),
      barcode: Value(barcode),
    );
  }

  factory ProductBarcodeRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductBarcodeRow(
      productId: serializer.fromJson<String>(json['productId']),
      barcode: serializer.fromJson<String>(json['barcode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'productId': serializer.toJson<String>(productId),
      'barcode': serializer.toJson<String>(barcode),
    };
  }

  ProductBarcodeRow copyWith({String? productId, String? barcode}) =>
      ProductBarcodeRow(
        productId: productId ?? this.productId,
        barcode: barcode ?? this.barcode,
      );
  ProductBarcodeRow copyWithCompanion(ProductBarcodesCompanion data) {
    return ProductBarcodeRow(
      productId: data.productId.present ? data.productId.value : this.productId,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductBarcodeRow(')
          ..write('productId: $productId, ')
          ..write('barcode: $barcode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(productId, barcode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductBarcodeRow &&
          other.productId == this.productId &&
          other.barcode == this.barcode);
}

class ProductBarcodesCompanion extends UpdateCompanion<ProductBarcodeRow> {
  final Value<String> productId;
  final Value<String> barcode;
  final Value<int> rowid;
  const ProductBarcodesCompanion({
    this.productId = const Value.absent(),
    this.barcode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductBarcodesCompanion.insert({
    required String productId,
    required String barcode,
    this.rowid = const Value.absent(),
  })  : productId = Value(productId),
        barcode = Value(barcode);
  static Insertable<ProductBarcodeRow> custom({
    Expression<String>? productId,
    Expression<String>? barcode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (productId != null) 'product_id': productId,
      if (barcode != null) 'barcode': barcode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductBarcodesCompanion copyWith(
      {Value<String>? productId, Value<String>? barcode, Value<int>? rowid}) {
    return ProductBarcodesCompanion(
      productId: productId ?? this.productId,
      barcode: barcode ?? this.barcode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductBarcodesCompanion(')
          ..write('productId: $productId, ')
          ..write('barcode: $barcode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OptionGroupsTable extends OptionGroups
    with TableInfo<$OptionGroupsTable, OptionGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OptionGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _selectionTypeMeta =
      const VerificationMeta('selectionType');
  @override
  late final GeneratedColumn<String> selectionType = GeneratedColumn<String>(
      'selection_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('single'));
  static const VerificationMeta _isRequiredMeta =
      const VerificationMeta('isRequired');
  @override
  late final GeneratedColumn<bool> isRequired = GeneratedColumn<bool>(
      'is_required', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_required" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _minSelectionsMeta =
      const VerificationMeta('minSelections');
  @override
  late final GeneratedColumn<int> minSelections = GeneratedColumn<int>(
      'min_selections', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _maxSelectionsMeta =
      const VerificationMeta('maxSelections');
  @override
  late final GeneratedColumn<int> maxSelections = GeneratedColumn<int>(
      'max_selections', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        selectionType,
        isRequired,
        minSelections,
        maxSelections,
        sortOrder,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'option_groups';
  @override
  VerificationContext validateIntegrity(Insertable<OptionGroupRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('selection_type')) {
      context.handle(
          _selectionTypeMeta,
          selectionType.isAcceptableOrUnknown(
              data['selection_type']!, _selectionTypeMeta));
    }
    if (data.containsKey('is_required')) {
      context.handle(
          _isRequiredMeta,
          isRequired.isAcceptableOrUnknown(
              data['is_required']!, _isRequiredMeta));
    }
    if (data.containsKey('min_selections')) {
      context.handle(
          _minSelectionsMeta,
          minSelections.isAcceptableOrUnknown(
              data['min_selections']!, _minSelectionsMeta));
    }
    if (data.containsKey('max_selections')) {
      context.handle(
          _maxSelectionsMeta,
          maxSelections.isAcceptableOrUnknown(
              data['max_selections']!, _maxSelectionsMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OptionGroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OptionGroupRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      selectionType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}selection_type'])!,
      isRequired: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_required'])!,
      minSelections: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}min_selections'])!,
      maxSelections: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_selections']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $OptionGroupsTable createAlias(String alias) {
    return $OptionGroupsTable(attachedDatabase, alias);
  }
}

class OptionGroupRow extends DataClass implements Insertable<OptionGroupRow> {
  final String id;
  final String name;
  final String selectionType;
  final bool isRequired;
  final int minSelections;
  final int? maxSelections;
  final int sortOrder;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const OptionGroupRow(
      {required this.id,
      required this.name,
      required this.selectionType,
      required this.isRequired,
      required this.minSelections,
      this.maxSelections,
      required this.sortOrder,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['selection_type'] = Variable<String>(selectionType);
    map['is_required'] = Variable<bool>(isRequired);
    map['min_selections'] = Variable<int>(minSelections);
    if (!nullToAbsent || maxSelections != null) {
      map['max_selections'] = Variable<int>(maxSelections);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  OptionGroupsCompanion toCompanion(bool nullToAbsent) {
    return OptionGroupsCompanion(
      id: Value(id),
      name: Value(name),
      selectionType: Value(selectionType),
      isRequired: Value(isRequired),
      minSelections: Value(minSelections),
      maxSelections: maxSelections == null && nullToAbsent
          ? const Value.absent()
          : Value(maxSelections),
      sortOrder: Value(sortOrder),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory OptionGroupRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OptionGroupRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      selectionType: serializer.fromJson<String>(json['selectionType']),
      isRequired: serializer.fromJson<bool>(json['isRequired']),
      minSelections: serializer.fromJson<int>(json['minSelections']),
      maxSelections: serializer.fromJson<int?>(json['maxSelections']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'selectionType': serializer.toJson<String>(selectionType),
      'isRequired': serializer.toJson<bool>(isRequired),
      'minSelections': serializer.toJson<int>(minSelections),
      'maxSelections': serializer.toJson<int?>(maxSelections),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  OptionGroupRow copyWith(
          {String? id,
          String? name,
          String? selectionType,
          bool? isRequired,
          int? minSelections,
          Value<int?> maxSelections = const Value.absent(),
          int? sortOrder,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      OptionGroupRow(
        id: id ?? this.id,
        name: name ?? this.name,
        selectionType: selectionType ?? this.selectionType,
        isRequired: isRequired ?? this.isRequired,
        minSelections: minSelections ?? this.minSelections,
        maxSelections:
            maxSelections.present ? maxSelections.value : this.maxSelections,
        sortOrder: sortOrder ?? this.sortOrder,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  OptionGroupRow copyWithCompanion(OptionGroupsCompanion data) {
    return OptionGroupRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      selectionType: data.selectionType.present
          ? data.selectionType.value
          : this.selectionType,
      isRequired:
          data.isRequired.present ? data.isRequired.value : this.isRequired,
      minSelections: data.minSelections.present
          ? data.minSelections.value
          : this.minSelections,
      maxSelections: data.maxSelections.present
          ? data.maxSelections.value
          : this.maxSelections,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OptionGroupRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('selectionType: $selectionType, ')
          ..write('isRequired: $isRequired, ')
          ..write('minSelections: $minSelections, ')
          ..write('maxSelections: $maxSelections, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, selectionType, isRequired,
      minSelections, maxSelections, sortOrder, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OptionGroupRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.selectionType == this.selectionType &&
          other.isRequired == this.isRequired &&
          other.minSelections == this.minSelections &&
          other.maxSelections == this.maxSelections &&
          other.sortOrder == this.sortOrder &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class OptionGroupsCompanion extends UpdateCompanion<OptionGroupRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> selectionType;
  final Value<bool> isRequired;
  final Value<int> minSelections;
  final Value<int?> maxSelections;
  final Value<int> sortOrder;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const OptionGroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.selectionType = const Value.absent(),
    this.isRequired = const Value.absent(),
    this.minSelections = const Value.absent(),
    this.maxSelections = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OptionGroupsCompanion.insert({
    required String id,
    required String name,
    this.selectionType = const Value.absent(),
    this.isRequired = const Value.absent(),
    this.minSelections = const Value.absent(),
    this.maxSelections = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        updatedAt = Value(updatedAt);
  static Insertable<OptionGroupRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? selectionType,
    Expression<bool>? isRequired,
    Expression<int>? minSelections,
    Expression<int>? maxSelections,
    Expression<int>? sortOrder,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (selectionType != null) 'selection_type': selectionType,
      if (isRequired != null) 'is_required': isRequired,
      if (minSelections != null) 'min_selections': minSelections,
      if (maxSelections != null) 'max_selections': maxSelections,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OptionGroupsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? selectionType,
      Value<bool>? isRequired,
      Value<int>? minSelections,
      Value<int?>? maxSelections,
      Value<int>? sortOrder,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return OptionGroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      selectionType: selectionType ?? this.selectionType,
      isRequired: isRequired ?? this.isRequired,
      minSelections: minSelections ?? this.minSelections,
      maxSelections: maxSelections ?? this.maxSelections,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (selectionType.present) {
      map['selection_type'] = Variable<String>(selectionType.value);
    }
    if (isRequired.present) {
      map['is_required'] = Variable<bool>(isRequired.value);
    }
    if (minSelections.present) {
      map['min_selections'] = Variable<int>(minSelections.value);
    }
    if (maxSelections.present) {
      map['max_selections'] = Variable<int>(maxSelections.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OptionGroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('selectionType: $selectionType, ')
          ..write('isRequired: $isRequired, ')
          ..write('minSelections: $minSelections, ')
          ..write('maxSelections: $maxSelections, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OptionChoicesTable extends OptionChoices
    with TableInfo<$OptionChoicesTable, OptionChoiceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OptionChoicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _optionGroupIdMeta =
      const VerificationMeta('optionGroupId');
  @override
  late final GeneratedColumn<String> optionGroupId = GeneratedColumn<String>(
      'option_group_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES option_groups (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priceDeltaCentsMeta =
      const VerificationMeta('priceDeltaCents');
  @override
  late final GeneratedColumn<int> priceDeltaCents = GeneratedColumn<int>(
      'price_delta_cents', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isDefaultMeta =
      const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
      'is_default', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_default" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        optionGroupId,
        name,
        priceDeltaCents,
        isDefault,
        sortOrder,
        isActive,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'option_choices';
  @override
  VerificationContext validateIntegrity(Insertable<OptionChoiceRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('option_group_id')) {
      context.handle(
          _optionGroupIdMeta,
          optionGroupId.isAcceptableOrUnknown(
              data['option_group_id']!, _optionGroupIdMeta));
    } else if (isInserting) {
      context.missing(_optionGroupIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price_delta_cents')) {
      context.handle(
          _priceDeltaCentsMeta,
          priceDeltaCents.isAcceptableOrUnknown(
              data['price_delta_cents']!, _priceDeltaCentsMeta));
    }
    if (data.containsKey('is_default')) {
      context.handle(_isDefaultMeta,
          isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OptionChoiceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OptionChoiceRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      optionGroupId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}option_group_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      priceDeltaCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}price_delta_cents'])!,
      isDefault: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_default'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $OptionChoicesTable createAlias(String alias) {
    return $OptionChoicesTable(attachedDatabase, alias);
  }
}

class OptionChoiceRow extends DataClass implements Insertable<OptionChoiceRow> {
  final String id;
  final String optionGroupId;
  final String name;
  final int priceDeltaCents;
  final bool isDefault;
  final int sortOrder;
  final bool isActive;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const OptionChoiceRow(
      {required this.id,
      required this.optionGroupId,
      required this.name,
      required this.priceDeltaCents,
      required this.isDefault,
      required this.sortOrder,
      required this.isActive,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['option_group_id'] = Variable<String>(optionGroupId);
    map['name'] = Variable<String>(name);
    map['price_delta_cents'] = Variable<int>(priceDeltaCents);
    map['is_default'] = Variable<bool>(isDefault);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_active'] = Variable<bool>(isActive);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  OptionChoicesCompanion toCompanion(bool nullToAbsent) {
    return OptionChoicesCompanion(
      id: Value(id),
      optionGroupId: Value(optionGroupId),
      name: Value(name),
      priceDeltaCents: Value(priceDeltaCents),
      isDefault: Value(isDefault),
      sortOrder: Value(sortOrder),
      isActive: Value(isActive),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory OptionChoiceRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OptionChoiceRow(
      id: serializer.fromJson<String>(json['id']),
      optionGroupId: serializer.fromJson<String>(json['optionGroupId']),
      name: serializer.fromJson<String>(json['name']),
      priceDeltaCents: serializer.fromJson<int>(json['priceDeltaCents']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'optionGroupId': serializer.toJson<String>(optionGroupId),
      'name': serializer.toJson<String>(name),
      'priceDeltaCents': serializer.toJson<int>(priceDeltaCents),
      'isDefault': serializer.toJson<bool>(isDefault),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isActive': serializer.toJson<bool>(isActive),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  OptionChoiceRow copyWith(
          {String? id,
          String? optionGroupId,
          String? name,
          int? priceDeltaCents,
          bool? isDefault,
          int? sortOrder,
          bool? isActive,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      OptionChoiceRow(
        id: id ?? this.id,
        optionGroupId: optionGroupId ?? this.optionGroupId,
        name: name ?? this.name,
        priceDeltaCents: priceDeltaCents ?? this.priceDeltaCents,
        isDefault: isDefault ?? this.isDefault,
        sortOrder: sortOrder ?? this.sortOrder,
        isActive: isActive ?? this.isActive,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  OptionChoiceRow copyWithCompanion(OptionChoicesCompanion data) {
    return OptionChoiceRow(
      id: data.id.present ? data.id.value : this.id,
      optionGroupId: data.optionGroupId.present
          ? data.optionGroupId.value
          : this.optionGroupId,
      name: data.name.present ? data.name.value : this.name,
      priceDeltaCents: data.priceDeltaCents.present
          ? data.priceDeltaCents.value
          : this.priceDeltaCents,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OptionChoiceRow(')
          ..write('id: $id, ')
          ..write('optionGroupId: $optionGroupId, ')
          ..write('name: $name, ')
          ..write('priceDeltaCents: $priceDeltaCents, ')
          ..write('isDefault: $isDefault, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, optionGroupId, name, priceDeltaCents,
      isDefault, sortOrder, isActive, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OptionChoiceRow &&
          other.id == this.id &&
          other.optionGroupId == this.optionGroupId &&
          other.name == this.name &&
          other.priceDeltaCents == this.priceDeltaCents &&
          other.isDefault == this.isDefault &&
          other.sortOrder == this.sortOrder &&
          other.isActive == this.isActive &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class OptionChoicesCompanion extends UpdateCompanion<OptionChoiceRow> {
  final Value<String> id;
  final Value<String> optionGroupId;
  final Value<String> name;
  final Value<int> priceDeltaCents;
  final Value<bool> isDefault;
  final Value<int> sortOrder;
  final Value<bool> isActive;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const OptionChoicesCompanion({
    this.id = const Value.absent(),
    this.optionGroupId = const Value.absent(),
    this.name = const Value.absent(),
    this.priceDeltaCents = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OptionChoicesCompanion.insert({
    required String id,
    required String optionGroupId,
    required String name,
    this.priceDeltaCents = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        optionGroupId = Value(optionGroupId),
        name = Value(name),
        updatedAt = Value(updatedAt);
  static Insertable<OptionChoiceRow> custom({
    Expression<String>? id,
    Expression<String>? optionGroupId,
    Expression<String>? name,
    Expression<int>? priceDeltaCents,
    Expression<bool>? isDefault,
    Expression<int>? sortOrder,
    Expression<bool>? isActive,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (optionGroupId != null) 'option_group_id': optionGroupId,
      if (name != null) 'name': name,
      if (priceDeltaCents != null) 'price_delta_cents': priceDeltaCents,
      if (isDefault != null) 'is_default': isDefault,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isActive != null) 'is_active': isActive,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OptionChoicesCompanion copyWith(
      {Value<String>? id,
      Value<String>? optionGroupId,
      Value<String>? name,
      Value<int>? priceDeltaCents,
      Value<bool>? isDefault,
      Value<int>? sortOrder,
      Value<bool>? isActive,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return OptionChoicesCompanion(
      id: id ?? this.id,
      optionGroupId: optionGroupId ?? this.optionGroupId,
      name: name ?? this.name,
      priceDeltaCents: priceDeltaCents ?? this.priceDeltaCents,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (optionGroupId.present) {
      map['option_group_id'] = Variable<String>(optionGroupId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (priceDeltaCents.present) {
      map['price_delta_cents'] = Variable<int>(priceDeltaCents.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OptionChoicesCompanion(')
          ..write('id: $id, ')
          ..write('optionGroupId: $optionGroupId, ')
          ..write('name: $name, ')
          ..write('priceDeltaCents: $priceDeltaCents, ')
          ..write('isDefault: $isDefault, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductOptionGroupsTable extends ProductOptionGroups
    with TableInfo<$ProductOptionGroupsTable, ProductOptionGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductOptionGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _optionGroupIdMeta =
      const VerificationMeta('optionGroupId');
  @override
  late final GeneratedColumn<String> optionGroupId = GeneratedColumn<String>(
      'option_group_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES option_groups (id)'));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isRequiredMeta =
      const VerificationMeta('isRequired');
  @override
  late final GeneratedColumn<bool> isRequired = GeneratedColumn<bool>(
      'is_required', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_required" IN (0, 1))'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, productId, optionGroupId, sortOrder, isRequired, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_option_groups';
  @override
  VerificationContext validateIntegrity(
      Insertable<ProductOptionGroupRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('option_group_id')) {
      context.handle(
          _optionGroupIdMeta,
          optionGroupId.isAcceptableOrUnknown(
              data['option_group_id']!, _optionGroupIdMeta));
    } else if (isInserting) {
      context.missing(_optionGroupIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('is_required')) {
      context.handle(
          _isRequiredMeta,
          isRequired.isAcceptableOrUnknown(
              data['is_required']!, _isRequiredMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductOptionGroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductOptionGroupRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      optionGroupId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}option_group_id'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      isRequired: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_required']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ProductOptionGroupsTable createAlias(String alias) {
    return $ProductOptionGroupsTable(attachedDatabase, alias);
  }
}

class ProductOptionGroupRow extends DataClass
    implements Insertable<ProductOptionGroupRow> {
  final String id;
  final String productId;
  final String optionGroupId;
  final int sortOrder;
  final bool? isRequired;
  final DateTime updatedAt;
  const ProductOptionGroupRow(
      {required this.id,
      required this.productId,
      required this.optionGroupId,
      required this.sortOrder,
      this.isRequired,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['option_group_id'] = Variable<String>(optionGroupId);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || isRequired != null) {
      map['is_required'] = Variable<bool>(isRequired);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProductOptionGroupsCompanion toCompanion(bool nullToAbsent) {
    return ProductOptionGroupsCompanion(
      id: Value(id),
      productId: Value(productId),
      optionGroupId: Value(optionGroupId),
      sortOrder: Value(sortOrder),
      isRequired: isRequired == null && nullToAbsent
          ? const Value.absent()
          : Value(isRequired),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProductOptionGroupRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductOptionGroupRow(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      optionGroupId: serializer.fromJson<String>(json['optionGroupId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isRequired: serializer.fromJson<bool?>(json['isRequired']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'optionGroupId': serializer.toJson<String>(optionGroupId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isRequired': serializer.toJson<bool?>(isRequired),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProductOptionGroupRow copyWith(
          {String? id,
          String? productId,
          String? optionGroupId,
          int? sortOrder,
          Value<bool?> isRequired = const Value.absent(),
          DateTime? updatedAt}) =>
      ProductOptionGroupRow(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        optionGroupId: optionGroupId ?? this.optionGroupId,
        sortOrder: sortOrder ?? this.sortOrder,
        isRequired: isRequired.present ? isRequired.value : this.isRequired,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ProductOptionGroupRow copyWithCompanion(ProductOptionGroupsCompanion data) {
    return ProductOptionGroupRow(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      optionGroupId: data.optionGroupId.present
          ? data.optionGroupId.value
          : this.optionGroupId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isRequired:
          data.isRequired.present ? data.isRequired.value : this.isRequired,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductOptionGroupRow(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('optionGroupId: $optionGroupId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isRequired: $isRequired, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, productId, optionGroupId, sortOrder, isRequired, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductOptionGroupRow &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.optionGroupId == this.optionGroupId &&
          other.sortOrder == this.sortOrder &&
          other.isRequired == this.isRequired &&
          other.updatedAt == this.updatedAt);
}

class ProductOptionGroupsCompanion
    extends UpdateCompanion<ProductOptionGroupRow> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String> optionGroupId;
  final Value<int> sortOrder;
  final Value<bool?> isRequired;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProductOptionGroupsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.optionGroupId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isRequired = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductOptionGroupsCompanion.insert({
    required String id,
    required String productId,
    required String optionGroupId,
    this.sortOrder = const Value.absent(),
    this.isRequired = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        productId = Value(productId),
        optionGroupId = Value(optionGroupId),
        updatedAt = Value(updatedAt);
  static Insertable<ProductOptionGroupRow> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? optionGroupId,
    Expression<int>? sortOrder,
    Expression<bool>? isRequired,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (optionGroupId != null) 'option_group_id': optionGroupId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isRequired != null) 'is_required': isRequired,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductOptionGroupsCompanion copyWith(
      {Value<String>? id,
      Value<String>? productId,
      Value<String>? optionGroupId,
      Value<int>? sortOrder,
      Value<bool?>? isRequired,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ProductOptionGroupsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      optionGroupId: optionGroupId ?? this.optionGroupId,
      sortOrder: sortOrder ?? this.sortOrder,
      isRequired: isRequired ?? this.isRequired,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (optionGroupId.present) {
      map['option_group_id'] = Variable<String>(optionGroupId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isRequired.present) {
      map['is_required'] = Variable<bool>(isRequired.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductOptionGroupsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('optionGroupId: $optionGroupId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isRequired: $isRequired, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductOptionChoiceOverridesTable extends ProductOptionChoiceOverrides
    with
        TableInfo<$ProductOptionChoiceOverridesTable,
            ProductOptionChoiceOverrideRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductOptionChoiceOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _optionChoiceIdMeta =
      const VerificationMeta('optionChoiceId');
  @override
  late final GeneratedColumn<String> optionChoiceId = GeneratedColumn<String>(
      'option_choice_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES option_choices (id)'));
  static const VerificationMeta _priceDeltaCentsMeta =
      const VerificationMeta('priceDeltaCents');
  @override
  late final GeneratedColumn<int> priceDeltaCents = GeneratedColumn<int>(
      'price_delta_cents', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isHiddenMeta =
      const VerificationMeta('isHidden');
  @override
  late final GeneratedColumn<bool> isHidden = GeneratedColumn<bool>(
      'is_hidden', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_hidden" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, productId, optionChoiceId, priceDeltaCents, isHidden, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_option_choice_overrides';
  @override
  VerificationContext validateIntegrity(
      Insertable<ProductOptionChoiceOverrideRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('option_choice_id')) {
      context.handle(
          _optionChoiceIdMeta,
          optionChoiceId.isAcceptableOrUnknown(
              data['option_choice_id']!, _optionChoiceIdMeta));
    } else if (isInserting) {
      context.missing(_optionChoiceIdMeta);
    }
    if (data.containsKey('price_delta_cents')) {
      context.handle(
          _priceDeltaCentsMeta,
          priceDeltaCents.isAcceptableOrUnknown(
              data['price_delta_cents']!, _priceDeltaCentsMeta));
    }
    if (data.containsKey('is_hidden')) {
      context.handle(_isHiddenMeta,
          isHidden.isAcceptableOrUnknown(data['is_hidden']!, _isHiddenMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductOptionChoiceOverrideRow map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductOptionChoiceOverrideRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      optionChoiceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}option_choice_id'])!,
      priceDeltaCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}price_delta_cents']),
      isHidden: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_hidden'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ProductOptionChoiceOverridesTable createAlias(String alias) {
    return $ProductOptionChoiceOverridesTable(attachedDatabase, alias);
  }
}

class ProductOptionChoiceOverrideRow extends DataClass
    implements Insertable<ProductOptionChoiceOverrideRow> {
  final String id;
  final String productId;
  final String optionChoiceId;
  final int? priceDeltaCents;
  final bool isHidden;
  final DateTime updatedAt;
  const ProductOptionChoiceOverrideRow(
      {required this.id,
      required this.productId,
      required this.optionChoiceId,
      this.priceDeltaCents,
      required this.isHidden,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['option_choice_id'] = Variable<String>(optionChoiceId);
    if (!nullToAbsent || priceDeltaCents != null) {
      map['price_delta_cents'] = Variable<int>(priceDeltaCents);
    }
    map['is_hidden'] = Variable<bool>(isHidden);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProductOptionChoiceOverridesCompanion toCompanion(bool nullToAbsent) {
    return ProductOptionChoiceOverridesCompanion(
      id: Value(id),
      productId: Value(productId),
      optionChoiceId: Value(optionChoiceId),
      priceDeltaCents: priceDeltaCents == null && nullToAbsent
          ? const Value.absent()
          : Value(priceDeltaCents),
      isHidden: Value(isHidden),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProductOptionChoiceOverrideRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductOptionChoiceOverrideRow(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      optionChoiceId: serializer.fromJson<String>(json['optionChoiceId']),
      priceDeltaCents: serializer.fromJson<int?>(json['priceDeltaCents']),
      isHidden: serializer.fromJson<bool>(json['isHidden']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'optionChoiceId': serializer.toJson<String>(optionChoiceId),
      'priceDeltaCents': serializer.toJson<int?>(priceDeltaCents),
      'isHidden': serializer.toJson<bool>(isHidden),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProductOptionChoiceOverrideRow copyWith(
          {String? id,
          String? productId,
          String? optionChoiceId,
          Value<int?> priceDeltaCents = const Value.absent(),
          bool? isHidden,
          DateTime? updatedAt}) =>
      ProductOptionChoiceOverrideRow(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        optionChoiceId: optionChoiceId ?? this.optionChoiceId,
        priceDeltaCents: priceDeltaCents.present
            ? priceDeltaCents.value
            : this.priceDeltaCents,
        isHidden: isHidden ?? this.isHidden,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ProductOptionChoiceOverrideRow copyWithCompanion(
      ProductOptionChoiceOverridesCompanion data) {
    return ProductOptionChoiceOverrideRow(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      optionChoiceId: data.optionChoiceId.present
          ? data.optionChoiceId.value
          : this.optionChoiceId,
      priceDeltaCents: data.priceDeltaCents.present
          ? data.priceDeltaCents.value
          : this.priceDeltaCents,
      isHidden: data.isHidden.present ? data.isHidden.value : this.isHidden,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductOptionChoiceOverrideRow(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('optionChoiceId: $optionChoiceId, ')
          ..write('priceDeltaCents: $priceDeltaCents, ')
          ..write('isHidden: $isHidden, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, productId, optionChoiceId, priceDeltaCents, isHidden, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductOptionChoiceOverrideRow &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.optionChoiceId == this.optionChoiceId &&
          other.priceDeltaCents == this.priceDeltaCents &&
          other.isHidden == this.isHidden &&
          other.updatedAt == this.updatedAt);
}

class ProductOptionChoiceOverridesCompanion
    extends UpdateCompanion<ProductOptionChoiceOverrideRow> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String> optionChoiceId;
  final Value<int?> priceDeltaCents;
  final Value<bool> isHidden;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProductOptionChoiceOverridesCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.optionChoiceId = const Value.absent(),
    this.priceDeltaCents = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductOptionChoiceOverridesCompanion.insert({
    required String id,
    required String productId,
    required String optionChoiceId,
    this.priceDeltaCents = const Value.absent(),
    this.isHidden = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        productId = Value(productId),
        optionChoiceId = Value(optionChoiceId),
        updatedAt = Value(updatedAt);
  static Insertable<ProductOptionChoiceOverrideRow> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? optionChoiceId,
    Expression<int>? priceDeltaCents,
    Expression<bool>? isHidden,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (optionChoiceId != null) 'option_choice_id': optionChoiceId,
      if (priceDeltaCents != null) 'price_delta_cents': priceDeltaCents,
      if (isHidden != null) 'is_hidden': isHidden,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductOptionChoiceOverridesCompanion copyWith(
      {Value<String>? id,
      Value<String>? productId,
      Value<String>? optionChoiceId,
      Value<int?>? priceDeltaCents,
      Value<bool>? isHidden,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ProductOptionChoiceOverridesCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      optionChoiceId: optionChoiceId ?? this.optionChoiceId,
      priceDeltaCents: priceDeltaCents ?? this.priceDeltaCents,
      isHidden: isHidden ?? this.isHidden,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (optionChoiceId.present) {
      map['option_choice_id'] = Variable<String>(optionChoiceId.value);
    }
    if (priceDeltaCents.present) {
      map['price_delta_cents'] = Variable<int>(priceDeltaCents.value);
    }
    if (isHidden.present) {
      map['is_hidden'] = Variable<bool>(isHidden.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductOptionChoiceOverridesCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('optionChoiceId: $optionChoiceId, ')
          ..write('priceDeltaCents: $priceDeltaCents, ')
          ..write('isHidden: $isHidden, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemberLevelsTable extends MemberLevels
    with TableInfo<$MemberLevelsTable, MemberLevelRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemberLevelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _discountRateMeta =
      const VerificationMeta('discountRate');
  @override
  late final GeneratedColumn<double> discountRate = GeneratedColumn<double>(
      'discount_rate', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.0));
  static const VerificationMeta _minSpendMeta =
      const VerificationMeta('minSpend');
  @override
  late final GeneratedColumn<int> minSpend = GeneratedColumn<int>(
      'min_spend', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _minPointsMeta =
      const VerificationMeta('minPoints');
  @override
  late final GeneratedColumn<int> minPoints = GeneratedColumn<int>(
      'min_points', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        discountRate,
        minSpend,
        minPoints,
        color,
        sortOrder,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'member_levels';
  @override
  VerificationContext validateIntegrity(Insertable<MemberLevelRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('discount_rate')) {
      context.handle(
          _discountRateMeta,
          discountRate.isAcceptableOrUnknown(
              data['discount_rate']!, _discountRateMeta));
    }
    if (data.containsKey('min_spend')) {
      context.handle(_minSpendMeta,
          minSpend.isAcceptableOrUnknown(data['min_spend']!, _minSpendMeta));
    }
    if (data.containsKey('min_points')) {
      context.handle(_minPointsMeta,
          minPoints.isAcceptableOrUnknown(data['min_points']!, _minPointsMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemberLevelRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemberLevelRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      discountRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}discount_rate'])!,
      minSpend: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}min_spend'])!,
      minPoints: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}min_points'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $MemberLevelsTable createAlias(String alias) {
    return $MemberLevelsTable(attachedDatabase, alias);
  }
}

class MemberLevelRow extends DataClass implements Insertable<MemberLevelRow> {
  final String id;
  final String name;
  final double discountRate;
  final int minSpend;
  final int minPoints;
  final String? color;
  final int sortOrder;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const MemberLevelRow(
      {required this.id,
      required this.name,
      required this.discountRate,
      required this.minSpend,
      required this.minPoints,
      this.color,
      required this.sortOrder,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['discount_rate'] = Variable<double>(discountRate);
    map['min_spend'] = Variable<int>(minSpend);
    map['min_points'] = Variable<int>(minPoints);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  MemberLevelsCompanion toCompanion(bool nullToAbsent) {
    return MemberLevelsCompanion(
      id: Value(id),
      name: Value(name),
      discountRate: Value(discountRate),
      minSpend: Value(minSpend),
      minPoints: Value(minPoints),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      sortOrder: Value(sortOrder),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory MemberLevelRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemberLevelRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      discountRate: serializer.fromJson<double>(json['discountRate']),
      minSpend: serializer.fromJson<int>(json['minSpend']),
      minPoints: serializer.fromJson<int>(json['minPoints']),
      color: serializer.fromJson<String?>(json['color']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'discountRate': serializer.toJson<double>(discountRate),
      'minSpend': serializer.toJson<int>(minSpend),
      'minPoints': serializer.toJson<int>(minPoints),
      'color': serializer.toJson<String?>(color),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  MemberLevelRow copyWith(
          {String? id,
          String? name,
          double? discountRate,
          int? minSpend,
          int? minPoints,
          Value<String?> color = const Value.absent(),
          int? sortOrder,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      MemberLevelRow(
        id: id ?? this.id,
        name: name ?? this.name,
        discountRate: discountRate ?? this.discountRate,
        minSpend: minSpend ?? this.minSpend,
        minPoints: minPoints ?? this.minPoints,
        color: color.present ? color.value : this.color,
        sortOrder: sortOrder ?? this.sortOrder,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  MemberLevelRow copyWithCompanion(MemberLevelsCompanion data) {
    return MemberLevelRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      discountRate: data.discountRate.present
          ? data.discountRate.value
          : this.discountRate,
      minSpend: data.minSpend.present ? data.minSpend.value : this.minSpend,
      minPoints: data.minPoints.present ? data.minPoints.value : this.minPoints,
      color: data.color.present ? data.color.value : this.color,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemberLevelRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('discountRate: $discountRate, ')
          ..write('minSpend: $minSpend, ')
          ..write('minPoints: $minPoints, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, discountRate, minSpend, minPoints,
      color, sortOrder, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemberLevelRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.discountRate == this.discountRate &&
          other.minSpend == this.minSpend &&
          other.minPoints == this.minPoints &&
          other.color == this.color &&
          other.sortOrder == this.sortOrder &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class MemberLevelsCompanion extends UpdateCompanion<MemberLevelRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> discountRate;
  final Value<int> minSpend;
  final Value<int> minPoints;
  final Value<String?> color;
  final Value<int> sortOrder;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const MemberLevelsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.discountRate = const Value.absent(),
    this.minSpend = const Value.absent(),
    this.minPoints = const Value.absent(),
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemberLevelsCompanion.insert({
    required String id,
    required String name,
    this.discountRate = const Value.absent(),
    this.minSpend = const Value.absent(),
    this.minPoints = const Value.absent(),
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        updatedAt = Value(updatedAt);
  static Insertable<MemberLevelRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? discountRate,
    Expression<int>? minSpend,
    Expression<int>? minPoints,
    Expression<String>? color,
    Expression<int>? sortOrder,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (discountRate != null) 'discount_rate': discountRate,
      if (minSpend != null) 'min_spend': minSpend,
      if (minPoints != null) 'min_points': minPoints,
      if (color != null) 'color': color,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemberLevelsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<double>? discountRate,
      Value<int>? minSpend,
      Value<int>? minPoints,
      Value<String?>? color,
      Value<int>? sortOrder,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return MemberLevelsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      discountRate: discountRate ?? this.discountRate,
      minSpend: minSpend ?? this.minSpend,
      minPoints: minPoints ?? this.minPoints,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (discountRate.present) {
      map['discount_rate'] = Variable<double>(discountRate.value);
    }
    if (minSpend.present) {
      map['min_spend'] = Variable<int>(minSpend.value);
    }
    if (minPoints.present) {
      map['min_points'] = Variable<int>(minPoints.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemberLevelsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('discountRate: $discountRate, ')
          ..write('minSpend: $minSpend, ')
          ..write('minPoints: $minPoints, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MembersTable extends Members with TableInfo<$MembersTable, MemberRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _birthdayMeta =
      const VerificationMeta('birthday');
  @override
  late final GeneratedColumn<DateTime> birthday = GeneratedColumn<DateTime>(
      'birthday', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<int> points = GeneratedColumn<int>(
      'points', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalSpentCentsMeta =
      const VerificationMeta('totalSpentCents');
  @override
  late final GeneratedColumn<int> totalSpentCents = GeneratedColumn<int>(
      'total_spent_cents', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _levelIdMeta =
      const VerificationMeta('levelId');
  @override
  late final GeneratedColumn<String> levelId = GeneratedColumn<String>(
      'level_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _qrCodeMeta = const VerificationMeta('qrCode');
  @override
  late final GeneratedColumn<String> qrCode = GeneratedColumn<String>(
      'qr_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _joinedAtMeta =
      const VerificationMeta('joinedAt');
  @override
  late final GeneratedColumn<DateTime> joinedAt = GeneratedColumn<DateTime>(
      'joined_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastVisitAtMeta =
      const VerificationMeta('lastVisitAt');
  @override
  late final GeneratedColumn<DateTime> lastVisitAt = GeneratedColumn<DateTime>(
      'last_visit_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        phone,
        name,
        email,
        birthday,
        points,
        totalSpentCents,
        levelId,
        qrCode,
        joinedAt,
        lastVisitAt,
        note,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'members';
  @override
  VerificationContext validateIntegrity(Insertable<MemberRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('birthday')) {
      context.handle(_birthdayMeta,
          birthday.isAcceptableOrUnknown(data['birthday']!, _birthdayMeta));
    }
    if (data.containsKey('points')) {
      context.handle(_pointsMeta,
          points.isAcceptableOrUnknown(data['points']!, _pointsMeta));
    }
    if (data.containsKey('total_spent_cents')) {
      context.handle(
          _totalSpentCentsMeta,
          totalSpentCents.isAcceptableOrUnknown(
              data['total_spent_cents']!, _totalSpentCentsMeta));
    }
    if (data.containsKey('level_id')) {
      context.handle(_levelIdMeta,
          levelId.isAcceptableOrUnknown(data['level_id']!, _levelIdMeta));
    }
    if (data.containsKey('qr_code')) {
      context.handle(_qrCodeMeta,
          qrCode.isAcceptableOrUnknown(data['qr_code']!, _qrCodeMeta));
    }
    if (data.containsKey('joined_at')) {
      context.handle(_joinedAtMeta,
          joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta));
    } else if (isInserting) {
      context.missing(_joinedAtMeta);
    }
    if (data.containsKey('last_visit_at')) {
      context.handle(
          _lastVisitAtMeta,
          lastVisitAt.isAcceptableOrUnknown(
              data['last_visit_at']!, _lastVisitAtMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemberRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemberRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      birthday: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}birthday']),
      points: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}points'])!,
      totalSpentCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_spent_cents'])!,
      levelId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}level_id']),
      qrCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}qr_code']),
      joinedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}joined_at'])!,
      lastVisitAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_visit_at']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $MembersTable createAlias(String alias) {
    return $MembersTable(attachedDatabase, alias);
  }
}

class MemberRow extends DataClass implements Insertable<MemberRow> {
  final String id;
  final String phone;
  final String name;
  final String? email;
  final DateTime? birthday;
  final int points;
  final int totalSpentCents;
  final String? levelId;
  final String? qrCode;
  final DateTime joinedAt;
  final DateTime? lastVisitAt;
  final String? note;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const MemberRow(
      {required this.id,
      required this.phone,
      required this.name,
      this.email,
      this.birthday,
      required this.points,
      required this.totalSpentCents,
      this.levelId,
      this.qrCode,
      required this.joinedAt,
      this.lastVisitAt,
      this.note,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['phone'] = Variable<String>(phone);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || birthday != null) {
      map['birthday'] = Variable<DateTime>(birthday);
    }
    map['points'] = Variable<int>(points);
    map['total_spent_cents'] = Variable<int>(totalSpentCents);
    if (!nullToAbsent || levelId != null) {
      map['level_id'] = Variable<String>(levelId);
    }
    if (!nullToAbsent || qrCode != null) {
      map['qr_code'] = Variable<String>(qrCode);
    }
    map['joined_at'] = Variable<DateTime>(joinedAt);
    if (!nullToAbsent || lastVisitAt != null) {
      map['last_visit_at'] = Variable<DateTime>(lastVisitAt);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  MembersCompanion toCompanion(bool nullToAbsent) {
    return MembersCompanion(
      id: Value(id),
      phone: Value(phone),
      name: Value(name),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      birthday: birthday == null && nullToAbsent
          ? const Value.absent()
          : Value(birthday),
      points: Value(points),
      totalSpentCents: Value(totalSpentCents),
      levelId: levelId == null && nullToAbsent
          ? const Value.absent()
          : Value(levelId),
      qrCode:
          qrCode == null && nullToAbsent ? const Value.absent() : Value(qrCode),
      joinedAt: Value(joinedAt),
      lastVisitAt: lastVisitAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastVisitAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory MemberRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemberRow(
      id: serializer.fromJson<String>(json['id']),
      phone: serializer.fromJson<String>(json['phone']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String?>(json['email']),
      birthday: serializer.fromJson<DateTime?>(json['birthday']),
      points: serializer.fromJson<int>(json['points']),
      totalSpentCents: serializer.fromJson<int>(json['totalSpentCents']),
      levelId: serializer.fromJson<String?>(json['levelId']),
      qrCode: serializer.fromJson<String?>(json['qrCode']),
      joinedAt: serializer.fromJson<DateTime>(json['joinedAt']),
      lastVisitAt: serializer.fromJson<DateTime?>(json['lastVisitAt']),
      note: serializer.fromJson<String?>(json['note']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'phone': serializer.toJson<String>(phone),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String?>(email),
      'birthday': serializer.toJson<DateTime?>(birthday),
      'points': serializer.toJson<int>(points),
      'totalSpentCents': serializer.toJson<int>(totalSpentCents),
      'levelId': serializer.toJson<String?>(levelId),
      'qrCode': serializer.toJson<String?>(qrCode),
      'joinedAt': serializer.toJson<DateTime>(joinedAt),
      'lastVisitAt': serializer.toJson<DateTime?>(lastVisitAt),
      'note': serializer.toJson<String?>(note),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  MemberRow copyWith(
          {String? id,
          String? phone,
          String? name,
          Value<String?> email = const Value.absent(),
          Value<DateTime?> birthday = const Value.absent(),
          int? points,
          int? totalSpentCents,
          Value<String?> levelId = const Value.absent(),
          Value<String?> qrCode = const Value.absent(),
          DateTime? joinedAt,
          Value<DateTime?> lastVisitAt = const Value.absent(),
          Value<String?> note = const Value.absent(),
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      MemberRow(
        id: id ?? this.id,
        phone: phone ?? this.phone,
        name: name ?? this.name,
        email: email.present ? email.value : this.email,
        birthday: birthday.present ? birthday.value : this.birthday,
        points: points ?? this.points,
        totalSpentCents: totalSpentCents ?? this.totalSpentCents,
        levelId: levelId.present ? levelId.value : this.levelId,
        qrCode: qrCode.present ? qrCode.value : this.qrCode,
        joinedAt: joinedAt ?? this.joinedAt,
        lastVisitAt: lastVisitAt.present ? lastVisitAt.value : this.lastVisitAt,
        note: note.present ? note.value : this.note,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  MemberRow copyWithCompanion(MembersCompanion data) {
    return MemberRow(
      id: data.id.present ? data.id.value : this.id,
      phone: data.phone.present ? data.phone.value : this.phone,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      birthday: data.birthday.present ? data.birthday.value : this.birthday,
      points: data.points.present ? data.points.value : this.points,
      totalSpentCents: data.totalSpentCents.present
          ? data.totalSpentCents.value
          : this.totalSpentCents,
      levelId: data.levelId.present ? data.levelId.value : this.levelId,
      qrCode: data.qrCode.present ? data.qrCode.value : this.qrCode,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
      lastVisitAt:
          data.lastVisitAt.present ? data.lastVisitAt.value : this.lastVisitAt,
      note: data.note.present ? data.note.value : this.note,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemberRow(')
          ..write('id: $id, ')
          ..write('phone: $phone, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('birthday: $birthday, ')
          ..write('points: $points, ')
          ..write('totalSpentCents: $totalSpentCents, ')
          ..write('levelId: $levelId, ')
          ..write('qrCode: $qrCode, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('lastVisitAt: $lastVisitAt, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      phone,
      name,
      email,
      birthday,
      points,
      totalSpentCents,
      levelId,
      qrCode,
      joinedAt,
      lastVisitAt,
      note,
      updatedAt,
      deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemberRow &&
          other.id == this.id &&
          other.phone == this.phone &&
          other.name == this.name &&
          other.email == this.email &&
          other.birthday == this.birthday &&
          other.points == this.points &&
          other.totalSpentCents == this.totalSpentCents &&
          other.levelId == this.levelId &&
          other.qrCode == this.qrCode &&
          other.joinedAt == this.joinedAt &&
          other.lastVisitAt == this.lastVisitAt &&
          other.note == this.note &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class MembersCompanion extends UpdateCompanion<MemberRow> {
  final Value<String> id;
  final Value<String> phone;
  final Value<String> name;
  final Value<String?> email;
  final Value<DateTime?> birthday;
  final Value<int> points;
  final Value<int> totalSpentCents;
  final Value<String?> levelId;
  final Value<String?> qrCode;
  final Value<DateTime> joinedAt;
  final Value<DateTime?> lastVisitAt;
  final Value<String?> note;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const MembersCompanion({
    this.id = const Value.absent(),
    this.phone = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.birthday = const Value.absent(),
    this.points = const Value.absent(),
    this.totalSpentCents = const Value.absent(),
    this.levelId = const Value.absent(),
    this.qrCode = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.lastVisitAt = const Value.absent(),
    this.note = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MembersCompanion.insert({
    required String id,
    required String phone,
    required String name,
    this.email = const Value.absent(),
    this.birthday = const Value.absent(),
    this.points = const Value.absent(),
    this.totalSpentCents = const Value.absent(),
    this.levelId = const Value.absent(),
    this.qrCode = const Value.absent(),
    required DateTime joinedAt,
    this.lastVisitAt = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        phone = Value(phone),
        name = Value(name),
        joinedAt = Value(joinedAt),
        updatedAt = Value(updatedAt);
  static Insertable<MemberRow> custom({
    Expression<String>? id,
    Expression<String>? phone,
    Expression<String>? name,
    Expression<String>? email,
    Expression<DateTime>? birthday,
    Expression<int>? points,
    Expression<int>? totalSpentCents,
    Expression<String>? levelId,
    Expression<String>? qrCode,
    Expression<DateTime>? joinedAt,
    Expression<DateTime>? lastVisitAt,
    Expression<String>? note,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (phone != null) 'phone': phone,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (birthday != null) 'birthday': birthday,
      if (points != null) 'points': points,
      if (totalSpentCents != null) 'total_spent_cents': totalSpentCents,
      if (levelId != null) 'level_id': levelId,
      if (qrCode != null) 'qr_code': qrCode,
      if (joinedAt != null) 'joined_at': joinedAt,
      if (lastVisitAt != null) 'last_visit_at': lastVisitAt,
      if (note != null) 'note': note,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MembersCompanion copyWith(
      {Value<String>? id,
      Value<String>? phone,
      Value<String>? name,
      Value<String?>? email,
      Value<DateTime?>? birthday,
      Value<int>? points,
      Value<int>? totalSpentCents,
      Value<String?>? levelId,
      Value<String?>? qrCode,
      Value<DateTime>? joinedAt,
      Value<DateTime?>? lastVisitAt,
      Value<String?>? note,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return MembersCompanion(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      birthday: birthday ?? this.birthday,
      points: points ?? this.points,
      totalSpentCents: totalSpentCents ?? this.totalSpentCents,
      levelId: levelId ?? this.levelId,
      qrCode: qrCode ?? this.qrCode,
      joinedAt: joinedAt ?? this.joinedAt,
      lastVisitAt: lastVisitAt ?? this.lastVisitAt,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (birthday.present) {
      map['birthday'] = Variable<DateTime>(birthday.value);
    }
    if (points.present) {
      map['points'] = Variable<int>(points.value);
    }
    if (totalSpentCents.present) {
      map['total_spent_cents'] = Variable<int>(totalSpentCents.value);
    }
    if (levelId.present) {
      map['level_id'] = Variable<String>(levelId.value);
    }
    if (qrCode.present) {
      map['qr_code'] = Variable<String>(qrCode.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<DateTime>(joinedAt.value);
    }
    if (lastVisitAt.present) {
      map['last_visit_at'] = Variable<DateTime>(lastVisitAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembersCompanion(')
          ..write('id: $id, ')
          ..write('phone: $phone, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('birthday: $birthday, ')
          ..write('points: $points, ')
          ..write('totalSpentCents: $totalSpentCents, ')
          ..write('levelId: $levelId, ')
          ..write('qrCode: $qrCode, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('lastVisitAt: $lastVisitAt, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CouponsTable extends Coupons with TableInfo<$CouponsTable, CouponRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CouponsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
      'value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _memberIdMeta =
      const VerificationMeta('memberId');
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
      'member_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _minSpendCentsMeta =
      const VerificationMeta('minSpendCents');
  @override
  late final GeneratedColumn<int> minSpendCents = GeneratedColumn<int>(
      'min_spend_cents', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
      'expires_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _usedAtMeta = const VerificationMeta('usedAt');
  @override
  late final GeneratedColumn<DateTime> usedAt = GeneratedColumn<DateTime>(
      'used_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        code,
        type,
        value,
        memberId,
        minSpendCents,
        expiresAt,
        usedAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'coupons';
  @override
  VerificationContext validateIntegrity(Insertable<CouponRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(_memberIdMeta,
          memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta));
    }
    if (data.containsKey('min_spend_cents')) {
      context.handle(
          _minSpendCentsMeta,
          minSpendCents.isAcceptableOrUnknown(
              data['min_spend_cents']!, _minSpendCentsMeta));
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    }
    if (data.containsKey('used_at')) {
      context.handle(_usedAtMeta,
          usedAt.isAcceptableOrUnknown(data['used_at']!, _usedAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CouponRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CouponRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value'])!,
      memberId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}member_id']),
      minSpendCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}min_spend_cents'])!,
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expires_at']),
      usedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}used_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CouponsTable createAlias(String alias) {
    return $CouponsTable(attachedDatabase, alias);
  }
}

class CouponRow extends DataClass implements Insertable<CouponRow> {
  final String id;
  final String code;
  final String type;
  final double value;
  final String? memberId;
  final int minSpendCents;
  final DateTime? expiresAt;
  final DateTime? usedAt;
  final DateTime updatedAt;
  const CouponRow(
      {required this.id,
      required this.code,
      required this.type,
      required this.value,
      this.memberId,
      required this.minSpendCents,
      this.expiresAt,
      this.usedAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['type'] = Variable<String>(type);
    map['value'] = Variable<double>(value);
    if (!nullToAbsent || memberId != null) {
      map['member_id'] = Variable<String>(memberId);
    }
    map['min_spend_cents'] = Variable<int>(minSpendCents);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    if (!nullToAbsent || usedAt != null) {
      map['used_at'] = Variable<DateTime>(usedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CouponsCompanion toCompanion(bool nullToAbsent) {
    return CouponsCompanion(
      id: Value(id),
      code: Value(code),
      type: Value(type),
      value: Value(value),
      memberId: memberId == null && nullToAbsent
          ? const Value.absent()
          : Value(memberId),
      minSpendCents: Value(minSpendCents),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      usedAt:
          usedAt == null && nullToAbsent ? const Value.absent() : Value(usedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CouponRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CouponRow(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      type: serializer.fromJson<String>(json['type']),
      value: serializer.fromJson<double>(json['value']),
      memberId: serializer.fromJson<String?>(json['memberId']),
      minSpendCents: serializer.fromJson<int>(json['minSpendCents']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      usedAt: serializer.fromJson<DateTime?>(json['usedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'type': serializer.toJson<String>(type),
      'value': serializer.toJson<double>(value),
      'memberId': serializer.toJson<String?>(memberId),
      'minSpendCents': serializer.toJson<int>(minSpendCents),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'usedAt': serializer.toJson<DateTime?>(usedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CouponRow copyWith(
          {String? id,
          String? code,
          String? type,
          double? value,
          Value<String?> memberId = const Value.absent(),
          int? minSpendCents,
          Value<DateTime?> expiresAt = const Value.absent(),
          Value<DateTime?> usedAt = const Value.absent(),
          DateTime? updatedAt}) =>
      CouponRow(
        id: id ?? this.id,
        code: code ?? this.code,
        type: type ?? this.type,
        value: value ?? this.value,
        memberId: memberId.present ? memberId.value : this.memberId,
        minSpendCents: minSpendCents ?? this.minSpendCents,
        expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
        usedAt: usedAt.present ? usedAt.value : this.usedAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CouponRow copyWithCompanion(CouponsCompanion data) {
    return CouponRow(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      type: data.type.present ? data.type.value : this.type,
      value: data.value.present ? data.value.value : this.value,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      minSpendCents: data.minSpendCents.present
          ? data.minSpendCents.value
          : this.minSpendCents,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      usedAt: data.usedAt.present ? data.usedAt.value : this.usedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CouponRow(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('type: $type, ')
          ..write('value: $value, ')
          ..write('memberId: $memberId, ')
          ..write('minSpendCents: $minSpendCents, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('usedAt: $usedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, code, type, value, memberId,
      minSpendCents, expiresAt, usedAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CouponRow &&
          other.id == this.id &&
          other.code == this.code &&
          other.type == this.type &&
          other.value == this.value &&
          other.memberId == this.memberId &&
          other.minSpendCents == this.minSpendCents &&
          other.expiresAt == this.expiresAt &&
          other.usedAt == this.usedAt &&
          other.updatedAt == this.updatedAt);
}

class CouponsCompanion extends UpdateCompanion<CouponRow> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> type;
  final Value<double> value;
  final Value<String?> memberId;
  final Value<int> minSpendCents;
  final Value<DateTime?> expiresAt;
  final Value<DateTime?> usedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CouponsCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.type = const Value.absent(),
    this.value = const Value.absent(),
    this.memberId = const Value.absent(),
    this.minSpendCents = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.usedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CouponsCompanion.insert({
    required String id,
    required String code,
    required String type,
    required double value,
    this.memberId = const Value.absent(),
    this.minSpendCents = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.usedAt = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        code = Value(code),
        type = Value(type),
        value = Value(value),
        updatedAt = Value(updatedAt);
  static Insertable<CouponRow> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? type,
    Expression<double>? value,
    Expression<String>? memberId,
    Expression<int>? minSpendCents,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? usedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (type != null) 'type': type,
      if (value != null) 'value': value,
      if (memberId != null) 'member_id': memberId,
      if (minSpendCents != null) 'min_spend_cents': minSpendCents,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (usedAt != null) 'used_at': usedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CouponsCompanion copyWith(
      {Value<String>? id,
      Value<String>? code,
      Value<String>? type,
      Value<double>? value,
      Value<String?>? memberId,
      Value<int>? minSpendCents,
      Value<DateTime?>? expiresAt,
      Value<DateTime?>? usedAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return CouponsCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      type: type ?? this.type,
      value: value ?? this.value,
      memberId: memberId ?? this.memberId,
      minSpendCents: minSpendCents ?? this.minSpendCents,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt ?? this.usedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (minSpendCents.present) {
      map['min_spend_cents'] = Variable<int>(minSpendCents.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (usedAt.present) {
      map['used_at'] = Variable<DateTime>(usedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CouponsCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('type: $type, ')
          ..write('value: $value, ')
          ..write('memberId: $memberId, ')
          ..write('minSpendCents: $minSpendCents, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('usedAt: $usedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PointTransactionsTable extends PointTransactions
    with TableInfo<$PointTransactionsTable, PointTransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PointTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _memberIdMeta =
      const VerificationMeta('memberId');
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
      'member_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deltaMeta = const VerificationMeta('delta');
  @override
  late final GeneratedColumn<int> delta = GeneratedColumn<int>(
      'delta', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderIdMeta =
      const VerificationMeta('orderId');
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
      'order_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
      'expires_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, memberId, delta, reason, orderId, expiresAt, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'point_transactions';
  @override
  VerificationContext validateIntegrity(
      Insertable<PointTransactionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(_memberIdMeta,
          memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta));
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('delta')) {
      context.handle(
          _deltaMeta, delta.isAcceptableOrUnknown(data['delta']!, _deltaMeta));
    } else if (isInserting) {
      context.missing(_deltaMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('order_id')) {
      context.handle(_orderIdMeta,
          orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta));
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PointTransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PointTransactionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      memberId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}member_id'])!,
      delta: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}delta'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason'])!,
      orderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_id']),
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expires_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PointTransactionsTable createAlias(String alias) {
    return $PointTransactionsTable(attachedDatabase, alias);
  }
}

class PointTransactionRow extends DataClass
    implements Insertable<PointTransactionRow> {
  final String id;
  final String memberId;
  final int delta;
  final String reason;
  final String? orderId;
  final DateTime? expiresAt;
  final DateTime createdAt;
  const PointTransactionRow(
      {required this.id,
      required this.memberId,
      required this.delta,
      required this.reason,
      this.orderId,
      this.expiresAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    map['delta'] = Variable<int>(delta);
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || orderId != null) {
      map['order_id'] = Variable<String>(orderId);
    }
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PointTransactionsCompanion toCompanion(bool nullToAbsent) {
    return PointTransactionsCompanion(
      id: Value(id),
      memberId: Value(memberId),
      delta: Value(delta),
      reason: Value(reason),
      orderId: orderId == null && nullToAbsent
          ? const Value.absent()
          : Value(orderId),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      createdAt: Value(createdAt),
    );
  }

  factory PointTransactionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PointTransactionRow(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['memberId']),
      delta: serializer.fromJson<int>(json['delta']),
      reason: serializer.fromJson<String>(json['reason']),
      orderId: serializer.fromJson<String?>(json['orderId']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'memberId': serializer.toJson<String>(memberId),
      'delta': serializer.toJson<int>(delta),
      'reason': serializer.toJson<String>(reason),
      'orderId': serializer.toJson<String?>(orderId),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PointTransactionRow copyWith(
          {String? id,
          String? memberId,
          int? delta,
          String? reason,
          Value<String?> orderId = const Value.absent(),
          Value<DateTime?> expiresAt = const Value.absent(),
          DateTime? createdAt}) =>
      PointTransactionRow(
        id: id ?? this.id,
        memberId: memberId ?? this.memberId,
        delta: delta ?? this.delta,
        reason: reason ?? this.reason,
        orderId: orderId.present ? orderId.value : this.orderId,
        expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
        createdAt: createdAt ?? this.createdAt,
      );
  PointTransactionRow copyWithCompanion(PointTransactionsCompanion data) {
    return PointTransactionRow(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      delta: data.delta.present ? data.delta.value : this.delta,
      reason: data.reason.present ? data.reason.value : this.reason,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PointTransactionRow(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('delta: $delta, ')
          ..write('reason: $reason, ')
          ..write('orderId: $orderId, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, memberId, delta, reason, orderId, expiresAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PointTransactionRow &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.delta == this.delta &&
          other.reason == this.reason &&
          other.orderId == this.orderId &&
          other.expiresAt == this.expiresAt &&
          other.createdAt == this.createdAt);
}

class PointTransactionsCompanion extends UpdateCompanion<PointTransactionRow> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<int> delta;
  final Value<String> reason;
  final Value<String?> orderId;
  final Value<DateTime?> expiresAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PointTransactionsCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.delta = const Value.absent(),
    this.reason = const Value.absent(),
    this.orderId = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PointTransactionsCompanion.insert({
    required String id,
    required String memberId,
    required int delta,
    required String reason,
    this.orderId = const Value.absent(),
    this.expiresAt = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        memberId = Value(memberId),
        delta = Value(delta),
        reason = Value(reason),
        createdAt = Value(createdAt);
  static Insertable<PointTransactionRow> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<int>? delta,
    Expression<String>? reason,
    Expression<String>? orderId,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (delta != null) 'delta': delta,
      if (reason != null) 'reason': reason,
      if (orderId != null) 'order_id': orderId,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PointTransactionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? memberId,
      Value<int>? delta,
      Value<String>? reason,
      Value<String?>? orderId,
      Value<DateTime?>? expiresAt,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return PointTransactionsCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      delta: delta ?? this.delta,
      reason: reason ?? this.reason,
      orderId: orderId ?? this.orderId,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (delta.present) {
      map['delta'] = Variable<int>(delta.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PointTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('delta: $delta, ')
          ..write('reason: $reason, ')
          ..write('orderId: $orderId, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrdersTable extends Orders with TableInfo<$OrdersTable, OrderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _storeIdMeta =
      const VerificationMeta('storeId');
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
      'store_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _terminalIdMeta =
      const VerificationMeta('terminalId');
  @override
  late final GeneratedColumn<String> terminalId = GeneratedColumn<String>(
      'terminal_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cashierIdMeta =
      const VerificationMeta('cashierId');
  @override
  late final GeneratedColumn<String> cashierId = GeneratedColumn<String>(
      'cashier_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _memberIdMeta =
      const VerificationMeta('memberId');
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
      'member_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('paid'));
  static const VerificationMeta _subtotalCentsMeta =
      const VerificationMeta('subtotalCents');
  @override
  late final GeneratedColumn<int> subtotalCents = GeneratedColumn<int>(
      'subtotal_cents', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _discountCentsMeta =
      const VerificationMeta('discountCents');
  @override
  late final GeneratedColumn<int> discountCents = GeneratedColumn<int>(
      'discount_cents', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _taxCentsMeta =
      const VerificationMeta('taxCents');
  @override
  late final GeneratedColumn<int> taxCents = GeneratedColumn<int>(
      'tax_cents', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalCentsMeta =
      const VerificationMeta('totalCents');
  @override
  late final GeneratedColumn<int> totalCents = GeneratedColumn<int>(
      'total_cents', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _refundedCentsMeta =
      const VerificationMeta('refundedCents');
  @override
  late final GeneratedColumn<int> refundedCents = GeneratedColumn<int>(
      'refunded_cents', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _invoiceNumberMeta =
      const VerificationMeta('invoiceNumber');
  @override
  late final GeneratedColumn<String> invoiceNumber = GeneratedColumn<String>(
      'invoice_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _invoiceCarrierMeta =
      const VerificationMeta('invoiceCarrier');
  @override
  late final GeneratedColumn<String> invoiceCarrier = GeneratedColumn<String>(
      'invoice_carrier', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _orderNoMeta =
      const VerificationMeta('orderNo');
  @override
  late final GeneratedColumn<String> orderNo = GeneratedColumn<String>(
      'order_no', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tableLabelMeta =
      const VerificationMeta('tableLabel');
  @override
  late final GeneratedColumn<String> tableLabel = GeneratedColumn<String>(
      'table_label', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _primaryPaymentMethodMeta =
      const VerificationMeta('primaryPaymentMethod');
  @override
  late final GeneratedColumn<String> primaryPaymentMethod =
      GeneratedColumn<String>('primary_payment_method', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceGuestOrderIdMeta =
      const VerificationMeta('sourceGuestOrderId');
  @override
  late final GeneratedColumn<String> sourceGuestOrderId =
      GeneratedColumn<String>('source_guest_order_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        storeId,
        terminalId,
        cashierId,
        memberId,
        status,
        subtotalCents,
        discountCents,
        taxCents,
        totalCents,
        refundedCents,
        invoiceNumber,
        invoiceCarrier,
        note,
        orderNo,
        tableLabel,
        primaryPaymentMethod,
        sourceGuestOrderId,
        createdAt,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orders';
  @override
  VerificationContext validateIntegrity(Insertable<OrderRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(_storeIdMeta,
          storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta));
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('terminal_id')) {
      context.handle(
          _terminalIdMeta,
          terminalId.isAcceptableOrUnknown(
              data['terminal_id']!, _terminalIdMeta));
    } else if (isInserting) {
      context.missing(_terminalIdMeta);
    }
    if (data.containsKey('cashier_id')) {
      context.handle(_cashierIdMeta,
          cashierId.isAcceptableOrUnknown(data['cashier_id']!, _cashierIdMeta));
    } else if (isInserting) {
      context.missing(_cashierIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(_memberIdMeta,
          memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('subtotal_cents')) {
      context.handle(
          _subtotalCentsMeta,
          subtotalCents.isAcceptableOrUnknown(
              data['subtotal_cents']!, _subtotalCentsMeta));
    }
    if (data.containsKey('discount_cents')) {
      context.handle(
          _discountCentsMeta,
          discountCents.isAcceptableOrUnknown(
              data['discount_cents']!, _discountCentsMeta));
    }
    if (data.containsKey('tax_cents')) {
      context.handle(_taxCentsMeta,
          taxCents.isAcceptableOrUnknown(data['tax_cents']!, _taxCentsMeta));
    }
    if (data.containsKey('total_cents')) {
      context.handle(
          _totalCentsMeta,
          totalCents.isAcceptableOrUnknown(
              data['total_cents']!, _totalCentsMeta));
    }
    if (data.containsKey('refunded_cents')) {
      context.handle(
          _refundedCentsMeta,
          refundedCents.isAcceptableOrUnknown(
              data['refunded_cents']!, _refundedCentsMeta));
    }
    if (data.containsKey('invoice_number')) {
      context.handle(
          _invoiceNumberMeta,
          invoiceNumber.isAcceptableOrUnknown(
              data['invoice_number']!, _invoiceNumberMeta));
    }
    if (data.containsKey('invoice_carrier')) {
      context.handle(
          _invoiceCarrierMeta,
          invoiceCarrier.isAcceptableOrUnknown(
              data['invoice_carrier']!, _invoiceCarrierMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('order_no')) {
      context.handle(_orderNoMeta,
          orderNo.isAcceptableOrUnknown(data['order_no']!, _orderNoMeta));
    }
    if (data.containsKey('table_label')) {
      context.handle(
          _tableLabelMeta,
          tableLabel.isAcceptableOrUnknown(
              data['table_label']!, _tableLabelMeta));
    }
    if (data.containsKey('primary_payment_method')) {
      context.handle(
          _primaryPaymentMethodMeta,
          primaryPaymentMethod.isAcceptableOrUnknown(
              data['primary_payment_method']!, _primaryPaymentMethodMeta));
    }
    if (data.containsKey('source_guest_order_id')) {
      context.handle(
          _sourceGuestOrderIdMeta,
          sourceGuestOrderId.isAcceptableOrUnknown(
              data['source_guest_order_id']!, _sourceGuestOrderIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      storeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}store_id'])!,
      terminalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}terminal_id'])!,
      cashierId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cashier_id'])!,
      memberId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}member_id']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      subtotalCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}subtotal_cents'])!,
      discountCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}discount_cents'])!,
      taxCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tax_cents'])!,
      totalCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_cents'])!,
      refundedCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}refunded_cents'])!,
      invoiceNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invoice_number']),
      invoiceCarrier: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invoice_carrier']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      orderNo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_no']),
      tableLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}table_label']),
      primaryPaymentMethod: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}primary_payment_method']),
      sourceGuestOrderId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_guest_order_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $OrdersTable createAlias(String alias) {
    return $OrdersTable(attachedDatabase, alias);
  }
}

class OrderRow extends DataClass implements Insertable<OrderRow> {
  final String id;
  final String storeId;
  final String terminalId;
  final String cashierId;
  final String? memberId;
  final String status;
  final int subtotalCents;
  final int discountCents;
  final int taxCents;
  final int totalCents;
  final int refundedCents;
  final String? invoiceNumber;
  final String? invoiceCarrier;
  final String? note;
  final String? orderNo;
  final String? tableLabel;
  final String? primaryPaymentMethod;
  final String? sourceGuestOrderId;
  final DateTime createdAt;
  final DateTime? syncedAt;
  const OrderRow(
      {required this.id,
      required this.storeId,
      required this.terminalId,
      required this.cashierId,
      this.memberId,
      required this.status,
      required this.subtotalCents,
      required this.discountCents,
      required this.taxCents,
      required this.totalCents,
      required this.refundedCents,
      this.invoiceNumber,
      this.invoiceCarrier,
      this.note,
      this.orderNo,
      this.tableLabel,
      this.primaryPaymentMethod,
      this.sourceGuestOrderId,
      required this.createdAt,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['store_id'] = Variable<String>(storeId);
    map['terminal_id'] = Variable<String>(terminalId);
    map['cashier_id'] = Variable<String>(cashierId);
    if (!nullToAbsent || memberId != null) {
      map['member_id'] = Variable<String>(memberId);
    }
    map['status'] = Variable<String>(status);
    map['subtotal_cents'] = Variable<int>(subtotalCents);
    map['discount_cents'] = Variable<int>(discountCents);
    map['tax_cents'] = Variable<int>(taxCents);
    map['total_cents'] = Variable<int>(totalCents);
    map['refunded_cents'] = Variable<int>(refundedCents);
    if (!nullToAbsent || invoiceNumber != null) {
      map['invoice_number'] = Variable<String>(invoiceNumber);
    }
    if (!nullToAbsent || invoiceCarrier != null) {
      map['invoice_carrier'] = Variable<String>(invoiceCarrier);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || orderNo != null) {
      map['order_no'] = Variable<String>(orderNo);
    }
    if (!nullToAbsent || tableLabel != null) {
      map['table_label'] = Variable<String>(tableLabel);
    }
    if (!nullToAbsent || primaryPaymentMethod != null) {
      map['primary_payment_method'] = Variable<String>(primaryPaymentMethod);
    }
    if (!nullToAbsent || sourceGuestOrderId != null) {
      map['source_guest_order_id'] = Variable<String>(sourceGuestOrderId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  OrdersCompanion toCompanion(bool nullToAbsent) {
    return OrdersCompanion(
      id: Value(id),
      storeId: Value(storeId),
      terminalId: Value(terminalId),
      cashierId: Value(cashierId),
      memberId: memberId == null && nullToAbsent
          ? const Value.absent()
          : Value(memberId),
      status: Value(status),
      subtotalCents: Value(subtotalCents),
      discountCents: Value(discountCents),
      taxCents: Value(taxCents),
      totalCents: Value(totalCents),
      refundedCents: Value(refundedCents),
      invoiceNumber: invoiceNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceNumber),
      invoiceCarrier: invoiceCarrier == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceCarrier),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      orderNo: orderNo == null && nullToAbsent
          ? const Value.absent()
          : Value(orderNo),
      tableLabel: tableLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(tableLabel),
      primaryPaymentMethod: primaryPaymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(primaryPaymentMethod),
      sourceGuestOrderId: sourceGuestOrderId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceGuestOrderId),
      createdAt: Value(createdAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory OrderRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderRow(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String>(json['storeId']),
      terminalId: serializer.fromJson<String>(json['terminalId']),
      cashierId: serializer.fromJson<String>(json['cashierId']),
      memberId: serializer.fromJson<String?>(json['memberId']),
      status: serializer.fromJson<String>(json['status']),
      subtotalCents: serializer.fromJson<int>(json['subtotalCents']),
      discountCents: serializer.fromJson<int>(json['discountCents']),
      taxCents: serializer.fromJson<int>(json['taxCents']),
      totalCents: serializer.fromJson<int>(json['totalCents']),
      refundedCents: serializer.fromJson<int>(json['refundedCents']),
      invoiceNumber: serializer.fromJson<String?>(json['invoiceNumber']),
      invoiceCarrier: serializer.fromJson<String?>(json['invoiceCarrier']),
      note: serializer.fromJson<String?>(json['note']),
      orderNo: serializer.fromJson<String?>(json['orderNo']),
      tableLabel: serializer.fromJson<String?>(json['tableLabel']),
      primaryPaymentMethod:
          serializer.fromJson<String?>(json['primaryPaymentMethod']),
      sourceGuestOrderId:
          serializer.fromJson<String?>(json['sourceGuestOrderId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'storeId': serializer.toJson<String>(storeId),
      'terminalId': serializer.toJson<String>(terminalId),
      'cashierId': serializer.toJson<String>(cashierId),
      'memberId': serializer.toJson<String?>(memberId),
      'status': serializer.toJson<String>(status),
      'subtotalCents': serializer.toJson<int>(subtotalCents),
      'discountCents': serializer.toJson<int>(discountCents),
      'taxCents': serializer.toJson<int>(taxCents),
      'totalCents': serializer.toJson<int>(totalCents),
      'refundedCents': serializer.toJson<int>(refundedCents),
      'invoiceNumber': serializer.toJson<String?>(invoiceNumber),
      'invoiceCarrier': serializer.toJson<String?>(invoiceCarrier),
      'note': serializer.toJson<String?>(note),
      'orderNo': serializer.toJson<String?>(orderNo),
      'tableLabel': serializer.toJson<String?>(tableLabel),
      'primaryPaymentMethod': serializer.toJson<String?>(primaryPaymentMethod),
      'sourceGuestOrderId': serializer.toJson<String?>(sourceGuestOrderId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  OrderRow copyWith(
          {String? id,
          String? storeId,
          String? terminalId,
          String? cashierId,
          Value<String?> memberId = const Value.absent(),
          String? status,
          int? subtotalCents,
          int? discountCents,
          int? taxCents,
          int? totalCents,
          int? refundedCents,
          Value<String?> invoiceNumber = const Value.absent(),
          Value<String?> invoiceCarrier = const Value.absent(),
          Value<String?> note = const Value.absent(),
          Value<String?> orderNo = const Value.absent(),
          Value<String?> tableLabel = const Value.absent(),
          Value<String?> primaryPaymentMethod = const Value.absent(),
          Value<String?> sourceGuestOrderId = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      OrderRow(
        id: id ?? this.id,
        storeId: storeId ?? this.storeId,
        terminalId: terminalId ?? this.terminalId,
        cashierId: cashierId ?? this.cashierId,
        memberId: memberId.present ? memberId.value : this.memberId,
        status: status ?? this.status,
        subtotalCents: subtotalCents ?? this.subtotalCents,
        discountCents: discountCents ?? this.discountCents,
        taxCents: taxCents ?? this.taxCents,
        totalCents: totalCents ?? this.totalCents,
        refundedCents: refundedCents ?? this.refundedCents,
        invoiceNumber:
            invoiceNumber.present ? invoiceNumber.value : this.invoiceNumber,
        invoiceCarrier:
            invoiceCarrier.present ? invoiceCarrier.value : this.invoiceCarrier,
        note: note.present ? note.value : this.note,
        orderNo: orderNo.present ? orderNo.value : this.orderNo,
        tableLabel: tableLabel.present ? tableLabel.value : this.tableLabel,
        primaryPaymentMethod: primaryPaymentMethod.present
            ? primaryPaymentMethod.value
            : this.primaryPaymentMethod,
        sourceGuestOrderId: sourceGuestOrderId.present
            ? sourceGuestOrderId.value
            : this.sourceGuestOrderId,
        createdAt: createdAt ?? this.createdAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  OrderRow copyWithCompanion(OrdersCompanion data) {
    return OrderRow(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      terminalId:
          data.terminalId.present ? data.terminalId.value : this.terminalId,
      cashierId: data.cashierId.present ? data.cashierId.value : this.cashierId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      status: data.status.present ? data.status.value : this.status,
      subtotalCents: data.subtotalCents.present
          ? data.subtotalCents.value
          : this.subtotalCents,
      discountCents: data.discountCents.present
          ? data.discountCents.value
          : this.discountCents,
      taxCents: data.taxCents.present ? data.taxCents.value : this.taxCents,
      totalCents:
          data.totalCents.present ? data.totalCents.value : this.totalCents,
      refundedCents: data.refundedCents.present
          ? data.refundedCents.value
          : this.refundedCents,
      invoiceNumber: data.invoiceNumber.present
          ? data.invoiceNumber.value
          : this.invoiceNumber,
      invoiceCarrier: data.invoiceCarrier.present
          ? data.invoiceCarrier.value
          : this.invoiceCarrier,
      note: data.note.present ? data.note.value : this.note,
      orderNo: data.orderNo.present ? data.orderNo.value : this.orderNo,
      tableLabel:
          data.tableLabel.present ? data.tableLabel.value : this.tableLabel,
      primaryPaymentMethod: data.primaryPaymentMethod.present
          ? data.primaryPaymentMethod.value
          : this.primaryPaymentMethod,
      sourceGuestOrderId: data.sourceGuestOrderId.present
          ? data.sourceGuestOrderId.value
          : this.sourceGuestOrderId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderRow(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('terminalId: $terminalId, ')
          ..write('cashierId: $cashierId, ')
          ..write('memberId: $memberId, ')
          ..write('status: $status, ')
          ..write('subtotalCents: $subtotalCents, ')
          ..write('discountCents: $discountCents, ')
          ..write('taxCents: $taxCents, ')
          ..write('totalCents: $totalCents, ')
          ..write('refundedCents: $refundedCents, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('invoiceCarrier: $invoiceCarrier, ')
          ..write('note: $note, ')
          ..write('orderNo: $orderNo, ')
          ..write('tableLabel: $tableLabel, ')
          ..write('primaryPaymentMethod: $primaryPaymentMethod, ')
          ..write('sourceGuestOrderId: $sourceGuestOrderId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      storeId,
      terminalId,
      cashierId,
      memberId,
      status,
      subtotalCents,
      discountCents,
      taxCents,
      totalCents,
      refundedCents,
      invoiceNumber,
      invoiceCarrier,
      note,
      orderNo,
      tableLabel,
      primaryPaymentMethod,
      sourceGuestOrderId,
      createdAt,
      syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderRow &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.terminalId == this.terminalId &&
          other.cashierId == this.cashierId &&
          other.memberId == this.memberId &&
          other.status == this.status &&
          other.subtotalCents == this.subtotalCents &&
          other.discountCents == this.discountCents &&
          other.taxCents == this.taxCents &&
          other.totalCents == this.totalCents &&
          other.refundedCents == this.refundedCents &&
          other.invoiceNumber == this.invoiceNumber &&
          other.invoiceCarrier == this.invoiceCarrier &&
          other.note == this.note &&
          other.orderNo == this.orderNo &&
          other.tableLabel == this.tableLabel &&
          other.primaryPaymentMethod == this.primaryPaymentMethod &&
          other.sourceGuestOrderId == this.sourceGuestOrderId &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt);
}

class OrdersCompanion extends UpdateCompanion<OrderRow> {
  final Value<String> id;
  final Value<String> storeId;
  final Value<String> terminalId;
  final Value<String> cashierId;
  final Value<String?> memberId;
  final Value<String> status;
  final Value<int> subtotalCents;
  final Value<int> discountCents;
  final Value<int> taxCents;
  final Value<int> totalCents;
  final Value<int> refundedCents;
  final Value<String?> invoiceNumber;
  final Value<String?> invoiceCarrier;
  final Value<String?> note;
  final Value<String?> orderNo;
  final Value<String?> tableLabel;
  final Value<String?> primaryPaymentMethod;
  final Value<String?> sourceGuestOrderId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const OrdersCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.terminalId = const Value.absent(),
    this.cashierId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.status = const Value.absent(),
    this.subtotalCents = const Value.absent(),
    this.discountCents = const Value.absent(),
    this.taxCents = const Value.absent(),
    this.totalCents = const Value.absent(),
    this.refundedCents = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.invoiceCarrier = const Value.absent(),
    this.note = const Value.absent(),
    this.orderNo = const Value.absent(),
    this.tableLabel = const Value.absent(),
    this.primaryPaymentMethod = const Value.absent(),
    this.sourceGuestOrderId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrdersCompanion.insert({
    required String id,
    required String storeId,
    required String terminalId,
    required String cashierId,
    this.memberId = const Value.absent(),
    this.status = const Value.absent(),
    this.subtotalCents = const Value.absent(),
    this.discountCents = const Value.absent(),
    this.taxCents = const Value.absent(),
    this.totalCents = const Value.absent(),
    this.refundedCents = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.invoiceCarrier = const Value.absent(),
    this.note = const Value.absent(),
    this.orderNo = const Value.absent(),
    this.tableLabel = const Value.absent(),
    this.primaryPaymentMethod = const Value.absent(),
    this.sourceGuestOrderId = const Value.absent(),
    required DateTime createdAt,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        storeId = Value(storeId),
        terminalId = Value(terminalId),
        cashierId = Value(cashierId),
        createdAt = Value(createdAt);
  static Insertable<OrderRow> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? terminalId,
    Expression<String>? cashierId,
    Expression<String>? memberId,
    Expression<String>? status,
    Expression<int>? subtotalCents,
    Expression<int>? discountCents,
    Expression<int>? taxCents,
    Expression<int>? totalCents,
    Expression<int>? refundedCents,
    Expression<String>? invoiceNumber,
    Expression<String>? invoiceCarrier,
    Expression<String>? note,
    Expression<String>? orderNo,
    Expression<String>? tableLabel,
    Expression<String>? primaryPaymentMethod,
    Expression<String>? sourceGuestOrderId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (terminalId != null) 'terminal_id': terminalId,
      if (cashierId != null) 'cashier_id': cashierId,
      if (memberId != null) 'member_id': memberId,
      if (status != null) 'status': status,
      if (subtotalCents != null) 'subtotal_cents': subtotalCents,
      if (discountCents != null) 'discount_cents': discountCents,
      if (taxCents != null) 'tax_cents': taxCents,
      if (totalCents != null) 'total_cents': totalCents,
      if (refundedCents != null) 'refunded_cents': refundedCents,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (invoiceCarrier != null) 'invoice_carrier': invoiceCarrier,
      if (note != null) 'note': note,
      if (orderNo != null) 'order_no': orderNo,
      if (tableLabel != null) 'table_label': tableLabel,
      if (primaryPaymentMethod != null)
        'primary_payment_method': primaryPaymentMethod,
      if (sourceGuestOrderId != null)
        'source_guest_order_id': sourceGuestOrderId,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrdersCompanion copyWith(
      {Value<String>? id,
      Value<String>? storeId,
      Value<String>? terminalId,
      Value<String>? cashierId,
      Value<String?>? memberId,
      Value<String>? status,
      Value<int>? subtotalCents,
      Value<int>? discountCents,
      Value<int>? taxCents,
      Value<int>? totalCents,
      Value<int>? refundedCents,
      Value<String?>? invoiceNumber,
      Value<String?>? invoiceCarrier,
      Value<String?>? note,
      Value<String?>? orderNo,
      Value<String?>? tableLabel,
      Value<String?>? primaryPaymentMethod,
      Value<String?>? sourceGuestOrderId,
      Value<DateTime>? createdAt,
      Value<DateTime?>? syncedAt,
      Value<int>? rowid}) {
    return OrdersCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      terminalId: terminalId ?? this.terminalId,
      cashierId: cashierId ?? this.cashierId,
      memberId: memberId ?? this.memberId,
      status: status ?? this.status,
      subtotalCents: subtotalCents ?? this.subtotalCents,
      discountCents: discountCents ?? this.discountCents,
      taxCents: taxCents ?? this.taxCents,
      totalCents: totalCents ?? this.totalCents,
      refundedCents: refundedCents ?? this.refundedCents,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceCarrier: invoiceCarrier ?? this.invoiceCarrier,
      note: note ?? this.note,
      orderNo: orderNo ?? this.orderNo,
      tableLabel: tableLabel ?? this.tableLabel,
      primaryPaymentMethod: primaryPaymentMethod ?? this.primaryPaymentMethod,
      sourceGuestOrderId: sourceGuestOrderId ?? this.sourceGuestOrderId,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (terminalId.present) {
      map['terminal_id'] = Variable<String>(terminalId.value);
    }
    if (cashierId.present) {
      map['cashier_id'] = Variable<String>(cashierId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (subtotalCents.present) {
      map['subtotal_cents'] = Variable<int>(subtotalCents.value);
    }
    if (discountCents.present) {
      map['discount_cents'] = Variable<int>(discountCents.value);
    }
    if (taxCents.present) {
      map['tax_cents'] = Variable<int>(taxCents.value);
    }
    if (totalCents.present) {
      map['total_cents'] = Variable<int>(totalCents.value);
    }
    if (refundedCents.present) {
      map['refunded_cents'] = Variable<int>(refundedCents.value);
    }
    if (invoiceNumber.present) {
      map['invoice_number'] = Variable<String>(invoiceNumber.value);
    }
    if (invoiceCarrier.present) {
      map['invoice_carrier'] = Variable<String>(invoiceCarrier.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (orderNo.present) {
      map['order_no'] = Variable<String>(orderNo.value);
    }
    if (tableLabel.present) {
      map['table_label'] = Variable<String>(tableLabel.value);
    }
    if (primaryPaymentMethod.present) {
      map['primary_payment_method'] =
          Variable<String>(primaryPaymentMethod.value);
    }
    if (sourceGuestOrderId.present) {
      map['source_guest_order_id'] = Variable<String>(sourceGuestOrderId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrdersCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('terminalId: $terminalId, ')
          ..write('cashierId: $cashierId, ')
          ..write('memberId: $memberId, ')
          ..write('status: $status, ')
          ..write('subtotalCents: $subtotalCents, ')
          ..write('discountCents: $discountCents, ')
          ..write('taxCents: $taxCents, ')
          ..write('totalCents: $totalCents, ')
          ..write('refundedCents: $refundedCents, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('invoiceCarrier: $invoiceCarrier, ')
          ..write('note: $note, ')
          ..write('orderNo: $orderNo, ')
          ..write('tableLabel: $tableLabel, ')
          ..write('primaryPaymentMethod: $primaryPaymentMethod, ')
          ..write('sourceGuestOrderId: $sourceGuestOrderId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrderLinesTable extends OrderLines
    with TableInfo<$OrderLinesTable, OrderLineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrderLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderIdMeta =
      const VerificationMeta('orderId');
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
      'order_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productNameMeta =
      const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
      'product_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
      'sku', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<double> qty = GeneratedColumn<double>(
      'qty', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitPriceCentsMeta =
      const VerificationMeta('unitPriceCents');
  @override
  late final GeneratedColumn<int> unitPriceCents = GeneratedColumn<int>(
      'unit_price_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lineDiscountCentsMeta =
      const VerificationMeta('lineDiscountCents');
  @override
  late final GeneratedColumn<int> lineDiscountCents = GeneratedColumn<int>(
      'line_discount_cents', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lineTotalCentsMeta =
      const VerificationMeta('lineTotalCents');
  @override
  late final GeneratedColumn<int> lineTotalCents = GeneratedColumn<int>(
      'line_total_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _taxRateMeta =
      const VerificationMeta('taxRate');
  @override
  late final GeneratedColumn<double> taxRate = GeneratedColumn<double>(
      'tax_rate', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.05));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _optionsJsonMeta =
      const VerificationMeta('optionsJson');
  @override
  late final GeneratedColumn<String> optionsJson = GeneratedColumn<String>(
      'options_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        orderId,
        productId,
        productName,
        sku,
        qty,
        unitPriceCents,
        lineDiscountCents,
        lineTotalCents,
        taxRate,
        note,
        optionsJson
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'order_lines';
  @override
  VerificationContext validateIntegrity(Insertable<OrderLineRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('order_id')) {
      context.handle(_orderIdMeta,
          orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta));
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
          _productNameMeta,
          productName.isAcceptableOrUnknown(
              data['product_name']!, _productNameMeta));
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
          _skuMeta, sku.isAcceptableOrUnknown(data['sku']!, _skuMeta));
    } else if (isInserting) {
      context.missing(_skuMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
          _qtyMeta, qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta));
    } else if (isInserting) {
      context.missing(_qtyMeta);
    }
    if (data.containsKey('unit_price_cents')) {
      context.handle(
          _unitPriceCentsMeta,
          unitPriceCents.isAcceptableOrUnknown(
              data['unit_price_cents']!, _unitPriceCentsMeta));
    } else if (isInserting) {
      context.missing(_unitPriceCentsMeta);
    }
    if (data.containsKey('line_discount_cents')) {
      context.handle(
          _lineDiscountCentsMeta,
          lineDiscountCents.isAcceptableOrUnknown(
              data['line_discount_cents']!, _lineDiscountCentsMeta));
    }
    if (data.containsKey('line_total_cents')) {
      context.handle(
          _lineTotalCentsMeta,
          lineTotalCents.isAcceptableOrUnknown(
              data['line_total_cents']!, _lineTotalCentsMeta));
    } else if (isInserting) {
      context.missing(_lineTotalCentsMeta);
    }
    if (data.containsKey('tax_rate')) {
      context.handle(_taxRateMeta,
          taxRate.isAcceptableOrUnknown(data['tax_rate']!, _taxRateMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('options_json')) {
      context.handle(
          _optionsJsonMeta,
          optionsJson.isAcceptableOrUnknown(
              data['options_json']!, _optionsJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrderLineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderLineRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      orderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      productName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_name'])!,
      sku: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sku'])!,
      qty: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}qty'])!,
      unitPriceCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unit_price_cents'])!,
      lineDiscountCents: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}line_discount_cents'])!,
      lineTotalCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}line_total_cents'])!,
      taxRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tax_rate'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      optionsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}options_json']),
    );
  }

  @override
  $OrderLinesTable createAlias(String alias) {
    return $OrderLinesTable(attachedDatabase, alias);
  }
}

class OrderLineRow extends DataClass implements Insertable<OrderLineRow> {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final String sku;
  final double qty;
  final int unitPriceCents;
  final int lineDiscountCents;
  final int lineTotalCents;
  final double taxRate;
  final String? note;
  final String? optionsJson;
  const OrderLineRow(
      {required this.id,
      required this.orderId,
      required this.productId,
      required this.productName,
      required this.sku,
      required this.qty,
      required this.unitPriceCents,
      required this.lineDiscountCents,
      required this.lineTotalCents,
      required this.taxRate,
      this.note,
      this.optionsJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['order_id'] = Variable<String>(orderId);
    map['product_id'] = Variable<String>(productId);
    map['product_name'] = Variable<String>(productName);
    map['sku'] = Variable<String>(sku);
    map['qty'] = Variable<double>(qty);
    map['unit_price_cents'] = Variable<int>(unitPriceCents);
    map['line_discount_cents'] = Variable<int>(lineDiscountCents);
    map['line_total_cents'] = Variable<int>(lineTotalCents);
    map['tax_rate'] = Variable<double>(taxRate);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || optionsJson != null) {
      map['options_json'] = Variable<String>(optionsJson);
    }
    return map;
  }

  OrderLinesCompanion toCompanion(bool nullToAbsent) {
    return OrderLinesCompanion(
      id: Value(id),
      orderId: Value(orderId),
      productId: Value(productId),
      productName: Value(productName),
      sku: Value(sku),
      qty: Value(qty),
      unitPriceCents: Value(unitPriceCents),
      lineDiscountCents: Value(lineDiscountCents),
      lineTotalCents: Value(lineTotalCents),
      taxRate: Value(taxRate),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      optionsJson: optionsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(optionsJson),
    );
  }

  factory OrderLineRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderLineRow(
      id: serializer.fromJson<String>(json['id']),
      orderId: serializer.fromJson<String>(json['orderId']),
      productId: serializer.fromJson<String>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      sku: serializer.fromJson<String>(json['sku']),
      qty: serializer.fromJson<double>(json['qty']),
      unitPriceCents: serializer.fromJson<int>(json['unitPriceCents']),
      lineDiscountCents: serializer.fromJson<int>(json['lineDiscountCents']),
      lineTotalCents: serializer.fromJson<int>(json['lineTotalCents']),
      taxRate: serializer.fromJson<double>(json['taxRate']),
      note: serializer.fromJson<String?>(json['note']),
      optionsJson: serializer.fromJson<String?>(json['optionsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orderId': serializer.toJson<String>(orderId),
      'productId': serializer.toJson<String>(productId),
      'productName': serializer.toJson<String>(productName),
      'sku': serializer.toJson<String>(sku),
      'qty': serializer.toJson<double>(qty),
      'unitPriceCents': serializer.toJson<int>(unitPriceCents),
      'lineDiscountCents': serializer.toJson<int>(lineDiscountCents),
      'lineTotalCents': serializer.toJson<int>(lineTotalCents),
      'taxRate': serializer.toJson<double>(taxRate),
      'note': serializer.toJson<String?>(note),
      'optionsJson': serializer.toJson<String?>(optionsJson),
    };
  }

  OrderLineRow copyWith(
          {String? id,
          String? orderId,
          String? productId,
          String? productName,
          String? sku,
          double? qty,
          int? unitPriceCents,
          int? lineDiscountCents,
          int? lineTotalCents,
          double? taxRate,
          Value<String?> note = const Value.absent(),
          Value<String?> optionsJson = const Value.absent()}) =>
      OrderLineRow(
        id: id ?? this.id,
        orderId: orderId ?? this.orderId,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        sku: sku ?? this.sku,
        qty: qty ?? this.qty,
        unitPriceCents: unitPriceCents ?? this.unitPriceCents,
        lineDiscountCents: lineDiscountCents ?? this.lineDiscountCents,
        lineTotalCents: lineTotalCents ?? this.lineTotalCents,
        taxRate: taxRate ?? this.taxRate,
        note: note.present ? note.value : this.note,
        optionsJson: optionsJson.present ? optionsJson.value : this.optionsJson,
      );
  OrderLineRow copyWithCompanion(OrderLinesCompanion data) {
    return OrderLineRow(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName:
          data.productName.present ? data.productName.value : this.productName,
      sku: data.sku.present ? data.sku.value : this.sku,
      qty: data.qty.present ? data.qty.value : this.qty,
      unitPriceCents: data.unitPriceCents.present
          ? data.unitPriceCents.value
          : this.unitPriceCents,
      lineDiscountCents: data.lineDiscountCents.present
          ? data.lineDiscountCents.value
          : this.lineDiscountCents,
      lineTotalCents: data.lineTotalCents.present
          ? data.lineTotalCents.value
          : this.lineTotalCents,
      taxRate: data.taxRate.present ? data.taxRate.value : this.taxRate,
      note: data.note.present ? data.note.value : this.note,
      optionsJson:
          data.optionsJson.present ? data.optionsJson.value : this.optionsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderLineRow(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('sku: $sku, ')
          ..write('qty: $qty, ')
          ..write('unitPriceCents: $unitPriceCents, ')
          ..write('lineDiscountCents: $lineDiscountCents, ')
          ..write('lineTotalCents: $lineTotalCents, ')
          ..write('taxRate: $taxRate, ')
          ..write('note: $note, ')
          ..write('optionsJson: $optionsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      orderId,
      productId,
      productName,
      sku,
      qty,
      unitPriceCents,
      lineDiscountCents,
      lineTotalCents,
      taxRate,
      note,
      optionsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderLineRow &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.sku == this.sku &&
          other.qty == this.qty &&
          other.unitPriceCents == this.unitPriceCents &&
          other.lineDiscountCents == this.lineDiscountCents &&
          other.lineTotalCents == this.lineTotalCents &&
          other.taxRate == this.taxRate &&
          other.note == this.note &&
          other.optionsJson == this.optionsJson);
}

class OrderLinesCompanion extends UpdateCompanion<OrderLineRow> {
  final Value<String> id;
  final Value<String> orderId;
  final Value<String> productId;
  final Value<String> productName;
  final Value<String> sku;
  final Value<double> qty;
  final Value<int> unitPriceCents;
  final Value<int> lineDiscountCents;
  final Value<int> lineTotalCents;
  final Value<double> taxRate;
  final Value<String?> note;
  final Value<String?> optionsJson;
  final Value<int> rowid;
  const OrderLinesCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.sku = const Value.absent(),
    this.qty = const Value.absent(),
    this.unitPriceCents = const Value.absent(),
    this.lineDiscountCents = const Value.absent(),
    this.lineTotalCents = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.note = const Value.absent(),
    this.optionsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrderLinesCompanion.insert({
    required String id,
    required String orderId,
    required String productId,
    required String productName,
    required String sku,
    required double qty,
    required int unitPriceCents,
    this.lineDiscountCents = const Value.absent(),
    required int lineTotalCents,
    this.taxRate = const Value.absent(),
    this.note = const Value.absent(),
    this.optionsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        orderId = Value(orderId),
        productId = Value(productId),
        productName = Value(productName),
        sku = Value(sku),
        qty = Value(qty),
        unitPriceCents = Value(unitPriceCents),
        lineTotalCents = Value(lineTotalCents);
  static Insertable<OrderLineRow> custom({
    Expression<String>? id,
    Expression<String>? orderId,
    Expression<String>? productId,
    Expression<String>? productName,
    Expression<String>? sku,
    Expression<double>? qty,
    Expression<int>? unitPriceCents,
    Expression<int>? lineDiscountCents,
    Expression<int>? lineTotalCents,
    Expression<double>? taxRate,
    Expression<String>? note,
    Expression<String>? optionsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (sku != null) 'sku': sku,
      if (qty != null) 'qty': qty,
      if (unitPriceCents != null) 'unit_price_cents': unitPriceCents,
      if (lineDiscountCents != null) 'line_discount_cents': lineDiscountCents,
      if (lineTotalCents != null) 'line_total_cents': lineTotalCents,
      if (taxRate != null) 'tax_rate': taxRate,
      if (note != null) 'note': note,
      if (optionsJson != null) 'options_json': optionsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrderLinesCompanion copyWith(
      {Value<String>? id,
      Value<String>? orderId,
      Value<String>? productId,
      Value<String>? productName,
      Value<String>? sku,
      Value<double>? qty,
      Value<int>? unitPriceCents,
      Value<int>? lineDiscountCents,
      Value<int>? lineTotalCents,
      Value<double>? taxRate,
      Value<String?>? note,
      Value<String?>? optionsJson,
      Value<int>? rowid}) {
    return OrderLinesCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      qty: qty ?? this.qty,
      unitPriceCents: unitPriceCents ?? this.unitPriceCents,
      lineDiscountCents: lineDiscountCents ?? this.lineDiscountCents,
      lineTotalCents: lineTotalCents ?? this.lineTotalCents,
      taxRate: taxRate ?? this.taxRate,
      note: note ?? this.note,
      optionsJson: optionsJson ?? this.optionsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (qty.present) {
      map['qty'] = Variable<double>(qty.value);
    }
    if (unitPriceCents.present) {
      map['unit_price_cents'] = Variable<int>(unitPriceCents.value);
    }
    if (lineDiscountCents.present) {
      map['line_discount_cents'] = Variable<int>(lineDiscountCents.value);
    }
    if (lineTotalCents.present) {
      map['line_total_cents'] = Variable<int>(lineTotalCents.value);
    }
    if (taxRate.present) {
      map['tax_rate'] = Variable<double>(taxRate.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (optionsJson.present) {
      map['options_json'] = Variable<String>(optionsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrderLinesCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('sku: $sku, ')
          ..write('qty: $qty, ')
          ..write('unitPriceCents: $unitPriceCents, ')
          ..write('lineDiscountCents: $lineDiscountCents, ')
          ..write('lineTotalCents: $lineTotalCents, ')
          ..write('taxRate: $taxRate, ')
          ..write('note: $note, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentsTable extends Payments
    with TableInfo<$PaymentsTable, PaymentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderIdMeta =
      const VerificationMeta('orderId');
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
      'order_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
      'method', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountCentsMeta =
      const VerificationMeta('amountCents');
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
      'amount_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('captured'));
  static const VerificationMeta _gatewayRefMeta =
      const VerificationMeta('gatewayRef');
  @override
  late final GeneratedColumn<String> gatewayRef = GeneratedColumn<String>(
      'gateway_ref', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _gatewayResponseJsonMeta =
      const VerificationMeta('gatewayResponseJson');
  @override
  late final GeneratedColumn<String> gatewayResponseJson =
      GeneratedColumn<String>('gateway_response_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tenderedCentsMeta =
      const VerificationMeta('tenderedCents');
  @override
  late final GeneratedColumn<int> tenderedCents = GeneratedColumn<int>(
      'tendered_cents', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _changeDueCentsMeta =
      const VerificationMeta('changeDueCents');
  @override
  late final GeneratedColumn<int> changeDueCents = GeneratedColumn<int>(
      'change_due_cents', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        orderId,
        method,
        amountCents,
        status,
        gatewayRef,
        gatewayResponseJson,
        tenderedCents,
        changeDueCents,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments';
  @override
  VerificationContext validateIntegrity(Insertable<PaymentRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('order_id')) {
      context.handle(_orderIdMeta,
          orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta));
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('method')) {
      context.handle(_methodMeta,
          method.isAcceptableOrUnknown(data['method']!, _methodMeta));
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
          _amountCentsMeta,
          amountCents.isAcceptableOrUnknown(
              data['amount_cents']!, _amountCentsMeta));
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('gateway_ref')) {
      context.handle(
          _gatewayRefMeta,
          gatewayRef.isAcceptableOrUnknown(
              data['gateway_ref']!, _gatewayRefMeta));
    }
    if (data.containsKey('gateway_response_json')) {
      context.handle(
          _gatewayResponseJsonMeta,
          gatewayResponseJson.isAcceptableOrUnknown(
              data['gateway_response_json']!, _gatewayResponseJsonMeta));
    }
    if (data.containsKey('tendered_cents')) {
      context.handle(
          _tenderedCentsMeta,
          tenderedCents.isAcceptableOrUnknown(
              data['tendered_cents']!, _tenderedCentsMeta));
    }
    if (data.containsKey('change_due_cents')) {
      context.handle(
          _changeDueCentsMeta,
          changeDueCents.isAcceptableOrUnknown(
              data['change_due_cents']!, _changeDueCentsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      orderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_id'])!,
      method: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method'])!,
      amountCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_cents'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      gatewayRef: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gateway_ref']),
      gatewayResponseJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}gateway_response_json']),
      tenderedCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tendered_cents']),
      changeDueCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}change_due_cents']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PaymentsTable createAlias(String alias) {
    return $PaymentsTable(attachedDatabase, alias);
  }
}

class PaymentRow extends DataClass implements Insertable<PaymentRow> {
  final String id;
  final String orderId;
  final String method;
  final int amountCents;
  final String status;
  final String? gatewayRef;
  final String? gatewayResponseJson;
  final int? tenderedCents;
  final int? changeDueCents;
  final DateTime createdAt;
  const PaymentRow(
      {required this.id,
      required this.orderId,
      required this.method,
      required this.amountCents,
      required this.status,
      this.gatewayRef,
      this.gatewayResponseJson,
      this.tenderedCents,
      this.changeDueCents,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['order_id'] = Variable<String>(orderId);
    map['method'] = Variable<String>(method);
    map['amount_cents'] = Variable<int>(amountCents);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || gatewayRef != null) {
      map['gateway_ref'] = Variable<String>(gatewayRef);
    }
    if (!nullToAbsent || gatewayResponseJson != null) {
      map['gateway_response_json'] = Variable<String>(gatewayResponseJson);
    }
    if (!nullToAbsent || tenderedCents != null) {
      map['tendered_cents'] = Variable<int>(tenderedCents);
    }
    if (!nullToAbsent || changeDueCents != null) {
      map['change_due_cents'] = Variable<int>(changeDueCents);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PaymentsCompanion toCompanion(bool nullToAbsent) {
    return PaymentsCompanion(
      id: Value(id),
      orderId: Value(orderId),
      method: Value(method),
      amountCents: Value(amountCents),
      status: Value(status),
      gatewayRef: gatewayRef == null && nullToAbsent
          ? const Value.absent()
          : Value(gatewayRef),
      gatewayResponseJson: gatewayResponseJson == null && nullToAbsent
          ? const Value.absent()
          : Value(gatewayResponseJson),
      tenderedCents: tenderedCents == null && nullToAbsent
          ? const Value.absent()
          : Value(tenderedCents),
      changeDueCents: changeDueCents == null && nullToAbsent
          ? const Value.absent()
          : Value(changeDueCents),
      createdAt: Value(createdAt),
    );
  }

  factory PaymentRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentRow(
      id: serializer.fromJson<String>(json['id']),
      orderId: serializer.fromJson<String>(json['orderId']),
      method: serializer.fromJson<String>(json['method']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      status: serializer.fromJson<String>(json['status']),
      gatewayRef: serializer.fromJson<String?>(json['gatewayRef']),
      gatewayResponseJson:
          serializer.fromJson<String?>(json['gatewayResponseJson']),
      tenderedCents: serializer.fromJson<int?>(json['tenderedCents']),
      changeDueCents: serializer.fromJson<int?>(json['changeDueCents']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orderId': serializer.toJson<String>(orderId),
      'method': serializer.toJson<String>(method),
      'amountCents': serializer.toJson<int>(amountCents),
      'status': serializer.toJson<String>(status),
      'gatewayRef': serializer.toJson<String?>(gatewayRef),
      'gatewayResponseJson': serializer.toJson<String?>(gatewayResponseJson),
      'tenderedCents': serializer.toJson<int?>(tenderedCents),
      'changeDueCents': serializer.toJson<int?>(changeDueCents),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PaymentRow copyWith(
          {String? id,
          String? orderId,
          String? method,
          int? amountCents,
          String? status,
          Value<String?> gatewayRef = const Value.absent(),
          Value<String?> gatewayResponseJson = const Value.absent(),
          Value<int?> tenderedCents = const Value.absent(),
          Value<int?> changeDueCents = const Value.absent(),
          DateTime? createdAt}) =>
      PaymentRow(
        id: id ?? this.id,
        orderId: orderId ?? this.orderId,
        method: method ?? this.method,
        amountCents: amountCents ?? this.amountCents,
        status: status ?? this.status,
        gatewayRef: gatewayRef.present ? gatewayRef.value : this.gatewayRef,
        gatewayResponseJson: gatewayResponseJson.present
            ? gatewayResponseJson.value
            : this.gatewayResponseJson,
        tenderedCents:
            tenderedCents.present ? tenderedCents.value : this.tenderedCents,
        changeDueCents:
            changeDueCents.present ? changeDueCents.value : this.changeDueCents,
        createdAt: createdAt ?? this.createdAt,
      );
  PaymentRow copyWithCompanion(PaymentsCompanion data) {
    return PaymentRow(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      method: data.method.present ? data.method.value : this.method,
      amountCents:
          data.amountCents.present ? data.amountCents.value : this.amountCents,
      status: data.status.present ? data.status.value : this.status,
      gatewayRef:
          data.gatewayRef.present ? data.gatewayRef.value : this.gatewayRef,
      gatewayResponseJson: data.gatewayResponseJson.present
          ? data.gatewayResponseJson.value
          : this.gatewayResponseJson,
      tenderedCents: data.tenderedCents.present
          ? data.tenderedCents.value
          : this.tenderedCents,
      changeDueCents: data.changeDueCents.present
          ? data.changeDueCents.value
          : this.changeDueCents,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentRow(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('method: $method, ')
          ..write('amountCents: $amountCents, ')
          ..write('status: $status, ')
          ..write('gatewayRef: $gatewayRef, ')
          ..write('gatewayResponseJson: $gatewayResponseJson, ')
          ..write('tenderedCents: $tenderedCents, ')
          ..write('changeDueCents: $changeDueCents, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      orderId,
      method,
      amountCents,
      status,
      gatewayRef,
      gatewayResponseJson,
      tenderedCents,
      changeDueCents,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentRow &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.method == this.method &&
          other.amountCents == this.amountCents &&
          other.status == this.status &&
          other.gatewayRef == this.gatewayRef &&
          other.gatewayResponseJson == this.gatewayResponseJson &&
          other.tenderedCents == this.tenderedCents &&
          other.changeDueCents == this.changeDueCents &&
          other.createdAt == this.createdAt);
}

class PaymentsCompanion extends UpdateCompanion<PaymentRow> {
  final Value<String> id;
  final Value<String> orderId;
  final Value<String> method;
  final Value<int> amountCents;
  final Value<String> status;
  final Value<String?> gatewayRef;
  final Value<String?> gatewayResponseJson;
  final Value<int?> tenderedCents;
  final Value<int?> changeDueCents;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PaymentsCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.method = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.status = const Value.absent(),
    this.gatewayRef = const Value.absent(),
    this.gatewayResponseJson = const Value.absent(),
    this.tenderedCents = const Value.absent(),
    this.changeDueCents = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentsCompanion.insert({
    required String id,
    required String orderId,
    required String method,
    required int amountCents,
    this.status = const Value.absent(),
    this.gatewayRef = const Value.absent(),
    this.gatewayResponseJson = const Value.absent(),
    this.tenderedCents = const Value.absent(),
    this.changeDueCents = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        orderId = Value(orderId),
        method = Value(method),
        amountCents = Value(amountCents),
        createdAt = Value(createdAt);
  static Insertable<PaymentRow> custom({
    Expression<String>? id,
    Expression<String>? orderId,
    Expression<String>? method,
    Expression<int>? amountCents,
    Expression<String>? status,
    Expression<String>? gatewayRef,
    Expression<String>? gatewayResponseJson,
    Expression<int>? tenderedCents,
    Expression<int>? changeDueCents,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (method != null) 'method': method,
      if (amountCents != null) 'amount_cents': amountCents,
      if (status != null) 'status': status,
      if (gatewayRef != null) 'gateway_ref': gatewayRef,
      if (gatewayResponseJson != null)
        'gateway_response_json': gatewayResponseJson,
      if (tenderedCents != null) 'tendered_cents': tenderedCents,
      if (changeDueCents != null) 'change_due_cents': changeDueCents,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? orderId,
      Value<String>? method,
      Value<int>? amountCents,
      Value<String>? status,
      Value<String?>? gatewayRef,
      Value<String?>? gatewayResponseJson,
      Value<int?>? tenderedCents,
      Value<int?>? changeDueCents,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return PaymentsCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      method: method ?? this.method,
      amountCents: amountCents ?? this.amountCents,
      status: status ?? this.status,
      gatewayRef: gatewayRef ?? this.gatewayRef,
      gatewayResponseJson: gatewayResponseJson ?? this.gatewayResponseJson,
      tenderedCents: tenderedCents ?? this.tenderedCents,
      changeDueCents: changeDueCents ?? this.changeDueCents,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (gatewayRef.present) {
      map['gateway_ref'] = Variable<String>(gatewayRef.value);
    }
    if (gatewayResponseJson.present) {
      map['gateway_response_json'] =
          Variable<String>(gatewayResponseJson.value);
    }
    if (tenderedCents.present) {
      map['tendered_cents'] = Variable<int>(tenderedCents.value);
    }
    if (changeDueCents.present) {
      map['change_due_cents'] = Variable<int>(changeDueCents.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('method: $method, ')
          ..write('amountCents: $amountCents, ')
          ..write('status: $status, ')
          ..write('gatewayRef: $gatewayRef, ')
          ..write('gatewayResponseJson: $gatewayResponseJson, ')
          ..write('tenderedCents: $tenderedCents, ')
          ..write('changeDueCents: $changeDueCents, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RefundsTable extends Refunds with TableInfo<$RefundsTable, RefundRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RefundsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderIdMeta =
      const VerificationMeta('orderId');
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
      'order_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
      'method', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalAmountCentsMeta =
      const VerificationMeta('totalAmountCents');
  @override
  late final GeneratedColumn<int> totalAmountCents = GeneratedColumn<int>(
      'total_amount_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _gatewayRefMeta =
      const VerificationMeta('gatewayRef');
  @override
  late final GeneratedColumn<String> gatewayRef = GeneratedColumn<String>(
      'gateway_ref', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        orderId,
        userId,
        method,
        totalAmountCents,
        reason,
        gatewayRef,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'refunds';
  @override
  VerificationContext validateIntegrity(Insertable<RefundRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('order_id')) {
      context.handle(_orderIdMeta,
          orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta));
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('method')) {
      context.handle(_methodMeta,
          method.isAcceptableOrUnknown(data['method']!, _methodMeta));
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('total_amount_cents')) {
      context.handle(
          _totalAmountCentsMeta,
          totalAmountCents.isAcceptableOrUnknown(
              data['total_amount_cents']!, _totalAmountCentsMeta));
    } else if (isInserting) {
      context.missing(_totalAmountCentsMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    }
    if (data.containsKey('gateway_ref')) {
      context.handle(
          _gatewayRefMeta,
          gatewayRef.isAcceptableOrUnknown(
              data['gateway_ref']!, _gatewayRefMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RefundRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RefundRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      orderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      method: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method'])!,
      totalAmountCents: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}total_amount_cents'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason']),
      gatewayRef: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gateway_ref']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $RefundsTable createAlias(String alias) {
    return $RefundsTable(attachedDatabase, alias);
  }
}

class RefundRow extends DataClass implements Insertable<RefundRow> {
  final String id;
  final String orderId;
  final String userId;
  final String method;
  final int totalAmountCents;
  final String? reason;
  final String? gatewayRef;
  final DateTime createdAt;
  const RefundRow(
      {required this.id,
      required this.orderId,
      required this.userId,
      required this.method,
      required this.totalAmountCents,
      this.reason,
      this.gatewayRef,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['order_id'] = Variable<String>(orderId);
    map['user_id'] = Variable<String>(userId);
    map['method'] = Variable<String>(method);
    map['total_amount_cents'] = Variable<int>(totalAmountCents);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    if (!nullToAbsent || gatewayRef != null) {
      map['gateway_ref'] = Variable<String>(gatewayRef);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RefundsCompanion toCompanion(bool nullToAbsent) {
    return RefundsCompanion(
      id: Value(id),
      orderId: Value(orderId),
      userId: Value(userId),
      method: Value(method),
      totalAmountCents: Value(totalAmountCents),
      reason:
          reason == null && nullToAbsent ? const Value.absent() : Value(reason),
      gatewayRef: gatewayRef == null && nullToAbsent
          ? const Value.absent()
          : Value(gatewayRef),
      createdAt: Value(createdAt),
    );
  }

  factory RefundRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RefundRow(
      id: serializer.fromJson<String>(json['id']),
      orderId: serializer.fromJson<String>(json['orderId']),
      userId: serializer.fromJson<String>(json['userId']),
      method: serializer.fromJson<String>(json['method']),
      totalAmountCents: serializer.fromJson<int>(json['totalAmountCents']),
      reason: serializer.fromJson<String?>(json['reason']),
      gatewayRef: serializer.fromJson<String?>(json['gatewayRef']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orderId': serializer.toJson<String>(orderId),
      'userId': serializer.toJson<String>(userId),
      'method': serializer.toJson<String>(method),
      'totalAmountCents': serializer.toJson<int>(totalAmountCents),
      'reason': serializer.toJson<String?>(reason),
      'gatewayRef': serializer.toJson<String?>(gatewayRef),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RefundRow copyWith(
          {String? id,
          String? orderId,
          String? userId,
          String? method,
          int? totalAmountCents,
          Value<String?> reason = const Value.absent(),
          Value<String?> gatewayRef = const Value.absent(),
          DateTime? createdAt}) =>
      RefundRow(
        id: id ?? this.id,
        orderId: orderId ?? this.orderId,
        userId: userId ?? this.userId,
        method: method ?? this.method,
        totalAmountCents: totalAmountCents ?? this.totalAmountCents,
        reason: reason.present ? reason.value : this.reason,
        gatewayRef: gatewayRef.present ? gatewayRef.value : this.gatewayRef,
        createdAt: createdAt ?? this.createdAt,
      );
  RefundRow copyWithCompanion(RefundsCompanion data) {
    return RefundRow(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      userId: data.userId.present ? data.userId.value : this.userId,
      method: data.method.present ? data.method.value : this.method,
      totalAmountCents: data.totalAmountCents.present
          ? data.totalAmountCents.value
          : this.totalAmountCents,
      reason: data.reason.present ? data.reason.value : this.reason,
      gatewayRef:
          data.gatewayRef.present ? data.gatewayRef.value : this.gatewayRef,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RefundRow(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('userId: $userId, ')
          ..write('method: $method, ')
          ..write('totalAmountCents: $totalAmountCents, ')
          ..write('reason: $reason, ')
          ..write('gatewayRef: $gatewayRef, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, orderId, userId, method, totalAmountCents,
      reason, gatewayRef, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RefundRow &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.userId == this.userId &&
          other.method == this.method &&
          other.totalAmountCents == this.totalAmountCents &&
          other.reason == this.reason &&
          other.gatewayRef == this.gatewayRef &&
          other.createdAt == this.createdAt);
}

class RefundsCompanion extends UpdateCompanion<RefundRow> {
  final Value<String> id;
  final Value<String> orderId;
  final Value<String> userId;
  final Value<String> method;
  final Value<int> totalAmountCents;
  final Value<String?> reason;
  final Value<String?> gatewayRef;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const RefundsCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.userId = const Value.absent(),
    this.method = const Value.absent(),
    this.totalAmountCents = const Value.absent(),
    this.reason = const Value.absent(),
    this.gatewayRef = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RefundsCompanion.insert({
    required String id,
    required String orderId,
    required String userId,
    required String method,
    required int totalAmountCents,
    this.reason = const Value.absent(),
    this.gatewayRef = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        orderId = Value(orderId),
        userId = Value(userId),
        method = Value(method),
        totalAmountCents = Value(totalAmountCents),
        createdAt = Value(createdAt);
  static Insertable<RefundRow> custom({
    Expression<String>? id,
    Expression<String>? orderId,
    Expression<String>? userId,
    Expression<String>? method,
    Expression<int>? totalAmountCents,
    Expression<String>? reason,
    Expression<String>? gatewayRef,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (userId != null) 'user_id': userId,
      if (method != null) 'method': method,
      if (totalAmountCents != null) 'total_amount_cents': totalAmountCents,
      if (reason != null) 'reason': reason,
      if (gatewayRef != null) 'gateway_ref': gatewayRef,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RefundsCompanion copyWith(
      {Value<String>? id,
      Value<String>? orderId,
      Value<String>? userId,
      Value<String>? method,
      Value<int>? totalAmountCents,
      Value<String?>? reason,
      Value<String?>? gatewayRef,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return RefundsCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      method: method ?? this.method,
      totalAmountCents: totalAmountCents ?? this.totalAmountCents,
      reason: reason ?? this.reason,
      gatewayRef: gatewayRef ?? this.gatewayRef,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (totalAmountCents.present) {
      map['total_amount_cents'] = Variable<int>(totalAmountCents.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (gatewayRef.present) {
      map['gateway_ref'] = Variable<String>(gatewayRef.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RefundsCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('userId: $userId, ')
          ..write('method: $method, ')
          ..write('totalAmountCents: $totalAmountCents, ')
          ..write('reason: $reason, ')
          ..write('gatewayRef: $gatewayRef, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RefundLinesTable extends RefundLines
    with TableInfo<$RefundLinesTable, RefundLineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RefundLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _refundIdMeta =
      const VerificationMeta('refundId');
  @override
  late final GeneratedColumn<String> refundId = GeneratedColumn<String>(
      'refund_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderLineIdMeta =
      const VerificationMeta('orderLineId');
  @override
  late final GeneratedColumn<String> orderLineId = GeneratedColumn<String>(
      'order_line_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<double> qty = GeneratedColumn<double>(
      'qty', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _amountCentsMeta =
      const VerificationMeta('amountCents');
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
      'amount_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, refundId, orderLineId, qty, amountCents];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'refund_lines';
  @override
  VerificationContext validateIntegrity(Insertable<RefundLineRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('refund_id')) {
      context.handle(_refundIdMeta,
          refundId.isAcceptableOrUnknown(data['refund_id']!, _refundIdMeta));
    } else if (isInserting) {
      context.missing(_refundIdMeta);
    }
    if (data.containsKey('order_line_id')) {
      context.handle(
          _orderLineIdMeta,
          orderLineId.isAcceptableOrUnknown(
              data['order_line_id']!, _orderLineIdMeta));
    } else if (isInserting) {
      context.missing(_orderLineIdMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
          _qtyMeta, qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta));
    } else if (isInserting) {
      context.missing(_qtyMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
          _amountCentsMeta,
          amountCents.isAcceptableOrUnknown(
              data['amount_cents']!, _amountCentsMeta));
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RefundLineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RefundLineRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      refundId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}refund_id'])!,
      orderLineId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_line_id'])!,
      qty: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}qty'])!,
      amountCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_cents'])!,
    );
  }

  @override
  $RefundLinesTable createAlias(String alias) {
    return $RefundLinesTable(attachedDatabase, alias);
  }
}

class RefundLineRow extends DataClass implements Insertable<RefundLineRow> {
  final String id;
  final String refundId;
  final String orderLineId;
  final double qty;
  final int amountCents;
  const RefundLineRow(
      {required this.id,
      required this.refundId,
      required this.orderLineId,
      required this.qty,
      required this.amountCents});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['refund_id'] = Variable<String>(refundId);
    map['order_line_id'] = Variable<String>(orderLineId);
    map['qty'] = Variable<double>(qty);
    map['amount_cents'] = Variable<int>(amountCents);
    return map;
  }

  RefundLinesCompanion toCompanion(bool nullToAbsent) {
    return RefundLinesCompanion(
      id: Value(id),
      refundId: Value(refundId),
      orderLineId: Value(orderLineId),
      qty: Value(qty),
      amountCents: Value(amountCents),
    );
  }

  factory RefundLineRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RefundLineRow(
      id: serializer.fromJson<String>(json['id']),
      refundId: serializer.fromJson<String>(json['refundId']),
      orderLineId: serializer.fromJson<String>(json['orderLineId']),
      qty: serializer.fromJson<double>(json['qty']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'refundId': serializer.toJson<String>(refundId),
      'orderLineId': serializer.toJson<String>(orderLineId),
      'qty': serializer.toJson<double>(qty),
      'amountCents': serializer.toJson<int>(amountCents),
    };
  }

  RefundLineRow copyWith(
          {String? id,
          String? refundId,
          String? orderLineId,
          double? qty,
          int? amountCents}) =>
      RefundLineRow(
        id: id ?? this.id,
        refundId: refundId ?? this.refundId,
        orderLineId: orderLineId ?? this.orderLineId,
        qty: qty ?? this.qty,
        amountCents: amountCents ?? this.amountCents,
      );
  RefundLineRow copyWithCompanion(RefundLinesCompanion data) {
    return RefundLineRow(
      id: data.id.present ? data.id.value : this.id,
      refundId: data.refundId.present ? data.refundId.value : this.refundId,
      orderLineId:
          data.orderLineId.present ? data.orderLineId.value : this.orderLineId,
      qty: data.qty.present ? data.qty.value : this.qty,
      amountCents:
          data.amountCents.present ? data.amountCents.value : this.amountCents,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RefundLineRow(')
          ..write('id: $id, ')
          ..write('refundId: $refundId, ')
          ..write('orderLineId: $orderLineId, ')
          ..write('qty: $qty, ')
          ..write('amountCents: $amountCents')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, refundId, orderLineId, qty, amountCents);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RefundLineRow &&
          other.id == this.id &&
          other.refundId == this.refundId &&
          other.orderLineId == this.orderLineId &&
          other.qty == this.qty &&
          other.amountCents == this.amountCents);
}

class RefundLinesCompanion extends UpdateCompanion<RefundLineRow> {
  final Value<String> id;
  final Value<String> refundId;
  final Value<String> orderLineId;
  final Value<double> qty;
  final Value<int> amountCents;
  final Value<int> rowid;
  const RefundLinesCompanion({
    this.id = const Value.absent(),
    this.refundId = const Value.absent(),
    this.orderLineId = const Value.absent(),
    this.qty = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RefundLinesCompanion.insert({
    required String id,
    required String refundId,
    required String orderLineId,
    required double qty,
    required int amountCents,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        refundId = Value(refundId),
        orderLineId = Value(orderLineId),
        qty = Value(qty),
        amountCents = Value(amountCents);
  static Insertable<RefundLineRow> custom({
    Expression<String>? id,
    Expression<String>? refundId,
    Expression<String>? orderLineId,
    Expression<double>? qty,
    Expression<int>? amountCents,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (refundId != null) 'refund_id': refundId,
      if (orderLineId != null) 'order_line_id': orderLineId,
      if (qty != null) 'qty': qty,
      if (amountCents != null) 'amount_cents': amountCents,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RefundLinesCompanion copyWith(
      {Value<String>? id,
      Value<String>? refundId,
      Value<String>? orderLineId,
      Value<double>? qty,
      Value<int>? amountCents,
      Value<int>? rowid}) {
    return RefundLinesCompanion(
      id: id ?? this.id,
      refundId: refundId ?? this.refundId,
      orderLineId: orderLineId ?? this.orderLineId,
      qty: qty ?? this.qty,
      amountCents: amountCents ?? this.amountCents,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (refundId.present) {
      map['refund_id'] = Variable<String>(refundId.value);
    }
    if (orderLineId.present) {
      map['order_line_id'] = Variable<String>(orderLineId.value);
    }
    if (qty.present) {
      map['qty'] = Variable<double>(qty.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RefundLinesCompanion(')
          ..write('id: $id, ')
          ..write('refundId: $refundId, ')
          ..write('orderLineId: $orderLineId, ')
          ..write('qty: $qty, ')
          ..write('amountCents: $amountCents, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InventoryLevelsTable extends InventoryLevels
    with TableInfo<$InventoryLevelsTable, InventoryLevelRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryLevelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _storeIdMeta =
      const VerificationMeta('storeId');
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
      'store_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _onHandMeta = const VerificationMeta('onHand');
  @override
  late final GeneratedColumn<double> onHand = GeneratedColumn<double>(
      'on_hand', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _safetyStockMeta =
      const VerificationMeta('safetyStock');
  @override
  late final GeneratedColumn<double> safetyStock = GeneratedColumn<double>(
      'safety_stock', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _reservedMeta =
      const VerificationMeta('reserved');
  @override
  late final GeneratedColumn<double> reserved = GeneratedColumn<double>(
      'reserved', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, storeId, productId, onHand, safetyStock, reserved, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_levels';
  @override
  VerificationContext validateIntegrity(Insertable<InventoryLevelRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(_storeIdMeta,
          storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta));
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('on_hand')) {
      context.handle(_onHandMeta,
          onHand.isAcceptableOrUnknown(data['on_hand']!, _onHandMeta));
    }
    if (data.containsKey('safety_stock')) {
      context.handle(
          _safetyStockMeta,
          safetyStock.isAcceptableOrUnknown(
              data['safety_stock']!, _safetyStockMeta));
    }
    if (data.containsKey('reserved')) {
      context.handle(_reservedMeta,
          reserved.isAcceptableOrUnknown(data['reserved']!, _reservedMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryLevelRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryLevelRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      storeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}store_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      onHand: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}on_hand'])!,
      safetyStock: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}safety_stock'])!,
      reserved: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}reserved'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $InventoryLevelsTable createAlias(String alias) {
    return $InventoryLevelsTable(attachedDatabase, alias);
  }
}

class InventoryLevelRow extends DataClass
    implements Insertable<InventoryLevelRow> {
  final String id;
  final String storeId;
  final String productId;
  final double onHand;
  final double safetyStock;
  final double reserved;
  final DateTime updatedAt;
  const InventoryLevelRow(
      {required this.id,
      required this.storeId,
      required this.productId,
      required this.onHand,
      required this.safetyStock,
      required this.reserved,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['store_id'] = Variable<String>(storeId);
    map['product_id'] = Variable<String>(productId);
    map['on_hand'] = Variable<double>(onHand);
    map['safety_stock'] = Variable<double>(safetyStock);
    map['reserved'] = Variable<double>(reserved);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  InventoryLevelsCompanion toCompanion(bool nullToAbsent) {
    return InventoryLevelsCompanion(
      id: Value(id),
      storeId: Value(storeId),
      productId: Value(productId),
      onHand: Value(onHand),
      safetyStock: Value(safetyStock),
      reserved: Value(reserved),
      updatedAt: Value(updatedAt),
    );
  }

  factory InventoryLevelRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryLevelRow(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String>(json['storeId']),
      productId: serializer.fromJson<String>(json['productId']),
      onHand: serializer.fromJson<double>(json['onHand']),
      safetyStock: serializer.fromJson<double>(json['safetyStock']),
      reserved: serializer.fromJson<double>(json['reserved']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'storeId': serializer.toJson<String>(storeId),
      'productId': serializer.toJson<String>(productId),
      'onHand': serializer.toJson<double>(onHand),
      'safetyStock': serializer.toJson<double>(safetyStock),
      'reserved': serializer.toJson<double>(reserved),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  InventoryLevelRow copyWith(
          {String? id,
          String? storeId,
          String? productId,
          double? onHand,
          double? safetyStock,
          double? reserved,
          DateTime? updatedAt}) =>
      InventoryLevelRow(
        id: id ?? this.id,
        storeId: storeId ?? this.storeId,
        productId: productId ?? this.productId,
        onHand: onHand ?? this.onHand,
        safetyStock: safetyStock ?? this.safetyStock,
        reserved: reserved ?? this.reserved,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  InventoryLevelRow copyWithCompanion(InventoryLevelsCompanion data) {
    return InventoryLevelRow(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      productId: data.productId.present ? data.productId.value : this.productId,
      onHand: data.onHand.present ? data.onHand.value : this.onHand,
      safetyStock:
          data.safetyStock.present ? data.safetyStock.value : this.safetyStock,
      reserved: data.reserved.present ? data.reserved.value : this.reserved,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryLevelRow(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('productId: $productId, ')
          ..write('onHand: $onHand, ')
          ..write('safetyStock: $safetyStock, ')
          ..write('reserved: $reserved, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, storeId, productId, onHand, safetyStock, reserved, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryLevelRow &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.productId == this.productId &&
          other.onHand == this.onHand &&
          other.safetyStock == this.safetyStock &&
          other.reserved == this.reserved &&
          other.updatedAt == this.updatedAt);
}

class InventoryLevelsCompanion extends UpdateCompanion<InventoryLevelRow> {
  final Value<String> id;
  final Value<String> storeId;
  final Value<String> productId;
  final Value<double> onHand;
  final Value<double> safetyStock;
  final Value<double> reserved;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const InventoryLevelsCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.productId = const Value.absent(),
    this.onHand = const Value.absent(),
    this.safetyStock = const Value.absent(),
    this.reserved = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventoryLevelsCompanion.insert({
    required String id,
    required String storeId,
    required String productId,
    this.onHand = const Value.absent(),
    this.safetyStock = const Value.absent(),
    this.reserved = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        storeId = Value(storeId),
        productId = Value(productId),
        updatedAt = Value(updatedAt);
  static Insertable<InventoryLevelRow> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? productId,
    Expression<double>? onHand,
    Expression<double>? safetyStock,
    Expression<double>? reserved,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (productId != null) 'product_id': productId,
      if (onHand != null) 'on_hand': onHand,
      if (safetyStock != null) 'safety_stock': safetyStock,
      if (reserved != null) 'reserved': reserved,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventoryLevelsCompanion copyWith(
      {Value<String>? id,
      Value<String>? storeId,
      Value<String>? productId,
      Value<double>? onHand,
      Value<double>? safetyStock,
      Value<double>? reserved,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return InventoryLevelsCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      productId: productId ?? this.productId,
      onHand: onHand ?? this.onHand,
      safetyStock: safetyStock ?? this.safetyStock,
      reserved: reserved ?? this.reserved,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (onHand.present) {
      map['on_hand'] = Variable<double>(onHand.value);
    }
    if (safetyStock.present) {
      map['safety_stock'] = Variable<double>(safetyStock.value);
    }
    if (reserved.present) {
      map['reserved'] = Variable<double>(reserved.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryLevelsCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('productId: $productId, ')
          ..write('onHand: $onHand, ')
          ..write('safetyStock: $safetyStock, ')
          ..write('reserved: $reserved, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InventoryMovementsTable extends InventoryMovements
    with TableInfo<$InventoryMovementsTable, InventoryMovementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _storeIdMeta =
      const VerificationMeta('storeId');
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
      'store_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _qtyDeltaMeta =
      const VerificationMeta('qtyDelta');
  @override
  late final GeneratedColumn<double> qtyDelta = GeneratedColumn<double>(
      'qty_delta', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _refTypeMeta =
      const VerificationMeta('refType');
  @override
  late final GeneratedColumn<String> refType = GeneratedColumn<String>(
      'ref_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _refIdMeta = const VerificationMeta('refId');
  @override
  late final GeneratedColumn<String> refId = GeneratedColumn<String>(
      'ref_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _terminalIdMeta =
      const VerificationMeta('terminalId');
  @override
  late final GeneratedColumn<String> terminalId = GeneratedColumn<String>(
      'terminal_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        storeId,
        productId,
        qtyDelta,
        reason,
        refType,
        refId,
        terminalId,
        userId,
        note,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_movements';
  @override
  VerificationContext validateIntegrity(
      Insertable<InventoryMovementRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(_storeIdMeta,
          storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta));
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('qty_delta')) {
      context.handle(_qtyDeltaMeta,
          qtyDelta.isAcceptableOrUnknown(data['qty_delta']!, _qtyDeltaMeta));
    } else if (isInserting) {
      context.missing(_qtyDeltaMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('ref_type')) {
      context.handle(_refTypeMeta,
          refType.isAcceptableOrUnknown(data['ref_type']!, _refTypeMeta));
    }
    if (data.containsKey('ref_id')) {
      context.handle(
          _refIdMeta, refId.isAcceptableOrUnknown(data['ref_id']!, _refIdMeta));
    }
    if (data.containsKey('terminal_id')) {
      context.handle(
          _terminalIdMeta,
          terminalId.isAcceptableOrUnknown(
              data['terminal_id']!, _terminalIdMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryMovementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryMovementRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      storeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}store_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      qtyDelta: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}qty_delta'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason'])!,
      refType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ref_type']),
      refId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ref_id']),
      terminalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}terminal_id']),
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $InventoryMovementsTable createAlias(String alias) {
    return $InventoryMovementsTable(attachedDatabase, alias);
  }
}

class InventoryMovementRow extends DataClass
    implements Insertable<InventoryMovementRow> {
  final String id;
  final String storeId;
  final String productId;
  final double qtyDelta;
  final String reason;
  final String? refType;
  final String? refId;
  final String? terminalId;
  final String? userId;
  final String? note;
  final DateTime createdAt;
  const InventoryMovementRow(
      {required this.id,
      required this.storeId,
      required this.productId,
      required this.qtyDelta,
      required this.reason,
      this.refType,
      this.refId,
      this.terminalId,
      this.userId,
      this.note,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['store_id'] = Variable<String>(storeId);
    map['product_id'] = Variable<String>(productId);
    map['qty_delta'] = Variable<double>(qtyDelta);
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || refType != null) {
      map['ref_type'] = Variable<String>(refType);
    }
    if (!nullToAbsent || refId != null) {
      map['ref_id'] = Variable<String>(refId);
    }
    if (!nullToAbsent || terminalId != null) {
      map['terminal_id'] = Variable<String>(terminalId);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  InventoryMovementsCompanion toCompanion(bool nullToAbsent) {
    return InventoryMovementsCompanion(
      id: Value(id),
      storeId: Value(storeId),
      productId: Value(productId),
      qtyDelta: Value(qtyDelta),
      reason: Value(reason),
      refType: refType == null && nullToAbsent
          ? const Value.absent()
          : Value(refType),
      refId:
          refId == null && nullToAbsent ? const Value.absent() : Value(refId),
      terminalId: terminalId == null && nullToAbsent
          ? const Value.absent()
          : Value(terminalId),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory InventoryMovementRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryMovementRow(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String>(json['storeId']),
      productId: serializer.fromJson<String>(json['productId']),
      qtyDelta: serializer.fromJson<double>(json['qtyDelta']),
      reason: serializer.fromJson<String>(json['reason']),
      refType: serializer.fromJson<String?>(json['refType']),
      refId: serializer.fromJson<String?>(json['refId']),
      terminalId: serializer.fromJson<String?>(json['terminalId']),
      userId: serializer.fromJson<String?>(json['userId']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'storeId': serializer.toJson<String>(storeId),
      'productId': serializer.toJson<String>(productId),
      'qtyDelta': serializer.toJson<double>(qtyDelta),
      'reason': serializer.toJson<String>(reason),
      'refType': serializer.toJson<String?>(refType),
      'refId': serializer.toJson<String?>(refId),
      'terminalId': serializer.toJson<String?>(terminalId),
      'userId': serializer.toJson<String?>(userId),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  InventoryMovementRow copyWith(
          {String? id,
          String? storeId,
          String? productId,
          double? qtyDelta,
          String? reason,
          Value<String?> refType = const Value.absent(),
          Value<String?> refId = const Value.absent(),
          Value<String?> terminalId = const Value.absent(),
          Value<String?> userId = const Value.absent(),
          Value<String?> note = const Value.absent(),
          DateTime? createdAt}) =>
      InventoryMovementRow(
        id: id ?? this.id,
        storeId: storeId ?? this.storeId,
        productId: productId ?? this.productId,
        qtyDelta: qtyDelta ?? this.qtyDelta,
        reason: reason ?? this.reason,
        refType: refType.present ? refType.value : this.refType,
        refId: refId.present ? refId.value : this.refId,
        terminalId: terminalId.present ? terminalId.value : this.terminalId,
        userId: userId.present ? userId.value : this.userId,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  InventoryMovementRow copyWithCompanion(InventoryMovementsCompanion data) {
    return InventoryMovementRow(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      productId: data.productId.present ? data.productId.value : this.productId,
      qtyDelta: data.qtyDelta.present ? data.qtyDelta.value : this.qtyDelta,
      reason: data.reason.present ? data.reason.value : this.reason,
      refType: data.refType.present ? data.refType.value : this.refType,
      refId: data.refId.present ? data.refId.value : this.refId,
      terminalId:
          data.terminalId.present ? data.terminalId.value : this.terminalId,
      userId: data.userId.present ? data.userId.value : this.userId,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryMovementRow(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('productId: $productId, ')
          ..write('qtyDelta: $qtyDelta, ')
          ..write('reason: $reason, ')
          ..write('refType: $refType, ')
          ..write('refId: $refId, ')
          ..write('terminalId: $terminalId, ')
          ..write('userId: $userId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, storeId, productId, qtyDelta, reason,
      refType, refId, terminalId, userId, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryMovementRow &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.productId == this.productId &&
          other.qtyDelta == this.qtyDelta &&
          other.reason == this.reason &&
          other.refType == this.refType &&
          other.refId == this.refId &&
          other.terminalId == this.terminalId &&
          other.userId == this.userId &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class InventoryMovementsCompanion
    extends UpdateCompanion<InventoryMovementRow> {
  final Value<String> id;
  final Value<String> storeId;
  final Value<String> productId;
  final Value<double> qtyDelta;
  final Value<String> reason;
  final Value<String?> refType;
  final Value<String?> refId;
  final Value<String?> terminalId;
  final Value<String?> userId;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const InventoryMovementsCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.productId = const Value.absent(),
    this.qtyDelta = const Value.absent(),
    this.reason = const Value.absent(),
    this.refType = const Value.absent(),
    this.refId = const Value.absent(),
    this.terminalId = const Value.absent(),
    this.userId = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventoryMovementsCompanion.insert({
    required String id,
    required String storeId,
    required String productId,
    required double qtyDelta,
    required String reason,
    this.refType = const Value.absent(),
    this.refId = const Value.absent(),
    this.terminalId = const Value.absent(),
    this.userId = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        storeId = Value(storeId),
        productId = Value(productId),
        qtyDelta = Value(qtyDelta),
        reason = Value(reason),
        createdAt = Value(createdAt);
  static Insertable<InventoryMovementRow> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? productId,
    Expression<double>? qtyDelta,
    Expression<String>? reason,
    Expression<String>? refType,
    Expression<String>? refId,
    Expression<String>? terminalId,
    Expression<String>? userId,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (productId != null) 'product_id': productId,
      if (qtyDelta != null) 'qty_delta': qtyDelta,
      if (reason != null) 'reason': reason,
      if (refType != null) 'ref_type': refType,
      if (refId != null) 'ref_id': refId,
      if (terminalId != null) 'terminal_id': terminalId,
      if (userId != null) 'user_id': userId,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventoryMovementsCompanion copyWith(
      {Value<String>? id,
      Value<String>? storeId,
      Value<String>? productId,
      Value<double>? qtyDelta,
      Value<String>? reason,
      Value<String?>? refType,
      Value<String?>? refId,
      Value<String?>? terminalId,
      Value<String?>? userId,
      Value<String?>? note,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return InventoryMovementsCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      productId: productId ?? this.productId,
      qtyDelta: qtyDelta ?? this.qtyDelta,
      reason: reason ?? this.reason,
      refType: refType ?? this.refType,
      refId: refId ?? this.refId,
      terminalId: terminalId ?? this.terminalId,
      userId: userId ?? this.userId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (qtyDelta.present) {
      map['qty_delta'] = Variable<double>(qtyDelta.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (refType.present) {
      map['ref_type'] = Variable<String>(refType.value);
    }
    if (refId.present) {
      map['ref_id'] = Variable<String>(refId.value);
    }
    if (terminalId.present) {
      map['terminal_id'] = Variable<String>(terminalId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryMovementsCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('productId: $productId, ')
          ..write('qtyDelta: $qtyDelta, ')
          ..write('reason: $reason, ')
          ..write('refType: $refType, ')
          ..write('refId: $refId, ')
          ..write('terminalId: $terminalId, ')
          ..write('userId: $userId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransferOrdersTable extends TransferOrders
    with TableInfo<$TransferOrdersTable, TransferOrderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransferOrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fromStoreIdMeta =
      const VerificationMeta('fromStoreId');
  @override
  late final GeneratedColumn<String> fromStoreId = GeneratedColumn<String>(
      'from_store_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _toStoreIdMeta =
      const VerificationMeta('toStoreId');
  @override
  late final GeneratedColumn<String> toStoreId = GeneratedColumn<String>(
      'to_store_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('draft'));
  static const VerificationMeta _dispatchedAtMeta =
      const VerificationMeta('dispatchedAt');
  @override
  late final GeneratedColumn<DateTime> dispatchedAt = GeneratedColumn<DateTime>(
      'dispatched_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _receivedAtMeta =
      const VerificationMeta('receivedAt');
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
      'received_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        fromStoreId,
        toStoreId,
        status,
        dispatchedAt,
        receivedAt,
        note,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfer_orders';
  @override
  VerificationContext validateIntegrity(Insertable<TransferOrderRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('from_store_id')) {
      context.handle(
          _fromStoreIdMeta,
          fromStoreId.isAcceptableOrUnknown(
              data['from_store_id']!, _fromStoreIdMeta));
    } else if (isInserting) {
      context.missing(_fromStoreIdMeta);
    }
    if (data.containsKey('to_store_id')) {
      context.handle(
          _toStoreIdMeta,
          toStoreId.isAcceptableOrUnknown(
              data['to_store_id']!, _toStoreIdMeta));
    } else if (isInserting) {
      context.missing(_toStoreIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('dispatched_at')) {
      context.handle(
          _dispatchedAtMeta,
          dispatchedAt.isAcceptableOrUnknown(
              data['dispatched_at']!, _dispatchedAtMeta));
    }
    if (data.containsKey('received_at')) {
      context.handle(
          _receivedAtMeta,
          receivedAt.isAcceptableOrUnknown(
              data['received_at']!, _receivedAtMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransferOrderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransferOrderRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      fromStoreId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}from_store_id'])!,
      toStoreId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}to_store_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      dispatchedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}dispatched_at']),
      receivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}received_at']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TransferOrdersTable createAlias(String alias) {
    return $TransferOrdersTable(attachedDatabase, alias);
  }
}

class TransferOrderRow extends DataClass
    implements Insertable<TransferOrderRow> {
  final String id;
  final String fromStoreId;
  final String toStoreId;
  final String status;
  final DateTime? dispatchedAt;
  final DateTime? receivedAt;
  final String? note;
  final DateTime createdAt;
  const TransferOrderRow(
      {required this.id,
      required this.fromStoreId,
      required this.toStoreId,
      required this.status,
      this.dispatchedAt,
      this.receivedAt,
      this.note,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['from_store_id'] = Variable<String>(fromStoreId);
    map['to_store_id'] = Variable<String>(toStoreId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || dispatchedAt != null) {
      map['dispatched_at'] = Variable<DateTime>(dispatchedAt);
    }
    if (!nullToAbsent || receivedAt != null) {
      map['received_at'] = Variable<DateTime>(receivedAt);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TransferOrdersCompanion toCompanion(bool nullToAbsent) {
    return TransferOrdersCompanion(
      id: Value(id),
      fromStoreId: Value(fromStoreId),
      toStoreId: Value(toStoreId),
      status: Value(status),
      dispatchedAt: dispatchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dispatchedAt),
      receivedAt: receivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(receivedAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory TransferOrderRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransferOrderRow(
      id: serializer.fromJson<String>(json['id']),
      fromStoreId: serializer.fromJson<String>(json['fromStoreId']),
      toStoreId: serializer.fromJson<String>(json['toStoreId']),
      status: serializer.fromJson<String>(json['status']),
      dispatchedAt: serializer.fromJson<DateTime?>(json['dispatchedAt']),
      receivedAt: serializer.fromJson<DateTime?>(json['receivedAt']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fromStoreId': serializer.toJson<String>(fromStoreId),
      'toStoreId': serializer.toJson<String>(toStoreId),
      'status': serializer.toJson<String>(status),
      'dispatchedAt': serializer.toJson<DateTime?>(dispatchedAt),
      'receivedAt': serializer.toJson<DateTime?>(receivedAt),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TransferOrderRow copyWith(
          {String? id,
          String? fromStoreId,
          String? toStoreId,
          String? status,
          Value<DateTime?> dispatchedAt = const Value.absent(),
          Value<DateTime?> receivedAt = const Value.absent(),
          Value<String?> note = const Value.absent(),
          DateTime? createdAt}) =>
      TransferOrderRow(
        id: id ?? this.id,
        fromStoreId: fromStoreId ?? this.fromStoreId,
        toStoreId: toStoreId ?? this.toStoreId,
        status: status ?? this.status,
        dispatchedAt:
            dispatchedAt.present ? dispatchedAt.value : this.dispatchedAt,
        receivedAt: receivedAt.present ? receivedAt.value : this.receivedAt,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  TransferOrderRow copyWithCompanion(TransferOrdersCompanion data) {
    return TransferOrderRow(
      id: data.id.present ? data.id.value : this.id,
      fromStoreId:
          data.fromStoreId.present ? data.fromStoreId.value : this.fromStoreId,
      toStoreId: data.toStoreId.present ? data.toStoreId.value : this.toStoreId,
      status: data.status.present ? data.status.value : this.status,
      dispatchedAt: data.dispatchedAt.present
          ? data.dispatchedAt.value
          : this.dispatchedAt,
      receivedAt:
          data.receivedAt.present ? data.receivedAt.value : this.receivedAt,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransferOrderRow(')
          ..write('id: $id, ')
          ..write('fromStoreId: $fromStoreId, ')
          ..write('toStoreId: $toStoreId, ')
          ..write('status: $status, ')
          ..write('dispatchedAt: $dispatchedAt, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fromStoreId, toStoreId, status,
      dispatchedAt, receivedAt, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransferOrderRow &&
          other.id == this.id &&
          other.fromStoreId == this.fromStoreId &&
          other.toStoreId == this.toStoreId &&
          other.status == this.status &&
          other.dispatchedAt == this.dispatchedAt &&
          other.receivedAt == this.receivedAt &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class TransferOrdersCompanion extends UpdateCompanion<TransferOrderRow> {
  final Value<String> id;
  final Value<String> fromStoreId;
  final Value<String> toStoreId;
  final Value<String> status;
  final Value<DateTime?> dispatchedAt;
  final Value<DateTime?> receivedAt;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TransferOrdersCompanion({
    this.id = const Value.absent(),
    this.fromStoreId = const Value.absent(),
    this.toStoreId = const Value.absent(),
    this.status = const Value.absent(),
    this.dispatchedAt = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransferOrdersCompanion.insert({
    required String id,
    required String fromStoreId,
    required String toStoreId,
    this.status = const Value.absent(),
    this.dispatchedAt = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        fromStoreId = Value(fromStoreId),
        toStoreId = Value(toStoreId),
        createdAt = Value(createdAt);
  static Insertable<TransferOrderRow> custom({
    Expression<String>? id,
    Expression<String>? fromStoreId,
    Expression<String>? toStoreId,
    Expression<String>? status,
    Expression<DateTime>? dispatchedAt,
    Expression<DateTime>? receivedAt,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fromStoreId != null) 'from_store_id': fromStoreId,
      if (toStoreId != null) 'to_store_id': toStoreId,
      if (status != null) 'status': status,
      if (dispatchedAt != null) 'dispatched_at': dispatchedAt,
      if (receivedAt != null) 'received_at': receivedAt,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransferOrdersCompanion copyWith(
      {Value<String>? id,
      Value<String>? fromStoreId,
      Value<String>? toStoreId,
      Value<String>? status,
      Value<DateTime?>? dispatchedAt,
      Value<DateTime?>? receivedAt,
      Value<String?>? note,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return TransferOrdersCompanion(
      id: id ?? this.id,
      fromStoreId: fromStoreId ?? this.fromStoreId,
      toStoreId: toStoreId ?? this.toStoreId,
      status: status ?? this.status,
      dispatchedAt: dispatchedAt ?? this.dispatchedAt,
      receivedAt: receivedAt ?? this.receivedAt,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fromStoreId.present) {
      map['from_store_id'] = Variable<String>(fromStoreId.value);
    }
    if (toStoreId.present) {
      map['to_store_id'] = Variable<String>(toStoreId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (dispatchedAt.present) {
      map['dispatched_at'] = Variable<DateTime>(dispatchedAt.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransferOrdersCompanion(')
          ..write('id: $id, ')
          ..write('fromStoreId: $fromStoreId, ')
          ..write('toStoreId: $toStoreId, ')
          ..write('status: $status, ')
          ..write('dispatchedAt: $dispatchedAt, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransferLinesTable extends TransferLines
    with TableInfo<$TransferLinesTable, TransferLineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransferLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _transferIdMeta =
      const VerificationMeta('transferId');
  @override
  late final GeneratedColumn<String> transferId = GeneratedColumn<String>(
      'transfer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<double> qty = GeneratedColumn<double>(
      'qty', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _receivedQtyMeta =
      const VerificationMeta('receivedQty');
  @override
  late final GeneratedColumn<double> receivedQty = GeneratedColumn<double>(
      'received_qty', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, transferId, productId, qty, receivedQty];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfer_lines';
  @override
  VerificationContext validateIntegrity(Insertable<TransferLineRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transfer_id')) {
      context.handle(
          _transferIdMeta,
          transferId.isAcceptableOrUnknown(
              data['transfer_id']!, _transferIdMeta));
    } else if (isInserting) {
      context.missing(_transferIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
          _qtyMeta, qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta));
    } else if (isInserting) {
      context.missing(_qtyMeta);
    }
    if (data.containsKey('received_qty')) {
      context.handle(
          _receivedQtyMeta,
          receivedQty.isAcceptableOrUnknown(
              data['received_qty']!, _receivedQtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransferLineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransferLineRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      transferId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transfer_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      qty: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}qty'])!,
      receivedQty: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}received_qty']),
    );
  }

  @override
  $TransferLinesTable createAlias(String alias) {
    return $TransferLinesTable(attachedDatabase, alias);
  }
}

class TransferLineRow extends DataClass implements Insertable<TransferLineRow> {
  final String id;
  final String transferId;
  final String productId;
  final double qty;
  final double? receivedQty;
  const TransferLineRow(
      {required this.id,
      required this.transferId,
      required this.productId,
      required this.qty,
      this.receivedQty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transfer_id'] = Variable<String>(transferId);
    map['product_id'] = Variable<String>(productId);
    map['qty'] = Variable<double>(qty);
    if (!nullToAbsent || receivedQty != null) {
      map['received_qty'] = Variable<double>(receivedQty);
    }
    return map;
  }

  TransferLinesCompanion toCompanion(bool nullToAbsent) {
    return TransferLinesCompanion(
      id: Value(id),
      transferId: Value(transferId),
      productId: Value(productId),
      qty: Value(qty),
      receivedQty: receivedQty == null && nullToAbsent
          ? const Value.absent()
          : Value(receivedQty),
    );
  }

  factory TransferLineRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransferLineRow(
      id: serializer.fromJson<String>(json['id']),
      transferId: serializer.fromJson<String>(json['transferId']),
      productId: serializer.fromJson<String>(json['productId']),
      qty: serializer.fromJson<double>(json['qty']),
      receivedQty: serializer.fromJson<double?>(json['receivedQty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transferId': serializer.toJson<String>(transferId),
      'productId': serializer.toJson<String>(productId),
      'qty': serializer.toJson<double>(qty),
      'receivedQty': serializer.toJson<double?>(receivedQty),
    };
  }

  TransferLineRow copyWith(
          {String? id,
          String? transferId,
          String? productId,
          double? qty,
          Value<double?> receivedQty = const Value.absent()}) =>
      TransferLineRow(
        id: id ?? this.id,
        transferId: transferId ?? this.transferId,
        productId: productId ?? this.productId,
        qty: qty ?? this.qty,
        receivedQty: receivedQty.present ? receivedQty.value : this.receivedQty,
      );
  TransferLineRow copyWithCompanion(TransferLinesCompanion data) {
    return TransferLineRow(
      id: data.id.present ? data.id.value : this.id,
      transferId:
          data.transferId.present ? data.transferId.value : this.transferId,
      productId: data.productId.present ? data.productId.value : this.productId,
      qty: data.qty.present ? data.qty.value : this.qty,
      receivedQty:
          data.receivedQty.present ? data.receivedQty.value : this.receivedQty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransferLineRow(')
          ..write('id: $id, ')
          ..write('transferId: $transferId, ')
          ..write('productId: $productId, ')
          ..write('qty: $qty, ')
          ..write('receivedQty: $receivedQty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, transferId, productId, qty, receivedQty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransferLineRow &&
          other.id == this.id &&
          other.transferId == this.transferId &&
          other.productId == this.productId &&
          other.qty == this.qty &&
          other.receivedQty == this.receivedQty);
}

class TransferLinesCompanion extends UpdateCompanion<TransferLineRow> {
  final Value<String> id;
  final Value<String> transferId;
  final Value<String> productId;
  final Value<double> qty;
  final Value<double?> receivedQty;
  final Value<int> rowid;
  const TransferLinesCompanion({
    this.id = const Value.absent(),
    this.transferId = const Value.absent(),
    this.productId = const Value.absent(),
    this.qty = const Value.absent(),
    this.receivedQty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransferLinesCompanion.insert({
    required String id,
    required String transferId,
    required String productId,
    required double qty,
    this.receivedQty = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        transferId = Value(transferId),
        productId = Value(productId),
        qty = Value(qty);
  static Insertable<TransferLineRow> custom({
    Expression<String>? id,
    Expression<String>? transferId,
    Expression<String>? productId,
    Expression<double>? qty,
    Expression<double>? receivedQty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transferId != null) 'transfer_id': transferId,
      if (productId != null) 'product_id': productId,
      if (qty != null) 'qty': qty,
      if (receivedQty != null) 'received_qty': receivedQty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransferLinesCompanion copyWith(
      {Value<String>? id,
      Value<String>? transferId,
      Value<String>? productId,
      Value<double>? qty,
      Value<double?>? receivedQty,
      Value<int>? rowid}) {
    return TransferLinesCompanion(
      id: id ?? this.id,
      transferId: transferId ?? this.transferId,
      productId: productId ?? this.productId,
      qty: qty ?? this.qty,
      receivedQty: receivedQty ?? this.receivedQty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transferId.present) {
      map['transfer_id'] = Variable<String>(transferId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (qty.present) {
      map['qty'] = Variable<double>(qty.value);
    }
    if (receivedQty.present) {
      map['received_qty'] = Variable<double>(receivedQty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransferLinesCompanion(')
          ..write('id: $id, ')
          ..write('transferId: $transferId, ')
          ..write('productId: $productId, ')
          ..write('qty: $qty, ')
          ..write('receivedQty: $receivedQty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StocktakesTable extends Stocktakes
    with TableInfo<$StocktakesTable, StocktakeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StocktakesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _storeIdMeta =
      const VerificationMeta('storeId');
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
      'store_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, storeId, completedAt, note, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stocktakes';
  @override
  VerificationContext validateIntegrity(Insertable<StocktakeRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(_storeIdMeta,
          storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta));
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StocktakeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StocktakeRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      storeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}store_id'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $StocktakesTable createAlias(String alias) {
    return $StocktakesTable(attachedDatabase, alias);
  }
}

class StocktakeRow extends DataClass implements Insertable<StocktakeRow> {
  final String id;
  final String storeId;
  final DateTime? completedAt;
  final String? note;
  final DateTime createdAt;
  const StocktakeRow(
      {required this.id,
      required this.storeId,
      this.completedAt,
      this.note,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['store_id'] = Variable<String>(storeId);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StocktakesCompanion toCompanion(bool nullToAbsent) {
    return StocktakesCompanion(
      id: Value(id),
      storeId: Value(storeId),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory StocktakeRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StocktakeRow(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String>(json['storeId']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'storeId': serializer.toJson<String>(storeId),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StocktakeRow copyWith(
          {String? id,
          String? storeId,
          Value<DateTime?> completedAt = const Value.absent(),
          Value<String?> note = const Value.absent(),
          DateTime? createdAt}) =>
      StocktakeRow(
        id: id ?? this.id,
        storeId: storeId ?? this.storeId,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  StocktakeRow copyWithCompanion(StocktakesCompanion data) {
    return StocktakeRow(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StocktakeRow(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('completedAt: $completedAt, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, storeId, completedAt, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StocktakeRow &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.completedAt == this.completedAt &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class StocktakesCompanion extends UpdateCompanion<StocktakeRow> {
  final Value<String> id;
  final Value<String> storeId;
  final Value<DateTime?> completedAt;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const StocktakesCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StocktakesCompanion.insert({
    required String id,
    required String storeId,
    this.completedAt = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        storeId = Value(storeId),
        createdAt = Value(createdAt);
  static Insertable<StocktakeRow> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<DateTime>? completedAt,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (completedAt != null) 'completed_at': completedAt,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StocktakesCompanion copyWith(
      {Value<String>? id,
      Value<String>? storeId,
      Value<DateTime?>? completedAt,
      Value<String?>? note,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return StocktakesCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      completedAt: completedAt ?? this.completedAt,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StocktakesCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('completedAt: $completedAt, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StocktakeLinesTable extends StocktakeLines
    with TableInfo<$StocktakeLinesTable, StocktakeLineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StocktakeLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stocktakeIdMeta =
      const VerificationMeta('stocktakeId');
  @override
  late final GeneratedColumn<String> stocktakeId = GeneratedColumn<String>(
      'stocktake_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _expectedQtyMeta =
      const VerificationMeta('expectedQty');
  @override
  late final GeneratedColumn<double> expectedQty = GeneratedColumn<double>(
      'expected_qty', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _actualQtyMeta =
      const VerificationMeta('actualQty');
  @override
  late final GeneratedColumn<double> actualQty = GeneratedColumn<double>(
      'actual_qty', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, stocktakeId, productId, expectedQty, actualQty];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stocktake_lines';
  @override
  VerificationContext validateIntegrity(Insertable<StocktakeLineRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('stocktake_id')) {
      context.handle(
          _stocktakeIdMeta,
          stocktakeId.isAcceptableOrUnknown(
              data['stocktake_id']!, _stocktakeIdMeta));
    } else if (isInserting) {
      context.missing(_stocktakeIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('expected_qty')) {
      context.handle(
          _expectedQtyMeta,
          expectedQty.isAcceptableOrUnknown(
              data['expected_qty']!, _expectedQtyMeta));
    } else if (isInserting) {
      context.missing(_expectedQtyMeta);
    }
    if (data.containsKey('actual_qty')) {
      context.handle(_actualQtyMeta,
          actualQty.isAcceptableOrUnknown(data['actual_qty']!, _actualQtyMeta));
    } else if (isInserting) {
      context.missing(_actualQtyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StocktakeLineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StocktakeLineRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      stocktakeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stocktake_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      expectedQty: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}expected_qty'])!,
      actualQty: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}actual_qty'])!,
    );
  }

  @override
  $StocktakeLinesTable createAlias(String alias) {
    return $StocktakeLinesTable(attachedDatabase, alias);
  }
}

class StocktakeLineRow extends DataClass
    implements Insertable<StocktakeLineRow> {
  final String id;
  final String stocktakeId;
  final String productId;
  final double expectedQty;
  final double actualQty;
  const StocktakeLineRow(
      {required this.id,
      required this.stocktakeId,
      required this.productId,
      required this.expectedQty,
      required this.actualQty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['stocktake_id'] = Variable<String>(stocktakeId);
    map['product_id'] = Variable<String>(productId);
    map['expected_qty'] = Variable<double>(expectedQty);
    map['actual_qty'] = Variable<double>(actualQty);
    return map;
  }

  StocktakeLinesCompanion toCompanion(bool nullToAbsent) {
    return StocktakeLinesCompanion(
      id: Value(id),
      stocktakeId: Value(stocktakeId),
      productId: Value(productId),
      expectedQty: Value(expectedQty),
      actualQty: Value(actualQty),
    );
  }

  factory StocktakeLineRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StocktakeLineRow(
      id: serializer.fromJson<String>(json['id']),
      stocktakeId: serializer.fromJson<String>(json['stocktakeId']),
      productId: serializer.fromJson<String>(json['productId']),
      expectedQty: serializer.fromJson<double>(json['expectedQty']),
      actualQty: serializer.fromJson<double>(json['actualQty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'stocktakeId': serializer.toJson<String>(stocktakeId),
      'productId': serializer.toJson<String>(productId),
      'expectedQty': serializer.toJson<double>(expectedQty),
      'actualQty': serializer.toJson<double>(actualQty),
    };
  }

  StocktakeLineRow copyWith(
          {String? id,
          String? stocktakeId,
          String? productId,
          double? expectedQty,
          double? actualQty}) =>
      StocktakeLineRow(
        id: id ?? this.id,
        stocktakeId: stocktakeId ?? this.stocktakeId,
        productId: productId ?? this.productId,
        expectedQty: expectedQty ?? this.expectedQty,
        actualQty: actualQty ?? this.actualQty,
      );
  StocktakeLineRow copyWithCompanion(StocktakeLinesCompanion data) {
    return StocktakeLineRow(
      id: data.id.present ? data.id.value : this.id,
      stocktakeId:
          data.stocktakeId.present ? data.stocktakeId.value : this.stocktakeId,
      productId: data.productId.present ? data.productId.value : this.productId,
      expectedQty:
          data.expectedQty.present ? data.expectedQty.value : this.expectedQty,
      actualQty: data.actualQty.present ? data.actualQty.value : this.actualQty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StocktakeLineRow(')
          ..write('id: $id, ')
          ..write('stocktakeId: $stocktakeId, ')
          ..write('productId: $productId, ')
          ..write('expectedQty: $expectedQty, ')
          ..write('actualQty: $actualQty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, stocktakeId, productId, expectedQty, actualQty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StocktakeLineRow &&
          other.id == this.id &&
          other.stocktakeId == this.stocktakeId &&
          other.productId == this.productId &&
          other.expectedQty == this.expectedQty &&
          other.actualQty == this.actualQty);
}

class StocktakeLinesCompanion extends UpdateCompanion<StocktakeLineRow> {
  final Value<String> id;
  final Value<String> stocktakeId;
  final Value<String> productId;
  final Value<double> expectedQty;
  final Value<double> actualQty;
  final Value<int> rowid;
  const StocktakeLinesCompanion({
    this.id = const Value.absent(),
    this.stocktakeId = const Value.absent(),
    this.productId = const Value.absent(),
    this.expectedQty = const Value.absent(),
    this.actualQty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StocktakeLinesCompanion.insert({
    required String id,
    required String stocktakeId,
    required String productId,
    required double expectedQty,
    required double actualQty,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        stocktakeId = Value(stocktakeId),
        productId = Value(productId),
        expectedQty = Value(expectedQty),
        actualQty = Value(actualQty);
  static Insertable<StocktakeLineRow> custom({
    Expression<String>? id,
    Expression<String>? stocktakeId,
    Expression<String>? productId,
    Expression<double>? expectedQty,
    Expression<double>? actualQty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stocktakeId != null) 'stocktake_id': stocktakeId,
      if (productId != null) 'product_id': productId,
      if (expectedQty != null) 'expected_qty': expectedQty,
      if (actualQty != null) 'actual_qty': actualQty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StocktakeLinesCompanion copyWith(
      {Value<String>? id,
      Value<String>? stocktakeId,
      Value<String>? productId,
      Value<double>? expectedQty,
      Value<double>? actualQty,
      Value<int>? rowid}) {
    return StocktakeLinesCompanion(
      id: id ?? this.id,
      stocktakeId: stocktakeId ?? this.stocktakeId,
      productId: productId ?? this.productId,
      expectedQty: expectedQty ?? this.expectedQty,
      actualQty: actualQty ?? this.actualQty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (stocktakeId.present) {
      map['stocktake_id'] = Variable<String>(stocktakeId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (expectedQty.present) {
      map['expected_qty'] = Variable<double>(expectedQty.value);
    }
    if (actualQty.present) {
      map['actual_qty'] = Variable<double>(actualQty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StocktakeLinesCompanion(')
          ..write('id: $id, ')
          ..write('stocktakeId: $stocktakeId, ')
          ..write('productId: $productId, ')
          ..write('expectedQty: $expectedQty, ')
          ..write('actualQty: $actualQty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PromotionsTable extends Promotions
    with TableInfo<$PromotionsTable, PromotionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PromotionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _strategyMeta =
      const VerificationMeta('strategy');
  @override
  late final GeneratedColumn<String> strategy = GeneratedColumn<String>(
      'strategy', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _configJsonMeta =
      const VerificationMeta('configJson');
  @override
  late final GeneratedColumn<String> configJson = GeneratedColumn<String>(
      'config_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _startsAtMeta =
      const VerificationMeta('startsAt');
  @override
  late final GeneratedColumn<DateTime> startsAt = GeneratedColumn<DateTime>(
      'starts_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _endsAtMeta = const VerificationMeta('endsAt');
  @override
  late final GeneratedColumn<DateTime> endsAt = GeneratedColumn<DateTime>(
      'ends_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _stackableMeta =
      const VerificationMeta('stackable');
  @override
  late final GeneratedColumn<bool> stackable = GeneratedColumn<bool>(
      'stackable', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("stackable" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _applicableProductIdsJsonMeta =
      const VerificationMeta('applicableProductIdsJson');
  @override
  late final GeneratedColumn<String> applicableProductIdsJson =
      GeneratedColumn<String>('applicable_product_ids_json', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('[]'));
  static const VerificationMeta _applicableCategoryIdsJsonMeta =
      const VerificationMeta('applicableCategoryIdsJson');
  @override
  late final GeneratedColumn<String> applicableCategoryIdsJson =
      GeneratedColumn<String>(
          'applicable_category_ids_json', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('[]'));
  static const VerificationMeta _memberLevelIdsJsonMeta =
      const VerificationMeta('memberLevelIdsJson');
  @override
  late final GeneratedColumn<String> memberLevelIdsJson =
      GeneratedColumn<String>('member_level_ids_json', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('[]'));
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        strategy,
        configJson,
        priority,
        startsAt,
        endsAt,
        isActive,
        stackable,
        applicableProductIdsJson,
        applicableCategoryIdsJson,
        memberLevelIdsJson,
        description,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'promotions';
  @override
  VerificationContext validateIntegrity(Insertable<PromotionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('strategy')) {
      context.handle(_strategyMeta,
          strategy.isAcceptableOrUnknown(data['strategy']!, _strategyMeta));
    } else if (isInserting) {
      context.missing(_strategyMeta);
    }
    if (data.containsKey('config_json')) {
      context.handle(
          _configJsonMeta,
          configJson.isAcceptableOrUnknown(
              data['config_json']!, _configJsonMeta));
    } else if (isInserting) {
      context.missing(_configJsonMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('starts_at')) {
      context.handle(_startsAtMeta,
          startsAt.isAcceptableOrUnknown(data['starts_at']!, _startsAtMeta));
    }
    if (data.containsKey('ends_at')) {
      context.handle(_endsAtMeta,
          endsAt.isAcceptableOrUnknown(data['ends_at']!, _endsAtMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('stackable')) {
      context.handle(_stackableMeta,
          stackable.isAcceptableOrUnknown(data['stackable']!, _stackableMeta));
    }
    if (data.containsKey('applicable_product_ids_json')) {
      context.handle(
          _applicableProductIdsJsonMeta,
          applicableProductIdsJson.isAcceptableOrUnknown(
              data['applicable_product_ids_json']!,
              _applicableProductIdsJsonMeta));
    }
    if (data.containsKey('applicable_category_ids_json')) {
      context.handle(
          _applicableCategoryIdsJsonMeta,
          applicableCategoryIdsJson.isAcceptableOrUnknown(
              data['applicable_category_ids_json']!,
              _applicableCategoryIdsJsonMeta));
    }
    if (data.containsKey('member_level_ids_json')) {
      context.handle(
          _memberLevelIdsJsonMeta,
          memberLevelIdsJson.isAcceptableOrUnknown(
              data['member_level_ids_json']!, _memberLevelIdsJsonMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PromotionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PromotionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      strategy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}strategy'])!,
      configJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}config_json'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      startsAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}starts_at']),
      endsAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ends_at']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      stackable: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}stackable'])!,
      applicableProductIdsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}applicable_product_ids_json'])!,
      applicableCategoryIdsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}applicable_category_ids_json'])!,
      memberLevelIdsJson: attachedDatabase.typeMapping.read(DriftSqlType.string,
          data['${effectivePrefix}member_level_ids_json'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $PromotionsTable createAlias(String alias) {
    return $PromotionsTable(attachedDatabase, alias);
  }
}

class PromotionRow extends DataClass implements Insertable<PromotionRow> {
  final String id;
  final String name;
  final String strategy;
  final String configJson;
  final int priority;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isActive;
  final bool stackable;
  final String applicableProductIdsJson;
  final String applicableCategoryIdsJson;
  final String memberLevelIdsJson;
  final String? description;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const PromotionRow(
      {required this.id,
      required this.name,
      required this.strategy,
      required this.configJson,
      required this.priority,
      this.startsAt,
      this.endsAt,
      required this.isActive,
      required this.stackable,
      required this.applicableProductIdsJson,
      required this.applicableCategoryIdsJson,
      required this.memberLevelIdsJson,
      this.description,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['strategy'] = Variable<String>(strategy);
    map['config_json'] = Variable<String>(configJson);
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || startsAt != null) {
      map['starts_at'] = Variable<DateTime>(startsAt);
    }
    if (!nullToAbsent || endsAt != null) {
      map['ends_at'] = Variable<DateTime>(endsAt);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['stackable'] = Variable<bool>(stackable);
    map['applicable_product_ids_json'] =
        Variable<String>(applicableProductIdsJson);
    map['applicable_category_ids_json'] =
        Variable<String>(applicableCategoryIdsJson);
    map['member_level_ids_json'] = Variable<String>(memberLevelIdsJson);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  PromotionsCompanion toCompanion(bool nullToAbsent) {
    return PromotionsCompanion(
      id: Value(id),
      name: Value(name),
      strategy: Value(strategy),
      configJson: Value(configJson),
      priority: Value(priority),
      startsAt: startsAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startsAt),
      endsAt:
          endsAt == null && nullToAbsent ? const Value.absent() : Value(endsAt),
      isActive: Value(isActive),
      stackable: Value(stackable),
      applicableProductIdsJson: Value(applicableProductIdsJson),
      applicableCategoryIdsJson: Value(applicableCategoryIdsJson),
      memberLevelIdsJson: Value(memberLevelIdsJson),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory PromotionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PromotionRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      strategy: serializer.fromJson<String>(json['strategy']),
      configJson: serializer.fromJson<String>(json['configJson']),
      priority: serializer.fromJson<int>(json['priority']),
      startsAt: serializer.fromJson<DateTime?>(json['startsAt']),
      endsAt: serializer.fromJson<DateTime?>(json['endsAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      stackable: serializer.fromJson<bool>(json['stackable']),
      applicableProductIdsJson:
          serializer.fromJson<String>(json['applicableProductIdsJson']),
      applicableCategoryIdsJson:
          serializer.fromJson<String>(json['applicableCategoryIdsJson']),
      memberLevelIdsJson:
          serializer.fromJson<String>(json['memberLevelIdsJson']),
      description: serializer.fromJson<String?>(json['description']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'strategy': serializer.toJson<String>(strategy),
      'configJson': serializer.toJson<String>(configJson),
      'priority': serializer.toJson<int>(priority),
      'startsAt': serializer.toJson<DateTime?>(startsAt),
      'endsAt': serializer.toJson<DateTime?>(endsAt),
      'isActive': serializer.toJson<bool>(isActive),
      'stackable': serializer.toJson<bool>(stackable),
      'applicableProductIdsJson':
          serializer.toJson<String>(applicableProductIdsJson),
      'applicableCategoryIdsJson':
          serializer.toJson<String>(applicableCategoryIdsJson),
      'memberLevelIdsJson': serializer.toJson<String>(memberLevelIdsJson),
      'description': serializer.toJson<String?>(description),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  PromotionRow copyWith(
          {String? id,
          String? name,
          String? strategy,
          String? configJson,
          int? priority,
          Value<DateTime?> startsAt = const Value.absent(),
          Value<DateTime?> endsAt = const Value.absent(),
          bool? isActive,
          bool? stackable,
          String? applicableProductIdsJson,
          String? applicableCategoryIdsJson,
          String? memberLevelIdsJson,
          Value<String?> description = const Value.absent(),
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      PromotionRow(
        id: id ?? this.id,
        name: name ?? this.name,
        strategy: strategy ?? this.strategy,
        configJson: configJson ?? this.configJson,
        priority: priority ?? this.priority,
        startsAt: startsAt.present ? startsAt.value : this.startsAt,
        endsAt: endsAt.present ? endsAt.value : this.endsAt,
        isActive: isActive ?? this.isActive,
        stackable: stackable ?? this.stackable,
        applicableProductIdsJson:
            applicableProductIdsJson ?? this.applicableProductIdsJson,
        applicableCategoryIdsJson:
            applicableCategoryIdsJson ?? this.applicableCategoryIdsJson,
        memberLevelIdsJson: memberLevelIdsJson ?? this.memberLevelIdsJson,
        description: description.present ? description.value : this.description,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  PromotionRow copyWithCompanion(PromotionsCompanion data) {
    return PromotionRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      strategy: data.strategy.present ? data.strategy.value : this.strategy,
      configJson:
          data.configJson.present ? data.configJson.value : this.configJson,
      priority: data.priority.present ? data.priority.value : this.priority,
      startsAt: data.startsAt.present ? data.startsAt.value : this.startsAt,
      endsAt: data.endsAt.present ? data.endsAt.value : this.endsAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      stackable: data.stackable.present ? data.stackable.value : this.stackable,
      applicableProductIdsJson: data.applicableProductIdsJson.present
          ? data.applicableProductIdsJson.value
          : this.applicableProductIdsJson,
      applicableCategoryIdsJson: data.applicableCategoryIdsJson.present
          ? data.applicableCategoryIdsJson.value
          : this.applicableCategoryIdsJson,
      memberLevelIdsJson: data.memberLevelIdsJson.present
          ? data.memberLevelIdsJson.value
          : this.memberLevelIdsJson,
      description:
          data.description.present ? data.description.value : this.description,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PromotionRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('strategy: $strategy, ')
          ..write('configJson: $configJson, ')
          ..write('priority: $priority, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('isActive: $isActive, ')
          ..write('stackable: $stackable, ')
          ..write('applicableProductIdsJson: $applicableProductIdsJson, ')
          ..write('applicableCategoryIdsJson: $applicableCategoryIdsJson, ')
          ..write('memberLevelIdsJson: $memberLevelIdsJson, ')
          ..write('description: $description, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      strategy,
      configJson,
      priority,
      startsAt,
      endsAt,
      isActive,
      stackable,
      applicableProductIdsJson,
      applicableCategoryIdsJson,
      memberLevelIdsJson,
      description,
      updatedAt,
      deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PromotionRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.strategy == this.strategy &&
          other.configJson == this.configJson &&
          other.priority == this.priority &&
          other.startsAt == this.startsAt &&
          other.endsAt == this.endsAt &&
          other.isActive == this.isActive &&
          other.stackable == this.stackable &&
          other.applicableProductIdsJson == this.applicableProductIdsJson &&
          other.applicableCategoryIdsJson == this.applicableCategoryIdsJson &&
          other.memberLevelIdsJson == this.memberLevelIdsJson &&
          other.description == this.description &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class PromotionsCompanion extends UpdateCompanion<PromotionRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> strategy;
  final Value<String> configJson;
  final Value<int> priority;
  final Value<DateTime?> startsAt;
  final Value<DateTime?> endsAt;
  final Value<bool> isActive;
  final Value<bool> stackable;
  final Value<String> applicableProductIdsJson;
  final Value<String> applicableCategoryIdsJson;
  final Value<String> memberLevelIdsJson;
  final Value<String?> description;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const PromotionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.strategy = const Value.absent(),
    this.configJson = const Value.absent(),
    this.priority = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.endsAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.stackable = const Value.absent(),
    this.applicableProductIdsJson = const Value.absent(),
    this.applicableCategoryIdsJson = const Value.absent(),
    this.memberLevelIdsJson = const Value.absent(),
    this.description = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PromotionsCompanion.insert({
    required String id,
    required String name,
    required String strategy,
    required String configJson,
    this.priority = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.endsAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.stackable = const Value.absent(),
    this.applicableProductIdsJson = const Value.absent(),
    this.applicableCategoryIdsJson = const Value.absent(),
    this.memberLevelIdsJson = const Value.absent(),
    this.description = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        strategy = Value(strategy),
        configJson = Value(configJson),
        updatedAt = Value(updatedAt);
  static Insertable<PromotionRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? strategy,
    Expression<String>? configJson,
    Expression<int>? priority,
    Expression<DateTime>? startsAt,
    Expression<DateTime>? endsAt,
    Expression<bool>? isActive,
    Expression<bool>? stackable,
    Expression<String>? applicableProductIdsJson,
    Expression<String>? applicableCategoryIdsJson,
    Expression<String>? memberLevelIdsJson,
    Expression<String>? description,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (strategy != null) 'strategy': strategy,
      if (configJson != null) 'config_json': configJson,
      if (priority != null) 'priority': priority,
      if (startsAt != null) 'starts_at': startsAt,
      if (endsAt != null) 'ends_at': endsAt,
      if (isActive != null) 'is_active': isActive,
      if (stackable != null) 'stackable': stackable,
      if (applicableProductIdsJson != null)
        'applicable_product_ids_json': applicableProductIdsJson,
      if (applicableCategoryIdsJson != null)
        'applicable_category_ids_json': applicableCategoryIdsJson,
      if (memberLevelIdsJson != null)
        'member_level_ids_json': memberLevelIdsJson,
      if (description != null) 'description': description,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PromotionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? strategy,
      Value<String>? configJson,
      Value<int>? priority,
      Value<DateTime?>? startsAt,
      Value<DateTime?>? endsAt,
      Value<bool>? isActive,
      Value<bool>? stackable,
      Value<String>? applicableProductIdsJson,
      Value<String>? applicableCategoryIdsJson,
      Value<String>? memberLevelIdsJson,
      Value<String?>? description,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return PromotionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      strategy: strategy ?? this.strategy,
      configJson: configJson ?? this.configJson,
      priority: priority ?? this.priority,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      isActive: isActive ?? this.isActive,
      stackable: stackable ?? this.stackable,
      applicableProductIdsJson:
          applicableProductIdsJson ?? this.applicableProductIdsJson,
      applicableCategoryIdsJson:
          applicableCategoryIdsJson ?? this.applicableCategoryIdsJson,
      memberLevelIdsJson: memberLevelIdsJson ?? this.memberLevelIdsJson,
      description: description ?? this.description,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (strategy.present) {
      map['strategy'] = Variable<String>(strategy.value);
    }
    if (configJson.present) {
      map['config_json'] = Variable<String>(configJson.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (startsAt.present) {
      map['starts_at'] = Variable<DateTime>(startsAt.value);
    }
    if (endsAt.present) {
      map['ends_at'] = Variable<DateTime>(endsAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (stackable.present) {
      map['stackable'] = Variable<bool>(stackable.value);
    }
    if (applicableProductIdsJson.present) {
      map['applicable_product_ids_json'] =
          Variable<String>(applicableProductIdsJson.value);
    }
    if (applicableCategoryIdsJson.present) {
      map['applicable_category_ids_json'] =
          Variable<String>(applicableCategoryIdsJson.value);
    }
    if (memberLevelIdsJson.present) {
      map['member_level_ids_json'] = Variable<String>(memberLevelIdsJson.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PromotionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('strategy: $strategy, ')
          ..write('configJson: $configJson, ')
          ..write('priority: $priority, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('isActive: $isActive, ')
          ..write('stackable: $stackable, ')
          ..write('applicableProductIdsJson: $applicableProductIdsJson, ')
          ..write('applicableCategoryIdsJson: $applicableCategoryIdsJson, ')
          ..write('memberLevelIdsJson: $memberLevelIdsJson, ')
          ..write('description: $description, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvoicesTable extends Invoices
    with TableInfo<$InvoicesTable, InvoiceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderIdMeta =
      const VerificationMeta('orderId');
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
      'order_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _invoiceNumberMeta =
      const VerificationMeta('invoiceNumber');
  @override
  late final GeneratedColumn<String> invoiceNumber = GeneratedColumn<String>(
      'invoice_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _invoiceDateMeta =
      const VerificationMeta('invoiceDate');
  @override
  late final GeneratedColumn<DateTime> invoiceDate = GeneratedColumn<DateTime>(
      'invoice_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _totalCentsMeta =
      const VerificationMeta('totalCents');
  @override
  late final GeneratedColumn<int> totalCents = GeneratedColumn<int>(
      'total_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _taxCentsMeta =
      const VerificationMeta('taxCents');
  @override
  late final GeneratedColumn<int> taxCents = GeneratedColumn<int>(
      'tax_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _taxTypeMeta =
      const VerificationMeta('taxType');
  @override
  late final GeneratedColumn<int> taxType = GeneratedColumn<int>(
      'tax_type', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _carrierTypeMeta =
      const VerificationMeta('carrierType');
  @override
  late final GeneratedColumn<String> carrierType = GeneratedColumn<String>(
      'carrier_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _carrierCodeMeta =
      const VerificationMeta('carrierCode');
  @override
  late final GeneratedColumn<String> carrierCode = GeneratedColumn<String>(
      'carrier_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _taxIdMeta = const VerificationMeta('taxId');
  @override
  late final GeneratedColumn<String> taxId = GeneratedColumn<String>(
      'tax_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _companyNameMeta =
      const VerificationMeta('companyName');
  @override
  late final GeneratedColumn<String> companyName = GeneratedColumn<String>(
      'company_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _donationCodeMeta =
      const VerificationMeta('donationCode');
  @override
  late final GeneratedColumn<String> donationCode = GeneratedColumn<String>(
      'donation_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _gatewayMeta =
      const VerificationMeta('gateway');
  @override
  late final GeneratedColumn<String> gateway = GeneratedColumn<String>(
      'gateway', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _gatewayRefMeta =
      const VerificationMeta('gatewayRef');
  @override
  late final GeneratedColumn<String> gatewayRef = GeneratedColumn<String>(
      'gateway_ref', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        orderId,
        status,
        invoiceNumber,
        invoiceDate,
        totalCents,
        taxCents,
        taxType,
        carrierType,
        carrierCode,
        taxId,
        companyName,
        donationCode,
        gateway,
        gatewayRef,
        lastError,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoices';
  @override
  VerificationContext validateIntegrity(Insertable<InvoiceRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('order_id')) {
      context.handle(_orderIdMeta,
          orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta));
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('invoice_number')) {
      context.handle(
          _invoiceNumberMeta,
          invoiceNumber.isAcceptableOrUnknown(
              data['invoice_number']!, _invoiceNumberMeta));
    }
    if (data.containsKey('invoice_date')) {
      context.handle(
          _invoiceDateMeta,
          invoiceDate.isAcceptableOrUnknown(
              data['invoice_date']!, _invoiceDateMeta));
    }
    if (data.containsKey('total_cents')) {
      context.handle(
          _totalCentsMeta,
          totalCents.isAcceptableOrUnknown(
              data['total_cents']!, _totalCentsMeta));
    } else if (isInserting) {
      context.missing(_totalCentsMeta);
    }
    if (data.containsKey('tax_cents')) {
      context.handle(_taxCentsMeta,
          taxCents.isAcceptableOrUnknown(data['tax_cents']!, _taxCentsMeta));
    } else if (isInserting) {
      context.missing(_taxCentsMeta);
    }
    if (data.containsKey('tax_type')) {
      context.handle(_taxTypeMeta,
          taxType.isAcceptableOrUnknown(data['tax_type']!, _taxTypeMeta));
    }
    if (data.containsKey('carrier_type')) {
      context.handle(
          _carrierTypeMeta,
          carrierType.isAcceptableOrUnknown(
              data['carrier_type']!, _carrierTypeMeta));
    }
    if (data.containsKey('carrier_code')) {
      context.handle(
          _carrierCodeMeta,
          carrierCode.isAcceptableOrUnknown(
              data['carrier_code']!, _carrierCodeMeta));
    }
    if (data.containsKey('tax_id')) {
      context.handle(
          _taxIdMeta, taxId.isAcceptableOrUnknown(data['tax_id']!, _taxIdMeta));
    }
    if (data.containsKey('company_name')) {
      context.handle(
          _companyNameMeta,
          companyName.isAcceptableOrUnknown(
              data['company_name']!, _companyNameMeta));
    }
    if (data.containsKey('donation_code')) {
      context.handle(
          _donationCodeMeta,
          donationCode.isAcceptableOrUnknown(
              data['donation_code']!, _donationCodeMeta));
    }
    if (data.containsKey('gateway')) {
      context.handle(_gatewayMeta,
          gateway.isAcceptableOrUnknown(data['gateway']!, _gatewayMeta));
    }
    if (data.containsKey('gateway_ref')) {
      context.handle(
          _gatewayRefMeta,
          gatewayRef.isAcceptableOrUnknown(
              data['gateway_ref']!, _gatewayRefMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InvoiceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvoiceRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      orderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      invoiceNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invoice_number']),
      invoiceDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}invoice_date']),
      totalCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_cents'])!,
      taxCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tax_cents'])!,
      taxType: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tax_type'])!,
      carrierType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}carrier_type']),
      carrierCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}carrier_code']),
      taxId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tax_id']),
      companyName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}company_name']),
      donationCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}donation_code']),
      gateway: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gateway']),
      gatewayRef: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gateway_ref']),
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $InvoicesTable createAlias(String alias) {
    return $InvoicesTable(attachedDatabase, alias);
  }
}

class InvoiceRow extends DataClass implements Insertable<InvoiceRow> {
  final String id;
  final String orderId;
  final String status;
  final String? invoiceNumber;
  final DateTime? invoiceDate;
  final int totalCents;
  final int taxCents;
  final int taxType;
  final String? carrierType;
  final String? carrierCode;
  final String? taxId;
  final String? companyName;
  final String? donationCode;
  final String? gateway;
  final String? gatewayRef;
  final String? lastError;
  final DateTime createdAt;
  const InvoiceRow(
      {required this.id,
      required this.orderId,
      required this.status,
      this.invoiceNumber,
      this.invoiceDate,
      required this.totalCents,
      required this.taxCents,
      required this.taxType,
      this.carrierType,
      this.carrierCode,
      this.taxId,
      this.companyName,
      this.donationCode,
      this.gateway,
      this.gatewayRef,
      this.lastError,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['order_id'] = Variable<String>(orderId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || invoiceNumber != null) {
      map['invoice_number'] = Variable<String>(invoiceNumber);
    }
    if (!nullToAbsent || invoiceDate != null) {
      map['invoice_date'] = Variable<DateTime>(invoiceDate);
    }
    map['total_cents'] = Variable<int>(totalCents);
    map['tax_cents'] = Variable<int>(taxCents);
    map['tax_type'] = Variable<int>(taxType);
    if (!nullToAbsent || carrierType != null) {
      map['carrier_type'] = Variable<String>(carrierType);
    }
    if (!nullToAbsent || carrierCode != null) {
      map['carrier_code'] = Variable<String>(carrierCode);
    }
    if (!nullToAbsent || taxId != null) {
      map['tax_id'] = Variable<String>(taxId);
    }
    if (!nullToAbsent || companyName != null) {
      map['company_name'] = Variable<String>(companyName);
    }
    if (!nullToAbsent || donationCode != null) {
      map['donation_code'] = Variable<String>(donationCode);
    }
    if (!nullToAbsent || gateway != null) {
      map['gateway'] = Variable<String>(gateway);
    }
    if (!nullToAbsent || gatewayRef != null) {
      map['gateway_ref'] = Variable<String>(gatewayRef);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  InvoicesCompanion toCompanion(bool nullToAbsent) {
    return InvoicesCompanion(
      id: Value(id),
      orderId: Value(orderId),
      status: Value(status),
      invoiceNumber: invoiceNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceNumber),
      invoiceDate: invoiceDate == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceDate),
      totalCents: Value(totalCents),
      taxCents: Value(taxCents),
      taxType: Value(taxType),
      carrierType: carrierType == null && nullToAbsent
          ? const Value.absent()
          : Value(carrierType),
      carrierCode: carrierCode == null && nullToAbsent
          ? const Value.absent()
          : Value(carrierCode),
      taxId:
          taxId == null && nullToAbsent ? const Value.absent() : Value(taxId),
      companyName: companyName == null && nullToAbsent
          ? const Value.absent()
          : Value(companyName),
      donationCode: donationCode == null && nullToAbsent
          ? const Value.absent()
          : Value(donationCode),
      gateway: gateway == null && nullToAbsent
          ? const Value.absent()
          : Value(gateway),
      gatewayRef: gatewayRef == null && nullToAbsent
          ? const Value.absent()
          : Value(gatewayRef),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
    );
  }

  factory InvoiceRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvoiceRow(
      id: serializer.fromJson<String>(json['id']),
      orderId: serializer.fromJson<String>(json['orderId']),
      status: serializer.fromJson<String>(json['status']),
      invoiceNumber: serializer.fromJson<String?>(json['invoiceNumber']),
      invoiceDate: serializer.fromJson<DateTime?>(json['invoiceDate']),
      totalCents: serializer.fromJson<int>(json['totalCents']),
      taxCents: serializer.fromJson<int>(json['taxCents']),
      taxType: serializer.fromJson<int>(json['taxType']),
      carrierType: serializer.fromJson<String?>(json['carrierType']),
      carrierCode: serializer.fromJson<String?>(json['carrierCode']),
      taxId: serializer.fromJson<String?>(json['taxId']),
      companyName: serializer.fromJson<String?>(json['companyName']),
      donationCode: serializer.fromJson<String?>(json['donationCode']),
      gateway: serializer.fromJson<String?>(json['gateway']),
      gatewayRef: serializer.fromJson<String?>(json['gatewayRef']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orderId': serializer.toJson<String>(orderId),
      'status': serializer.toJson<String>(status),
      'invoiceNumber': serializer.toJson<String?>(invoiceNumber),
      'invoiceDate': serializer.toJson<DateTime?>(invoiceDate),
      'totalCents': serializer.toJson<int>(totalCents),
      'taxCents': serializer.toJson<int>(taxCents),
      'taxType': serializer.toJson<int>(taxType),
      'carrierType': serializer.toJson<String?>(carrierType),
      'carrierCode': serializer.toJson<String?>(carrierCode),
      'taxId': serializer.toJson<String?>(taxId),
      'companyName': serializer.toJson<String?>(companyName),
      'donationCode': serializer.toJson<String?>(donationCode),
      'gateway': serializer.toJson<String?>(gateway),
      'gatewayRef': serializer.toJson<String?>(gatewayRef),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  InvoiceRow copyWith(
          {String? id,
          String? orderId,
          String? status,
          Value<String?> invoiceNumber = const Value.absent(),
          Value<DateTime?> invoiceDate = const Value.absent(),
          int? totalCents,
          int? taxCents,
          int? taxType,
          Value<String?> carrierType = const Value.absent(),
          Value<String?> carrierCode = const Value.absent(),
          Value<String?> taxId = const Value.absent(),
          Value<String?> companyName = const Value.absent(),
          Value<String?> donationCode = const Value.absent(),
          Value<String?> gateway = const Value.absent(),
          Value<String?> gatewayRef = const Value.absent(),
          Value<String?> lastError = const Value.absent(),
          DateTime? createdAt}) =>
      InvoiceRow(
        id: id ?? this.id,
        orderId: orderId ?? this.orderId,
        status: status ?? this.status,
        invoiceNumber:
            invoiceNumber.present ? invoiceNumber.value : this.invoiceNumber,
        invoiceDate: invoiceDate.present ? invoiceDate.value : this.invoiceDate,
        totalCents: totalCents ?? this.totalCents,
        taxCents: taxCents ?? this.taxCents,
        taxType: taxType ?? this.taxType,
        carrierType: carrierType.present ? carrierType.value : this.carrierType,
        carrierCode: carrierCode.present ? carrierCode.value : this.carrierCode,
        taxId: taxId.present ? taxId.value : this.taxId,
        companyName: companyName.present ? companyName.value : this.companyName,
        donationCode:
            donationCode.present ? donationCode.value : this.donationCode,
        gateway: gateway.present ? gateway.value : this.gateway,
        gatewayRef: gatewayRef.present ? gatewayRef.value : this.gatewayRef,
        lastError: lastError.present ? lastError.value : this.lastError,
        createdAt: createdAt ?? this.createdAt,
      );
  InvoiceRow copyWithCompanion(InvoicesCompanion data) {
    return InvoiceRow(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      status: data.status.present ? data.status.value : this.status,
      invoiceNumber: data.invoiceNumber.present
          ? data.invoiceNumber.value
          : this.invoiceNumber,
      invoiceDate:
          data.invoiceDate.present ? data.invoiceDate.value : this.invoiceDate,
      totalCents:
          data.totalCents.present ? data.totalCents.value : this.totalCents,
      taxCents: data.taxCents.present ? data.taxCents.value : this.taxCents,
      taxType: data.taxType.present ? data.taxType.value : this.taxType,
      carrierType:
          data.carrierType.present ? data.carrierType.value : this.carrierType,
      carrierCode:
          data.carrierCode.present ? data.carrierCode.value : this.carrierCode,
      taxId: data.taxId.present ? data.taxId.value : this.taxId,
      companyName:
          data.companyName.present ? data.companyName.value : this.companyName,
      donationCode: data.donationCode.present
          ? data.donationCode.value
          : this.donationCode,
      gateway: data.gateway.present ? data.gateway.value : this.gateway,
      gatewayRef:
          data.gatewayRef.present ? data.gatewayRef.value : this.gatewayRef,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceRow(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('status: $status, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('invoiceDate: $invoiceDate, ')
          ..write('totalCents: $totalCents, ')
          ..write('taxCents: $taxCents, ')
          ..write('taxType: $taxType, ')
          ..write('carrierType: $carrierType, ')
          ..write('carrierCode: $carrierCode, ')
          ..write('taxId: $taxId, ')
          ..write('companyName: $companyName, ')
          ..write('donationCode: $donationCode, ')
          ..write('gateway: $gateway, ')
          ..write('gatewayRef: $gatewayRef, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      orderId,
      status,
      invoiceNumber,
      invoiceDate,
      totalCents,
      taxCents,
      taxType,
      carrierType,
      carrierCode,
      taxId,
      companyName,
      donationCode,
      gateway,
      gatewayRef,
      lastError,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvoiceRow &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.status == this.status &&
          other.invoiceNumber == this.invoiceNumber &&
          other.invoiceDate == this.invoiceDate &&
          other.totalCents == this.totalCents &&
          other.taxCents == this.taxCents &&
          other.taxType == this.taxType &&
          other.carrierType == this.carrierType &&
          other.carrierCode == this.carrierCode &&
          other.taxId == this.taxId &&
          other.companyName == this.companyName &&
          other.donationCode == this.donationCode &&
          other.gateway == this.gateway &&
          other.gatewayRef == this.gatewayRef &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt);
}

class InvoicesCompanion extends UpdateCompanion<InvoiceRow> {
  final Value<String> id;
  final Value<String> orderId;
  final Value<String> status;
  final Value<String?> invoiceNumber;
  final Value<DateTime?> invoiceDate;
  final Value<int> totalCents;
  final Value<int> taxCents;
  final Value<int> taxType;
  final Value<String?> carrierType;
  final Value<String?> carrierCode;
  final Value<String?> taxId;
  final Value<String?> companyName;
  final Value<String?> donationCode;
  final Value<String?> gateway;
  final Value<String?> gatewayRef;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const InvoicesCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.status = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.invoiceDate = const Value.absent(),
    this.totalCents = const Value.absent(),
    this.taxCents = const Value.absent(),
    this.taxType = const Value.absent(),
    this.carrierType = const Value.absent(),
    this.carrierCode = const Value.absent(),
    this.taxId = const Value.absent(),
    this.companyName = const Value.absent(),
    this.donationCode = const Value.absent(),
    this.gateway = const Value.absent(),
    this.gatewayRef = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvoicesCompanion.insert({
    required String id,
    required String orderId,
    this.status = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.invoiceDate = const Value.absent(),
    required int totalCents,
    required int taxCents,
    this.taxType = const Value.absent(),
    this.carrierType = const Value.absent(),
    this.carrierCode = const Value.absent(),
    this.taxId = const Value.absent(),
    this.companyName = const Value.absent(),
    this.donationCode = const Value.absent(),
    this.gateway = const Value.absent(),
    this.gatewayRef = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        orderId = Value(orderId),
        totalCents = Value(totalCents),
        taxCents = Value(taxCents),
        createdAt = Value(createdAt);
  static Insertable<InvoiceRow> custom({
    Expression<String>? id,
    Expression<String>? orderId,
    Expression<String>? status,
    Expression<String>? invoiceNumber,
    Expression<DateTime>? invoiceDate,
    Expression<int>? totalCents,
    Expression<int>? taxCents,
    Expression<int>? taxType,
    Expression<String>? carrierType,
    Expression<String>? carrierCode,
    Expression<String>? taxId,
    Expression<String>? companyName,
    Expression<String>? donationCode,
    Expression<String>? gateway,
    Expression<String>? gatewayRef,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (status != null) 'status': status,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (invoiceDate != null) 'invoice_date': invoiceDate,
      if (totalCents != null) 'total_cents': totalCents,
      if (taxCents != null) 'tax_cents': taxCents,
      if (taxType != null) 'tax_type': taxType,
      if (carrierType != null) 'carrier_type': carrierType,
      if (carrierCode != null) 'carrier_code': carrierCode,
      if (taxId != null) 'tax_id': taxId,
      if (companyName != null) 'company_name': companyName,
      if (donationCode != null) 'donation_code': donationCode,
      if (gateway != null) 'gateway': gateway,
      if (gatewayRef != null) 'gateway_ref': gatewayRef,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvoicesCompanion copyWith(
      {Value<String>? id,
      Value<String>? orderId,
      Value<String>? status,
      Value<String?>? invoiceNumber,
      Value<DateTime?>? invoiceDate,
      Value<int>? totalCents,
      Value<int>? taxCents,
      Value<int>? taxType,
      Value<String?>? carrierType,
      Value<String?>? carrierCode,
      Value<String?>? taxId,
      Value<String?>? companyName,
      Value<String?>? donationCode,
      Value<String?>? gateway,
      Value<String?>? gatewayRef,
      Value<String?>? lastError,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return InvoicesCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      totalCents: totalCents ?? this.totalCents,
      taxCents: taxCents ?? this.taxCents,
      taxType: taxType ?? this.taxType,
      carrierType: carrierType ?? this.carrierType,
      carrierCode: carrierCode ?? this.carrierCode,
      taxId: taxId ?? this.taxId,
      companyName: companyName ?? this.companyName,
      donationCode: donationCode ?? this.donationCode,
      gateway: gateway ?? this.gateway,
      gatewayRef: gatewayRef ?? this.gatewayRef,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (invoiceNumber.present) {
      map['invoice_number'] = Variable<String>(invoiceNumber.value);
    }
    if (invoiceDate.present) {
      map['invoice_date'] = Variable<DateTime>(invoiceDate.value);
    }
    if (totalCents.present) {
      map['total_cents'] = Variable<int>(totalCents.value);
    }
    if (taxCents.present) {
      map['tax_cents'] = Variable<int>(taxCents.value);
    }
    if (taxType.present) {
      map['tax_type'] = Variable<int>(taxType.value);
    }
    if (carrierType.present) {
      map['carrier_type'] = Variable<String>(carrierType.value);
    }
    if (carrierCode.present) {
      map['carrier_code'] = Variable<String>(carrierCode.value);
    }
    if (taxId.present) {
      map['tax_id'] = Variable<String>(taxId.value);
    }
    if (companyName.present) {
      map['company_name'] = Variable<String>(companyName.value);
    }
    if (donationCode.present) {
      map['donation_code'] = Variable<String>(donationCode.value);
    }
    if (gateway.present) {
      map['gateway'] = Variable<String>(gateway.value);
    }
    if (gatewayRef.present) {
      map['gateway_ref'] = Variable<String>(gatewayRef.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoicesCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('status: $status, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('invoiceDate: $invoiceDate, ')
          ..write('totalCents: $totalCents, ')
          ..write('taxCents: $taxCents, ')
          ..write('taxType: $taxType, ')
          ..write('carrierType: $carrierType, ')
          ..write('carrierCode: $carrierCode, ')
          ..write('taxId: $taxId, ')
          ..write('companyName: $companyName, ')
          ..write('donationCode: $donationCode, ')
          ..write('gateway: $gateway, ')
          ..write('gatewayRef: $gatewayRef, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
      'op', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _retriesMeta =
      const VerificationMeta('retries');
  @override
  late final GeneratedColumn<int> retries = GeneratedColumn<int>(
      'retries', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _nextRetryAtMeta =
      const VerificationMeta('nextRetryAt');
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
      'next_retry_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, op, payloadJson, retries, nextRetryAt, createdAt, lastError];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    } else if (isInserting) {
      context.missing(_opMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('retries')) {
      context.handle(_retriesMeta,
          retries.isAcceptableOrUnknown(data['retries']!, _retriesMeta));
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
          _nextRetryAtMeta,
          nextRetryAt.isAcceptableOrUnknown(
              data['next_retry_at']!, _nextRetryAtMeta));
    } else if (isInserting) {
      context.missing(_nextRetryAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      op: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}op'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      retries: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retries'])!,
      nextRetryAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}next_retry_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueRow extends DataClass implements Insertable<SyncQueueRow> {
  final String id;
  final String op;
  final String payloadJson;
  final int retries;
  final DateTime nextRetryAt;
  final DateTime createdAt;
  final String? lastError;
  const SyncQueueRow(
      {required this.id,
      required this.op,
      required this.payloadJson,
      required this.retries,
      required this.nextRetryAt,
      required this.createdAt,
      this.lastError});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['op'] = Variable<String>(op);
    map['payload_json'] = Variable<String>(payloadJson);
    map['retries'] = Variable<int>(retries);
    map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      op: Value(op),
      payloadJson: Value(payloadJson),
      retries: Value(retries),
      nextRetryAt: Value(nextRetryAt),
      createdAt: Value(createdAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncQueueRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueRow(
      id: serializer.fromJson<String>(json['id']),
      op: serializer.fromJson<String>(json['op']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      retries: serializer.fromJson<int>(json['retries']),
      nextRetryAt: serializer.fromJson<DateTime>(json['nextRetryAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'op': serializer.toJson<String>(op),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'retries': serializer.toJson<int>(retries),
      'nextRetryAt': serializer.toJson<DateTime>(nextRetryAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncQueueRow copyWith(
          {String? id,
          String? op,
          String? payloadJson,
          int? retries,
          DateTime? nextRetryAt,
          DateTime? createdAt,
          Value<String?> lastError = const Value.absent()}) =>
      SyncQueueRow(
        id: id ?? this.id,
        op: op ?? this.op,
        payloadJson: payloadJson ?? this.payloadJson,
        retries: retries ?? this.retries,
        nextRetryAt: nextRetryAt ?? this.nextRetryAt,
        createdAt: createdAt ?? this.createdAt,
        lastError: lastError.present ? lastError.value : this.lastError,
      );
  SyncQueueRow copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueRow(
      id: data.id.present ? data.id.value : this.id,
      op: data.op.present ? data.op.value : this.op,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      retries: data.retries.present ? data.retries.value : this.retries,
      nextRetryAt:
          data.nextRetryAt.present ? data.nextRetryAt.value : this.nextRetryAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueRow(')
          ..write('id: $id, ')
          ..write('op: $op, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('retries: $retries, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, op, payloadJson, retries, nextRetryAt, createdAt, lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueRow &&
          other.id == this.id &&
          other.op == this.op &&
          other.payloadJson == this.payloadJson &&
          other.retries == this.retries &&
          other.nextRetryAt == this.nextRetryAt &&
          other.createdAt == this.createdAt &&
          other.lastError == this.lastError);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueRow> {
  final Value<String> id;
  final Value<String> op;
  final Value<String> payloadJson;
  final Value<int> retries;
  final Value<DateTime> nextRetryAt;
  final Value<DateTime> createdAt;
  final Value<String?> lastError;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.op = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.retries = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String id,
    required String op,
    required String payloadJson,
    this.retries = const Value.absent(),
    required DateTime nextRetryAt,
    required DateTime createdAt,
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        op = Value(op),
        payloadJson = Value(payloadJson),
        nextRetryAt = Value(nextRetryAt),
        createdAt = Value(createdAt);
  static Insertable<SyncQueueRow> custom({
    Expression<String>? id,
    Expression<String>? op,
    Expression<String>? payloadJson,
    Expression<int>? retries,
    Expression<DateTime>? nextRetryAt,
    Expression<DateTime>? createdAt,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (op != null) 'op': op,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (retries != null) 'retries': retries,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (createdAt != null) 'created_at': createdAt,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith(
      {Value<String>? id,
      Value<String>? op,
      Value<String>? payloadJson,
      Value<int>? retries,
      Value<DateTime>? nextRetryAt,
      Value<DateTime>? createdAt,
      Value<String?>? lastError,
      Value<int>? rowid}) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      op: op ?? this.op,
      payloadJson: payloadJson ?? this.payloadJson,
      retries: retries ?? this.retries,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      createdAt: createdAt ?? this.createdAt,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (retries.present) {
      map['retries'] = Variable<int>(retries.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('op: $op, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('retries: $retries, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HeldCartsTable extends HeldCarts
    with TableInfo<$HeldCartsTable, HeldCartRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeldCartsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pendingGuestOrderIdMeta =
      const VerificationMeta('pendingGuestOrderId');
  @override
  late final GeneratedColumn<String> pendingGuestOrderId =
      GeneratedColumn<String>('pending_guest_order_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, label, payload, pendingGuestOrderId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'held_carts';
  @override
  VerificationContext validateIntegrity(Insertable<HeldCartRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('pending_guest_order_id')) {
      context.handle(
          _pendingGuestOrderIdMeta,
          pendingGuestOrderId.isAcceptableOrUnknown(
              data['pending_guest_order_id']!, _pendingGuestOrderIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HeldCartRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeldCartRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      pendingGuestOrderId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}pending_guest_order_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $HeldCartsTable createAlias(String alias) {
    return $HeldCartsTable(attachedDatabase, alias);
  }
}

class HeldCartRow extends DataClass implements Insertable<HeldCartRow> {
  final String id;
  final String label;
  final String payload;
  final String? pendingGuestOrderId;
  final DateTime createdAt;
  const HeldCartRow(
      {required this.id,
      required this.label,
      required this.payload,
      this.pendingGuestOrderId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || pendingGuestOrderId != null) {
      map['pending_guest_order_id'] = Variable<String>(pendingGuestOrderId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  HeldCartsCompanion toCompanion(bool nullToAbsent) {
    return HeldCartsCompanion(
      id: Value(id),
      label: Value(label),
      payload: Value(payload),
      pendingGuestOrderId: pendingGuestOrderId == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingGuestOrderId),
      createdAt: Value(createdAt),
    );
  }

  factory HeldCartRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeldCartRow(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      payload: serializer.fromJson<String>(json['payload']),
      pendingGuestOrderId:
          serializer.fromJson<String?>(json['pendingGuestOrderId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'payload': serializer.toJson<String>(payload),
      'pendingGuestOrderId': serializer.toJson<String?>(pendingGuestOrderId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  HeldCartRow copyWith(
          {String? id,
          String? label,
          String? payload,
          Value<String?> pendingGuestOrderId = const Value.absent(),
          DateTime? createdAt}) =>
      HeldCartRow(
        id: id ?? this.id,
        label: label ?? this.label,
        payload: payload ?? this.payload,
        pendingGuestOrderId: pendingGuestOrderId.present
            ? pendingGuestOrderId.value
            : this.pendingGuestOrderId,
        createdAt: createdAt ?? this.createdAt,
      );
  HeldCartRow copyWithCompanion(HeldCartsCompanion data) {
    return HeldCartRow(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      payload: data.payload.present ? data.payload.value : this.payload,
      pendingGuestOrderId: data.pendingGuestOrderId.present
          ? data.pendingGuestOrderId.value
          : this.pendingGuestOrderId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeldCartRow(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('payload: $payload, ')
          ..write('pendingGuestOrderId: $pendingGuestOrderId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, label, payload, pendingGuestOrderId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeldCartRow &&
          other.id == this.id &&
          other.label == this.label &&
          other.payload == this.payload &&
          other.pendingGuestOrderId == this.pendingGuestOrderId &&
          other.createdAt == this.createdAt);
}

class HeldCartsCompanion extends UpdateCompanion<HeldCartRow> {
  final Value<String> id;
  final Value<String> label;
  final Value<String> payload;
  final Value<String?> pendingGuestOrderId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const HeldCartsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.payload = const Value.absent(),
    this.pendingGuestOrderId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HeldCartsCompanion.insert({
    required String id,
    required String label,
    required String payload,
    this.pendingGuestOrderId = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        label = Value(label),
        payload = Value(payload),
        createdAt = Value(createdAt);
  static Insertable<HeldCartRow> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<String>? payload,
    Expression<String>? pendingGuestOrderId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (payload != null) 'payload': payload,
      if (pendingGuestOrderId != null)
        'pending_guest_order_id': pendingGuestOrderId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HeldCartsCompanion copyWith(
      {Value<String>? id,
      Value<String>? label,
      Value<String>? payload,
      Value<String?>? pendingGuestOrderId,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return HeldCartsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      payload: payload ?? this.payload,
      pendingGuestOrderId: pendingGuestOrderId ?? this.pendingGuestOrderId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (pendingGuestOrderId.present) {
      map['pending_guest_order_id'] =
          Variable<String>(pendingGuestOrderId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeldCartsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('payload: $payload, ')
          ..write('pendingGuestOrderId: $pendingGuestOrderId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KvMetaTable extends KvMeta with TableInfo<$KvMetaTable, KvMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KvMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kv_meta';
  @override
  VerificationContext validateIntegrity(Insertable<KvMetaRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KvMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KvMetaRow(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value']),
    );
  }

  @override
  $KvMetaTable createAlias(String alias) {
    return $KvMetaTable(attachedDatabase, alias);
  }
}

class KvMetaRow extends DataClass implements Insertable<KvMetaRow> {
  final String key;
  final String? value;
  const KvMetaRow({required this.key, this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  KvMetaCompanion toCompanion(bool nullToAbsent) {
    return KvMetaCompanion(
      key: Value(key),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
    );
  }

  factory KvMetaRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KvMetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
    };
  }

  KvMetaRow copyWith(
          {String? key, Value<String?> value = const Value.absent()}) =>
      KvMetaRow(
        key: key ?? this.key,
        value: value.present ? value.value : this.value,
      );
  KvMetaRow copyWithCompanion(KvMetaCompanion data) {
    return KvMetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KvMetaRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KvMetaRow &&
          other.key == this.key &&
          other.value == this.value);
}

class KvMetaCompanion extends UpdateCompanion<KvMetaRow> {
  final Value<String> key;
  final Value<String?> value;
  final Value<int> rowid;
  const KvMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KvMetaCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<KvMetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KvMetaCompanion copyWith(
      {Value<String>? key, Value<String?>? value, Value<int>? rowid}) {
    return KvMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KvMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $StoresTable stores = $StoresTable(this);
  late final $TerminalsTable terminals = $TerminalsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $BookDetailsTable bookDetails = $BookDetailsTable(this);
  late final $ProductBarcodesTable productBarcodes =
      $ProductBarcodesTable(this);
  late final $OptionGroupsTable optionGroups = $OptionGroupsTable(this);
  late final $OptionChoicesTable optionChoices = $OptionChoicesTable(this);
  late final $ProductOptionGroupsTable productOptionGroups =
      $ProductOptionGroupsTable(this);
  late final $ProductOptionChoiceOverridesTable productOptionChoiceOverrides =
      $ProductOptionChoiceOverridesTable(this);
  late final $MemberLevelsTable memberLevels = $MemberLevelsTable(this);
  late final $MembersTable members = $MembersTable(this);
  late final $CouponsTable coupons = $CouponsTable(this);
  late final $PointTransactionsTable pointTransactions =
      $PointTransactionsTable(this);
  late final $OrdersTable orders = $OrdersTable(this);
  late final $OrderLinesTable orderLines = $OrderLinesTable(this);
  late final $PaymentsTable payments = $PaymentsTable(this);
  late final $RefundsTable refunds = $RefundsTable(this);
  late final $RefundLinesTable refundLines = $RefundLinesTable(this);
  late final $InventoryLevelsTable inventoryLevels =
      $InventoryLevelsTable(this);
  late final $InventoryMovementsTable inventoryMovements =
      $InventoryMovementsTable(this);
  late final $TransferOrdersTable transferOrders = $TransferOrdersTable(this);
  late final $TransferLinesTable transferLines = $TransferLinesTable(this);
  late final $StocktakesTable stocktakes = $StocktakesTable(this);
  late final $StocktakeLinesTable stocktakeLines = $StocktakeLinesTable(this);
  late final $PromotionsTable promotions = $PromotionsTable(this);
  late final $InvoicesTable invoices = $InvoicesTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $HeldCartsTable heldCarts = $HeldCartsTable(this);
  late final $KvMetaTable kvMeta = $KvMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        stores,
        terminals,
        categories,
        products,
        bookDetails,
        productBarcodes,
        optionGroups,
        optionChoices,
        productOptionGroups,
        productOptionChoiceOverrides,
        memberLevels,
        members,
        coupons,
        pointTransactions,
        orders,
        orderLines,
        payments,
        refunds,
        refundLines,
        inventoryLevels,
        inventoryMovements,
        transferOrders,
        transferLines,
        stocktakes,
        stocktakeLines,
        promotions,
        invoices,
        syncQueue,
        heldCarts,
        kvMeta
      ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$StoresTableCreateCompanionBuilder = StoresCompanion Function({
  required String id,
  required String code,
  required String name,
  Value<String?> taxId,
  Value<String?> address,
  Value<String?> phone,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$StoresTableUpdateCompanionBuilder = StoresCompanion Function({
  Value<String> id,
  Value<String> code,
  Value<String> name,
  Value<String?> taxId,
  Value<String?> address,
  Value<String?> phone,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$StoresTableReferences
    extends BaseReferences<_$AppDatabase, $StoresTable, StoreRow> {
  $$StoresTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TerminalsTable, List<TerminalRow>>
      _terminalsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.terminals,
          aliasName: $_aliasNameGenerator(db.stores.id, db.terminals.storeId));

  $$TerminalsTableProcessedTableManager get terminalsRefs {
    final manager = $$TerminalsTableTableManager($_db, $_db.terminals)
        .filter((f) => f.storeId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_terminalsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$StoresTableFilterComposer
    extends Composer<_$AppDatabase, $StoresTable> {
  $$StoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taxId => $composableBuilder(
      column: $table.taxId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> terminalsRefs(
      Expression<bool> Function($$TerminalsTableFilterComposer f) f) {
    final $$TerminalsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.terminals,
        getReferencedColumn: (t) => t.storeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TerminalsTableFilterComposer(
              $db: $db,
              $table: $db.terminals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$StoresTableOrderingComposer
    extends Composer<_$AppDatabase, $StoresTable> {
  $$StoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taxId => $composableBuilder(
      column: $table.taxId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$StoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoresTable> {
  $$StoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get taxId =>
      $composableBuilder(column: $table.taxId, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> terminalsRefs<T extends Object>(
      Expression<T> Function($$TerminalsTableAnnotationComposer a) f) {
    final $$TerminalsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.terminals,
        getReferencedColumn: (t) => t.storeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TerminalsTableAnnotationComposer(
              $db: $db,
              $table: $db.terminals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$StoresTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StoresTable,
    StoreRow,
    $$StoresTableFilterComposer,
    $$StoresTableOrderingComposer,
    $$StoresTableAnnotationComposer,
    $$StoresTableCreateCompanionBuilder,
    $$StoresTableUpdateCompanionBuilder,
    (StoreRow, $$StoresTableReferences),
    StoreRow,
    PrefetchHooks Function({bool terminalsRefs})> {
  $$StoresTableTableManager(_$AppDatabase db, $StoresTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> taxId = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StoresCompanion(
            id: id,
            code: code,
            name: name,
            taxId: taxId,
            address: address,
            phone: phone,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String code,
            required String name,
            Value<String?> taxId = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StoresCompanion.insert(
            id: id,
            code: code,
            name: name,
            taxId: taxId,
            address: address,
            phone: phone,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$StoresTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({terminalsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (terminalsRefs) db.terminals],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (terminalsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$StoresTableReferences._terminalsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$StoresTableReferences(db, table, p0)
                                .terminalsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.storeId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$StoresTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StoresTable,
    StoreRow,
    $$StoresTableFilterComposer,
    $$StoresTableOrderingComposer,
    $$StoresTableAnnotationComposer,
    $$StoresTableCreateCompanionBuilder,
    $$StoresTableUpdateCompanionBuilder,
    (StoreRow, $$StoresTableReferences),
    StoreRow,
    PrefetchHooks Function({bool terminalsRefs})>;
typedef $$TerminalsTableCreateCompanionBuilder = TerminalsCompanion Function({
  required String id,
  required String storeId,
  required String code,
  Value<DateTime?> lastSeenAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$TerminalsTableUpdateCompanionBuilder = TerminalsCompanion Function({
  Value<String> id,
  Value<String> storeId,
  Value<String> code,
  Value<DateTime?> lastSeenAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$TerminalsTableReferences
    extends BaseReferences<_$AppDatabase, $TerminalsTable, TerminalRow> {
  $$TerminalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StoresTable _storeIdTable(_$AppDatabase db) => db.stores
      .createAlias($_aliasNameGenerator(db.terminals.storeId, db.stores.id));

  $$StoresTableProcessedTableManager? get storeId {
    if ($_item.storeId == null) return null;
    final manager = $$StoresTableTableManager($_db, $_db.stores)
        .filter((f) => f.id($_item.storeId!));
    final item = $_typedResult.readTableOrNull(_storeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TerminalsTableFilterComposer
    extends Composer<_$AppDatabase, $TerminalsTable> {
  $$TerminalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
      column: $table.lastSeenAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$StoresTableFilterComposer get storeId {
    final $$StoresTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.storeId,
        referencedTable: $db.stores,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StoresTableFilterComposer(
              $db: $db,
              $table: $db.stores,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TerminalsTableOrderingComposer
    extends Composer<_$AppDatabase, $TerminalsTable> {
  $$TerminalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
      column: $table.lastSeenAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$StoresTableOrderingComposer get storeId {
    final $$StoresTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.storeId,
        referencedTable: $db.stores,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StoresTableOrderingComposer(
              $db: $db,
              $table: $db.stores,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TerminalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TerminalsTable> {
  $$TerminalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
      column: $table.lastSeenAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$StoresTableAnnotationComposer get storeId {
    final $$StoresTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.storeId,
        referencedTable: $db.stores,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StoresTableAnnotationComposer(
              $db: $db,
              $table: $db.stores,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TerminalsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TerminalsTable,
    TerminalRow,
    $$TerminalsTableFilterComposer,
    $$TerminalsTableOrderingComposer,
    $$TerminalsTableAnnotationComposer,
    $$TerminalsTableCreateCompanionBuilder,
    $$TerminalsTableUpdateCompanionBuilder,
    (TerminalRow, $$TerminalsTableReferences),
    TerminalRow,
    PrefetchHooks Function({bool storeId})> {
  $$TerminalsTableTableManager(_$AppDatabase db, $TerminalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TerminalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TerminalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TerminalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> storeId = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<DateTime?> lastSeenAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TerminalsCompanion(
            id: id,
            storeId: storeId,
            code: code,
            lastSeenAt: lastSeenAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String storeId,
            required String code,
            Value<DateTime?> lastSeenAt = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TerminalsCompanion.insert(
            id: id,
            storeId: storeId,
            code: code,
            lastSeenAt: lastSeenAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TerminalsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({storeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (storeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.storeId,
                    referencedTable:
                        $$TerminalsTableReferences._storeIdTable(db),
                    referencedColumn:
                        $$TerminalsTableReferences._storeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TerminalsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TerminalsTable,
    TerminalRow,
    $$TerminalsTableFilterComposer,
    $$TerminalsTableOrderingComposer,
    $$TerminalsTableAnnotationComposer,
    $$TerminalsTableCreateCompanionBuilder,
    $$TerminalsTableUpdateCompanionBuilder,
    (TerminalRow, $$TerminalsTableReferences),
    TerminalRow,
    PrefetchHooks Function({bool storeId})>;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  required String name,
  Value<String?> parentId,
  Value<int> sortOrder,
  Value<String?> color,
  Value<String?> icon,
  Value<bool> hideFromPublicOrdering,
  Value<bool> hideFromPosBrowse,
  Value<bool> memberDiscountEligible,
  Value<bool> pointsEarnEligible,
  Value<bool> pointsRedeemEligible,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> parentId,
  Value<int> sortOrder,
  Value<String?> color,
  Value<String?> icon,
  Value<bool> hideFromPublicOrdering,
  Value<bool> hideFromPosBrowse,
  Value<bool> memberDiscountEligible,
  Value<bool> pointsEarnEligible,
  Value<bool> pointsRedeemEligible,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hideFromPublicOrdering => $composableBuilder(
      column: $table.hideFromPublicOrdering,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hideFromPosBrowse => $composableBuilder(
      column: $table.hideFromPosBrowse,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get memberDiscountEligible => $composableBuilder(
      column: $table.memberDiscountEligible,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pointsEarnEligible => $composableBuilder(
      column: $table.pointsEarnEligible,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pointsRedeemEligible => $composableBuilder(
      column: $table.pointsRedeemEligible,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hideFromPublicOrdering => $composableBuilder(
      column: $table.hideFromPublicOrdering,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hideFromPosBrowse => $composableBuilder(
      column: $table.hideFromPosBrowse,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get memberDiscountEligible => $composableBuilder(
      column: $table.memberDiscountEligible,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pointsEarnEligible => $composableBuilder(
      column: $table.pointsEarnEligible,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pointsRedeemEligible => $composableBuilder(
      column: $table.pointsRedeemEligible,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<bool> get hideFromPublicOrdering => $composableBuilder(
      column: $table.hideFromPublicOrdering, builder: (column) => column);

  GeneratedColumn<bool> get hideFromPosBrowse => $composableBuilder(
      column: $table.hideFromPosBrowse, builder: (column) => column);

  GeneratedColumn<bool> get memberDiscountEligible => $composableBuilder(
      column: $table.memberDiscountEligible, builder: (column) => column);

  GeneratedColumn<bool> get pointsEarnEligible => $composableBuilder(
      column: $table.pointsEarnEligible, builder: (column) => column);

  GeneratedColumn<bool> get pointsRedeemEligible => $composableBuilder(
      column: $table.pointsRedeemEligible, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    CategoryRow,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (CategoryRow, BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>),
    CategoryRow,
    PrefetchHooks Function()> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> parentId = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<bool> hideFromPublicOrdering = const Value.absent(),
            Value<bool> hideFromPosBrowse = const Value.absent(),
            Value<bool> memberDiscountEligible = const Value.absent(),
            Value<bool> pointsEarnEligible = const Value.absent(),
            Value<bool> pointsRedeemEligible = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            name: name,
            parentId: parentId,
            sortOrder: sortOrder,
            color: color,
            icon: icon,
            hideFromPublicOrdering: hideFromPublicOrdering,
            hideFromPosBrowse: hideFromPosBrowse,
            memberDiscountEligible: memberDiscountEligible,
            pointsEarnEligible: pointsEarnEligible,
            pointsRedeemEligible: pointsRedeemEligible,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> parentId = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<bool> hideFromPublicOrdering = const Value.absent(),
            Value<bool> hideFromPosBrowse = const Value.absent(),
            Value<bool> memberDiscountEligible = const Value.absent(),
            Value<bool> pointsEarnEligible = const Value.absent(),
            Value<bool> pointsRedeemEligible = const Value.absent(),
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            name: name,
            parentId: parentId,
            sortOrder: sortOrder,
            color: color,
            icon: icon,
            hideFromPublicOrdering: hideFromPublicOrdering,
            hideFromPosBrowse: hideFromPosBrowse,
            memberDiscountEligible: memberDiscountEligible,
            pointsEarnEligible: pointsEarnEligible,
            pointsRedeemEligible: pointsRedeemEligible,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTable,
    CategoryRow,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (CategoryRow, BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>),
    CategoryRow,
    PrefetchHooks Function()>;
typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  required String id,
  required String sku,
  required String name,
  Value<int> priceCents,
  Value<int?> costCents,
  Value<String?> categoryId,
  Value<String?> imageUrl,
  Value<double> taxRate,
  Value<bool> isWeighted,
  Value<String> unit,
  Value<bool> isActive,
  Value<String?> description,
  Value<bool> hideFromPublicOrdering,
  Value<bool> hideFromPosBrowse,
  Value<bool> trackInventory,
  Value<String> productKind,
  Value<bool?> memberDiscountEligible,
  Value<bool?> pointsEarnEligible,
  Value<bool?> pointsRedeemEligible,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<String> id,
  Value<String> sku,
  Value<String> name,
  Value<int> priceCents,
  Value<int?> costCents,
  Value<String?> categoryId,
  Value<String?> imageUrl,
  Value<double> taxRate,
  Value<bool> isWeighted,
  Value<String> unit,
  Value<bool> isActive,
  Value<String?> description,
  Value<bool> hideFromPublicOrdering,
  Value<bool> hideFromPosBrowse,
  Value<bool> trackInventory,
  Value<String> productKind,
  Value<bool?> memberDiscountEligible,
  Value<bool?> pointsEarnEligible,
  Value<bool?> pointsRedeemEligible,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$ProductsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductsTable, ProductRow> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BookDetailsTable, List<BookDetailRow>>
      _bookDetailsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.bookDetails,
          aliasName:
              $_aliasNameGenerator(db.products.id, db.bookDetails.productId));

  $$BookDetailsTableProcessedTableManager get bookDetailsRefs {
    final manager = $$BookDetailsTableTableManager($_db, $_db.bookDetails)
        .filter((f) => f.productId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_bookDetailsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ProductBarcodesTable, List<ProductBarcodeRow>>
      _productBarcodesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.productBarcodes,
              aliasName: $_aliasNameGenerator(
                  db.products.id, db.productBarcodes.productId));

  $$ProductBarcodesTableProcessedTableManager get productBarcodesRefs {
    final manager =
        $$ProductBarcodesTableTableManager($_db, $_db.productBarcodes)
            .filter((f) => f.productId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_productBarcodesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ProductOptionGroupsTable,
      List<ProductOptionGroupRow>> _productOptionGroupsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.productOptionGroups,
          aliasName: $_aliasNameGenerator(
              db.products.id, db.productOptionGroups.productId));

  $$ProductOptionGroupsTableProcessedTableManager get productOptionGroupsRefs {
    final manager =
        $$ProductOptionGroupsTableTableManager($_db, $_db.productOptionGroups)
            .filter((f) => f.productId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_productOptionGroupsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ProductOptionChoiceOverridesTable,
          List<ProductOptionChoiceOverrideRow>>
      _productOptionChoiceOverridesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.productOptionChoiceOverrides,
              aliasName: $_aliasNameGenerator(
                  db.products.id, db.productOptionChoiceOverrides.productId));

  $$ProductOptionChoiceOverridesTableProcessedTableManager
      get productOptionChoiceOverridesRefs {
    final manager = $$ProductOptionChoiceOverridesTableTableManager(
            $_db, $_db.productOptionChoiceOverrides)
        .filter((f) => f.productId.id($_item.id));

    final cache = $_typedResult
        .readTableOrNull(_productOptionChoiceOverridesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priceCents => $composableBuilder(
      column: $table.priceCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get costCents => $composableBuilder(
      column: $table.costCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get taxRate => $composableBuilder(
      column: $table.taxRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isWeighted => $composableBuilder(
      column: $table.isWeighted, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hideFromPublicOrdering => $composableBuilder(
      column: $table.hideFromPublicOrdering,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hideFromPosBrowse => $composableBuilder(
      column: $table.hideFromPosBrowse,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get trackInventory => $composableBuilder(
      column: $table.trackInventory,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productKind => $composableBuilder(
      column: $table.productKind, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get memberDiscountEligible => $composableBuilder(
      column: $table.memberDiscountEligible,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pointsEarnEligible => $composableBuilder(
      column: $table.pointsEarnEligible,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pointsRedeemEligible => $composableBuilder(
      column: $table.pointsRedeemEligible,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> bookDetailsRefs(
      Expression<bool> Function($$BookDetailsTableFilterComposer f) f) {
    final $$BookDetailsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bookDetails,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BookDetailsTableFilterComposer(
              $db: $db,
              $table: $db.bookDetails,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> productBarcodesRefs(
      Expression<bool> Function($$ProductBarcodesTableFilterComposer f) f) {
    final $$ProductBarcodesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.productBarcodes,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductBarcodesTableFilterComposer(
              $db: $db,
              $table: $db.productBarcodes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> productOptionGroupsRefs(
      Expression<bool> Function($$ProductOptionGroupsTableFilterComposer f) f) {
    final $$ProductOptionGroupsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.productOptionGroups,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductOptionGroupsTableFilterComposer(
              $db: $db,
              $table: $db.productOptionGroups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> productOptionChoiceOverridesRefs(
      Expression<bool> Function(
              $$ProductOptionChoiceOverridesTableFilterComposer f)
          f) {
    final $$ProductOptionChoiceOverridesTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.productOptionChoiceOverrides,
            getReferencedColumn: (t) => t.productId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ProductOptionChoiceOverridesTableFilterComposer(
                  $db: $db,
                  $table: $db.productOptionChoiceOverrides,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priceCents => $composableBuilder(
      column: $table.priceCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get costCents => $composableBuilder(
      column: $table.costCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get taxRate => $composableBuilder(
      column: $table.taxRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isWeighted => $composableBuilder(
      column: $table.isWeighted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hideFromPublicOrdering => $composableBuilder(
      column: $table.hideFromPublicOrdering,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hideFromPosBrowse => $composableBuilder(
      column: $table.hideFromPosBrowse,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get trackInventory => $composableBuilder(
      column: $table.trackInventory,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productKind => $composableBuilder(
      column: $table.productKind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get memberDiscountEligible => $composableBuilder(
      column: $table.memberDiscountEligible,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pointsEarnEligible => $composableBuilder(
      column: $table.pointsEarnEligible,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pointsRedeemEligible => $composableBuilder(
      column: $table.pointsRedeemEligible,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get priceCents => $composableBuilder(
      column: $table.priceCents, builder: (column) => column);

  GeneratedColumn<int> get costCents =>
      $composableBuilder(column: $table.costCents, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<double> get taxRate =>
      $composableBuilder(column: $table.taxRate, builder: (column) => column);

  GeneratedColumn<bool> get isWeighted => $composableBuilder(
      column: $table.isWeighted, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<bool> get hideFromPublicOrdering => $composableBuilder(
      column: $table.hideFromPublicOrdering, builder: (column) => column);

  GeneratedColumn<bool> get hideFromPosBrowse => $composableBuilder(
      column: $table.hideFromPosBrowse, builder: (column) => column);

  GeneratedColumn<bool> get trackInventory => $composableBuilder(
      column: $table.trackInventory, builder: (column) => column);

  GeneratedColumn<String> get productKind => $composableBuilder(
      column: $table.productKind, builder: (column) => column);

  GeneratedColumn<bool> get memberDiscountEligible => $composableBuilder(
      column: $table.memberDiscountEligible, builder: (column) => column);

  GeneratedColumn<bool> get pointsEarnEligible => $composableBuilder(
      column: $table.pointsEarnEligible, builder: (column) => column);

  GeneratedColumn<bool> get pointsRedeemEligible => $composableBuilder(
      column: $table.pointsRedeemEligible, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> bookDetailsRefs<T extends Object>(
      Expression<T> Function($$BookDetailsTableAnnotationComposer a) f) {
    final $$BookDetailsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bookDetails,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BookDetailsTableAnnotationComposer(
              $db: $db,
              $table: $db.bookDetails,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> productBarcodesRefs<T extends Object>(
      Expression<T> Function($$ProductBarcodesTableAnnotationComposer a) f) {
    final $$ProductBarcodesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.productBarcodes,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductBarcodesTableAnnotationComposer(
              $db: $db,
              $table: $db.productBarcodes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> productOptionGroupsRefs<T extends Object>(
      Expression<T> Function($$ProductOptionGroupsTableAnnotationComposer a)
          f) {
    final $$ProductOptionGroupsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.productOptionGroups,
            getReferencedColumn: (t) => t.productId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ProductOptionGroupsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.productOptionGroups,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> productOptionChoiceOverridesRefs<T extends Object>(
      Expression<T> Function(
              $$ProductOptionChoiceOverridesTableAnnotationComposer a)
          f) {
    final $$ProductOptionChoiceOverridesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.productOptionChoiceOverrides,
            getReferencedColumn: (t) => t.productId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ProductOptionChoiceOverridesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.productOptionChoiceOverrides,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$ProductsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductsTable,
    ProductRow,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (ProductRow, $$ProductsTableReferences),
    ProductRow,
    PrefetchHooks Function(
        {bool bookDetailsRefs,
        bool productBarcodesRefs,
        bool productOptionGroupsRefs,
        bool productOptionChoiceOverridesRefs})> {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> sku = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> priceCents = const Value.absent(),
            Value<int?> costCents = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<double> taxRate = const Value.absent(),
            Value<bool> isWeighted = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<bool> hideFromPublicOrdering = const Value.absent(),
            Value<bool> hideFromPosBrowse = const Value.absent(),
            Value<bool> trackInventory = const Value.absent(),
            Value<String> productKind = const Value.absent(),
            Value<bool?> memberDiscountEligible = const Value.absent(),
            Value<bool?> pointsEarnEligible = const Value.absent(),
            Value<bool?> pointsRedeemEligible = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCompanion(
            id: id,
            sku: sku,
            name: name,
            priceCents: priceCents,
            costCents: costCents,
            categoryId: categoryId,
            imageUrl: imageUrl,
            taxRate: taxRate,
            isWeighted: isWeighted,
            unit: unit,
            isActive: isActive,
            description: description,
            hideFromPublicOrdering: hideFromPublicOrdering,
            hideFromPosBrowse: hideFromPosBrowse,
            trackInventory: trackInventory,
            productKind: productKind,
            memberDiscountEligible: memberDiscountEligible,
            pointsEarnEligible: pointsEarnEligible,
            pointsRedeemEligible: pointsRedeemEligible,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String sku,
            required String name,
            Value<int> priceCents = const Value.absent(),
            Value<int?> costCents = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<double> taxRate = const Value.absent(),
            Value<bool> isWeighted = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<bool> hideFromPublicOrdering = const Value.absent(),
            Value<bool> hideFromPosBrowse = const Value.absent(),
            Value<bool> trackInventory = const Value.absent(),
            Value<String> productKind = const Value.absent(),
            Value<bool?> memberDiscountEligible = const Value.absent(),
            Value<bool?> pointsEarnEligible = const Value.absent(),
            Value<bool?> pointsRedeemEligible = const Value.absent(),
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCompanion.insert(
            id: id,
            sku: sku,
            name: name,
            priceCents: priceCents,
            costCents: costCents,
            categoryId: categoryId,
            imageUrl: imageUrl,
            taxRate: taxRate,
            isWeighted: isWeighted,
            unit: unit,
            isActive: isActive,
            description: description,
            hideFromPublicOrdering: hideFromPublicOrdering,
            hideFromPosBrowse: hideFromPosBrowse,
            trackInventory: trackInventory,
            productKind: productKind,
            memberDiscountEligible: memberDiscountEligible,
            pointsEarnEligible: pointsEarnEligible,
            pointsRedeemEligible: pointsRedeemEligible,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ProductsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {bookDetailsRefs = false,
              productBarcodesRefs = false,
              productOptionGroupsRefs = false,
              productOptionChoiceOverridesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (bookDetailsRefs) db.bookDetails,
                if (productBarcodesRefs) db.productBarcodes,
                if (productOptionGroupsRefs) db.productOptionGroups,
                if (productOptionChoiceOverridesRefs)
                  db.productOptionChoiceOverrides
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (bookDetailsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$ProductsTableReferences._bookDetailsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .bookDetailsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.productId == item.id),
                        typedResults: items),
                  if (productBarcodesRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$ProductsTableReferences
                            ._productBarcodesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .productBarcodesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.productId == item.id),
                        typedResults: items),
                  if (productOptionGroupsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$ProductsTableReferences
                            ._productOptionGroupsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .productOptionGroupsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.productId == item.id),
                        typedResults: items),
                  if (productOptionChoiceOverridesRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$ProductsTableReferences
                            ._productOptionChoiceOverridesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .productOptionChoiceOverridesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.productId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ProductsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProductsTable,
    ProductRow,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (ProductRow, $$ProductsTableReferences),
    ProductRow,
    PrefetchHooks Function(
        {bool bookDetailsRefs,
        bool productBarcodesRefs,
        bool productOptionGroupsRefs,
        bool productOptionChoiceOverridesRefs})>;
typedef $$BookDetailsTableCreateCompanionBuilder = BookDetailsCompanion
    Function({
  required String productId,
  required String barcode,
  Value<String?> author,
  Value<String?> publisher,
  Value<String?> isbn,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$BookDetailsTableUpdateCompanionBuilder = BookDetailsCompanion
    Function({
  Value<String> productId,
  Value<String> barcode,
  Value<String?> author,
  Value<String?> publisher,
  Value<String?> isbn,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$BookDetailsTableReferences
    extends BaseReferences<_$AppDatabase, $BookDetailsTable, BookDetailRow> {
  $$BookDetailsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias(
          $_aliasNameGenerator(db.bookDetails.productId, db.products.id));

  $$ProductsTableProcessedTableManager? get productId {
    if ($_item.productId == null) return null;
    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id($_item.productId!));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BookDetailsTableFilterComposer
    extends Composer<_$AppDatabase, $BookDetailsTable> {
  $$BookDetailsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get author => $composableBuilder(
      column: $table.author, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get publisher => $composableBuilder(
      column: $table.publisher, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get isbn => $composableBuilder(
      column: $table.isbn, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BookDetailsTableOrderingComposer
    extends Composer<_$AppDatabase, $BookDetailsTable> {
  $$BookDetailsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get author => $composableBuilder(
      column: $table.author, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get publisher => $composableBuilder(
      column: $table.publisher, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get isbn => $composableBuilder(
      column: $table.isbn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BookDetailsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookDetailsTable> {
  $$BookDetailsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get publisher =>
      $composableBuilder(column: $table.publisher, builder: (column) => column);

  GeneratedColumn<String> get isbn =>
      $composableBuilder(column: $table.isbn, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BookDetailsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BookDetailsTable,
    BookDetailRow,
    $$BookDetailsTableFilterComposer,
    $$BookDetailsTableOrderingComposer,
    $$BookDetailsTableAnnotationComposer,
    $$BookDetailsTableCreateCompanionBuilder,
    $$BookDetailsTableUpdateCompanionBuilder,
    (BookDetailRow, $$BookDetailsTableReferences),
    BookDetailRow,
    PrefetchHooks Function({bool productId})> {
  $$BookDetailsTableTableManager(_$AppDatabase db, $BookDetailsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookDetailsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookDetailsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookDetailsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> productId = const Value.absent(),
            Value<String> barcode = const Value.absent(),
            Value<String?> author = const Value.absent(),
            Value<String?> publisher = const Value.absent(),
            Value<String?> isbn = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BookDetailsCompanion(
            productId: productId,
            barcode: barcode,
            author: author,
            publisher: publisher,
            isbn: isbn,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String productId,
            required String barcode,
            Value<String?> author = const Value.absent(),
            Value<String?> publisher = const Value.absent(),
            Value<String?> isbn = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BookDetailsCompanion.insert(
            productId: productId,
            barcode: barcode,
            author: author,
            publisher: publisher,
            isbn: isbn,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$BookDetailsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable:
                        $$BookDetailsTableReferences._productIdTable(db),
                    referencedColumn:
                        $$BookDetailsTableReferences._productIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$BookDetailsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BookDetailsTable,
    BookDetailRow,
    $$BookDetailsTableFilterComposer,
    $$BookDetailsTableOrderingComposer,
    $$BookDetailsTableAnnotationComposer,
    $$BookDetailsTableCreateCompanionBuilder,
    $$BookDetailsTableUpdateCompanionBuilder,
    (BookDetailRow, $$BookDetailsTableReferences),
    BookDetailRow,
    PrefetchHooks Function({bool productId})>;
typedef $$ProductBarcodesTableCreateCompanionBuilder = ProductBarcodesCompanion
    Function({
  required String productId,
  required String barcode,
  Value<int> rowid,
});
typedef $$ProductBarcodesTableUpdateCompanionBuilder = ProductBarcodesCompanion
    Function({
  Value<String> productId,
  Value<String> barcode,
  Value<int> rowid,
});

final class $$ProductBarcodesTableReferences extends BaseReferences<
    _$AppDatabase, $ProductBarcodesTable, ProductBarcodeRow> {
  $$ProductBarcodesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias(
          $_aliasNameGenerator(db.productBarcodes.productId, db.products.id));

  $$ProductsTableProcessedTableManager? get productId {
    if ($_item.productId == null) return null;
    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id($_item.productId!));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ProductBarcodesTableFilterComposer
    extends Composer<_$AppDatabase, $ProductBarcodesTable> {
  $$ProductBarcodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnFilters(column));

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProductBarcodesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductBarcodesTable> {
  $$ProductBarcodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnOrderings(column));

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProductBarcodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductBarcodesTable> {
  $$ProductBarcodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProductBarcodesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductBarcodesTable,
    ProductBarcodeRow,
    $$ProductBarcodesTableFilterComposer,
    $$ProductBarcodesTableOrderingComposer,
    $$ProductBarcodesTableAnnotationComposer,
    $$ProductBarcodesTableCreateCompanionBuilder,
    $$ProductBarcodesTableUpdateCompanionBuilder,
    (ProductBarcodeRow, $$ProductBarcodesTableReferences),
    ProductBarcodeRow,
    PrefetchHooks Function({bool productId})> {
  $$ProductBarcodesTableTableManager(
      _$AppDatabase db, $ProductBarcodesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductBarcodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductBarcodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductBarcodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> productId = const Value.absent(),
            Value<String> barcode = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductBarcodesCompanion(
            productId: productId,
            barcode: barcode,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String productId,
            required String barcode,
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductBarcodesCompanion.insert(
            productId: productId,
            barcode: barcode,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ProductBarcodesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable:
                        $$ProductBarcodesTableReferences._productIdTable(db),
                    referencedColumn:
                        $$ProductBarcodesTableReferences._productIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ProductBarcodesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProductBarcodesTable,
    ProductBarcodeRow,
    $$ProductBarcodesTableFilterComposer,
    $$ProductBarcodesTableOrderingComposer,
    $$ProductBarcodesTableAnnotationComposer,
    $$ProductBarcodesTableCreateCompanionBuilder,
    $$ProductBarcodesTableUpdateCompanionBuilder,
    (ProductBarcodeRow, $$ProductBarcodesTableReferences),
    ProductBarcodeRow,
    PrefetchHooks Function({bool productId})>;
typedef $$OptionGroupsTableCreateCompanionBuilder = OptionGroupsCompanion
    Function({
  required String id,
  required String name,
  Value<String> selectionType,
  Value<bool> isRequired,
  Value<int> minSelections,
  Value<int?> maxSelections,
  Value<int> sortOrder,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$OptionGroupsTableUpdateCompanionBuilder = OptionGroupsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> selectionType,
  Value<bool> isRequired,
  Value<int> minSelections,
  Value<int?> maxSelections,
  Value<int> sortOrder,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$OptionGroupsTableReferences
    extends BaseReferences<_$AppDatabase, $OptionGroupsTable, OptionGroupRow> {
  $$OptionGroupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$OptionChoicesTable, List<OptionChoiceRow>>
      _optionChoicesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.optionChoices,
              aliasName: $_aliasNameGenerator(
                  db.optionGroups.id, db.optionChoices.optionGroupId));

  $$OptionChoicesTableProcessedTableManager get optionChoicesRefs {
    final manager = $$OptionChoicesTableTableManager($_db, $_db.optionChoices)
        .filter((f) => f.optionGroupId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_optionChoicesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ProductOptionGroupsTable,
      List<ProductOptionGroupRow>> _productOptionGroupsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.productOptionGroups,
          aliasName: $_aliasNameGenerator(
              db.optionGroups.id, db.productOptionGroups.optionGroupId));

  $$ProductOptionGroupsTableProcessedTableManager get productOptionGroupsRefs {
    final manager =
        $$ProductOptionGroupsTableTableManager($_db, $_db.productOptionGroups)
            .filter((f) => f.optionGroupId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_productOptionGroupsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$OptionGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $OptionGroupsTable> {
  $$OptionGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get selectionType => $composableBuilder(
      column: $table.selectionType, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRequired => $composableBuilder(
      column: $table.isRequired, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minSelections => $composableBuilder(
      column: $table.minSelections, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxSelections => $composableBuilder(
      column: $table.maxSelections, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> optionChoicesRefs(
      Expression<bool> Function($$OptionChoicesTableFilterComposer f) f) {
    final $$OptionChoicesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.optionChoices,
        getReferencedColumn: (t) => t.optionGroupId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OptionChoicesTableFilterComposer(
              $db: $db,
              $table: $db.optionChoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> productOptionGroupsRefs(
      Expression<bool> Function($$ProductOptionGroupsTableFilterComposer f) f) {
    final $$ProductOptionGroupsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.productOptionGroups,
        getReferencedColumn: (t) => t.optionGroupId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductOptionGroupsTableFilterComposer(
              $db: $db,
              $table: $db.productOptionGroups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$OptionGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $OptionGroupsTable> {
  $$OptionGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get selectionType => $composableBuilder(
      column: $table.selectionType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRequired => $composableBuilder(
      column: $table.isRequired, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minSelections => $composableBuilder(
      column: $table.minSelections,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxSelections => $composableBuilder(
      column: $table.maxSelections,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$OptionGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OptionGroupsTable> {
  $$OptionGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get selectionType => $composableBuilder(
      column: $table.selectionType, builder: (column) => column);

  GeneratedColumn<bool> get isRequired => $composableBuilder(
      column: $table.isRequired, builder: (column) => column);

  GeneratedColumn<int> get minSelections => $composableBuilder(
      column: $table.minSelections, builder: (column) => column);

  GeneratedColumn<int> get maxSelections => $composableBuilder(
      column: $table.maxSelections, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> optionChoicesRefs<T extends Object>(
      Expression<T> Function($$OptionChoicesTableAnnotationComposer a) f) {
    final $$OptionChoicesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.optionChoices,
        getReferencedColumn: (t) => t.optionGroupId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OptionChoicesTableAnnotationComposer(
              $db: $db,
              $table: $db.optionChoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> productOptionGroupsRefs<T extends Object>(
      Expression<T> Function($$ProductOptionGroupsTableAnnotationComposer a)
          f) {
    final $$ProductOptionGroupsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.productOptionGroups,
            getReferencedColumn: (t) => t.optionGroupId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ProductOptionGroupsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.productOptionGroups,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$OptionGroupsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OptionGroupsTable,
    OptionGroupRow,
    $$OptionGroupsTableFilterComposer,
    $$OptionGroupsTableOrderingComposer,
    $$OptionGroupsTableAnnotationComposer,
    $$OptionGroupsTableCreateCompanionBuilder,
    $$OptionGroupsTableUpdateCompanionBuilder,
    (OptionGroupRow, $$OptionGroupsTableReferences),
    OptionGroupRow,
    PrefetchHooks Function(
        {bool optionChoicesRefs, bool productOptionGroupsRefs})> {
  $$OptionGroupsTableTableManager(_$AppDatabase db, $OptionGroupsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OptionGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OptionGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OptionGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> selectionType = const Value.absent(),
            Value<bool> isRequired = const Value.absent(),
            Value<int> minSelections = const Value.absent(),
            Value<int?> maxSelections = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OptionGroupsCompanion(
            id: id,
            name: name,
            selectionType: selectionType,
            isRequired: isRequired,
            minSelections: minSelections,
            maxSelections: maxSelections,
            sortOrder: sortOrder,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String> selectionType = const Value.absent(),
            Value<bool> isRequired = const Value.absent(),
            Value<int> minSelections = const Value.absent(),
            Value<int?> maxSelections = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OptionGroupsCompanion.insert(
            id: id,
            name: name,
            selectionType: selectionType,
            isRequired: isRequired,
            minSelections: minSelections,
            maxSelections: maxSelections,
            sortOrder: sortOrder,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$OptionGroupsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {optionChoicesRefs = false, productOptionGroupsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (optionChoicesRefs) db.optionChoices,
                if (productOptionGroupsRefs) db.productOptionGroups
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (optionChoicesRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$OptionGroupsTableReferences
                            ._optionChoicesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$OptionGroupsTableReferences(db, table, p0)
                                .optionChoicesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.optionGroupId == item.id),
                        typedResults: items),
                  if (productOptionGroupsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$OptionGroupsTableReferences
                            ._productOptionGroupsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$OptionGroupsTableReferences(db, table, p0)
                                .productOptionGroupsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.optionGroupId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$OptionGroupsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OptionGroupsTable,
    OptionGroupRow,
    $$OptionGroupsTableFilterComposer,
    $$OptionGroupsTableOrderingComposer,
    $$OptionGroupsTableAnnotationComposer,
    $$OptionGroupsTableCreateCompanionBuilder,
    $$OptionGroupsTableUpdateCompanionBuilder,
    (OptionGroupRow, $$OptionGroupsTableReferences),
    OptionGroupRow,
    PrefetchHooks Function(
        {bool optionChoicesRefs, bool productOptionGroupsRefs})>;
typedef $$OptionChoicesTableCreateCompanionBuilder = OptionChoicesCompanion
    Function({
  required String id,
  required String optionGroupId,
  required String name,
  Value<int> priceDeltaCents,
  Value<bool> isDefault,
  Value<int> sortOrder,
  Value<bool> isActive,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$OptionChoicesTableUpdateCompanionBuilder = OptionChoicesCompanion
    Function({
  Value<String> id,
  Value<String> optionGroupId,
  Value<String> name,
  Value<int> priceDeltaCents,
  Value<bool> isDefault,
  Value<int> sortOrder,
  Value<bool> isActive,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$OptionChoicesTableReferences extends BaseReferences<_$AppDatabase,
    $OptionChoicesTable, OptionChoiceRow> {
  $$OptionChoicesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $OptionGroupsTable _optionGroupIdTable(_$AppDatabase db) =>
      db.optionGroups.createAlias($_aliasNameGenerator(
          db.optionChoices.optionGroupId, db.optionGroups.id));

  $$OptionGroupsTableProcessedTableManager? get optionGroupId {
    if ($_item.optionGroupId == null) return null;
    final manager = $$OptionGroupsTableTableManager($_db, $_db.optionGroups)
        .filter((f) => f.id($_item.optionGroupId!));
    final item = $_typedResult.readTableOrNull(_optionGroupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$ProductOptionChoiceOverridesTable,
          List<ProductOptionChoiceOverrideRow>>
      _productOptionChoiceOverridesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.productOptionChoiceOverrides,
              aliasName: $_aliasNameGenerator(db.optionChoices.id,
                  db.productOptionChoiceOverrides.optionChoiceId));

  $$ProductOptionChoiceOverridesTableProcessedTableManager
      get productOptionChoiceOverridesRefs {
    final manager = $$ProductOptionChoiceOverridesTableTableManager(
            $_db, $_db.productOptionChoiceOverrides)
        .filter((f) => f.optionChoiceId.id($_item.id));

    final cache = $_typedResult
        .readTableOrNull(_productOptionChoiceOverridesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$OptionChoicesTableFilterComposer
    extends Composer<_$AppDatabase, $OptionChoicesTable> {
  $$OptionChoicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priceDeltaCents => $composableBuilder(
      column: $table.priceDeltaCents,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$OptionGroupsTableFilterComposer get optionGroupId {
    final $$OptionGroupsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.optionGroupId,
        referencedTable: $db.optionGroups,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OptionGroupsTableFilterComposer(
              $db: $db,
              $table: $db.optionGroups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> productOptionChoiceOverridesRefs(
      Expression<bool> Function(
              $$ProductOptionChoiceOverridesTableFilterComposer f)
          f) {
    final $$ProductOptionChoiceOverridesTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.productOptionChoiceOverrides,
            getReferencedColumn: (t) => t.optionChoiceId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ProductOptionChoiceOverridesTableFilterComposer(
                  $db: $db,
                  $table: $db.productOptionChoiceOverrides,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$OptionChoicesTableOrderingComposer
    extends Composer<_$AppDatabase, $OptionChoicesTable> {
  $$OptionChoicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priceDeltaCents => $composableBuilder(
      column: $table.priceDeltaCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$OptionGroupsTableOrderingComposer get optionGroupId {
    final $$OptionGroupsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.optionGroupId,
        referencedTable: $db.optionGroups,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OptionGroupsTableOrderingComposer(
              $db: $db,
              $table: $db.optionGroups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OptionChoicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OptionChoicesTable> {
  $$OptionChoicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get priceDeltaCents => $composableBuilder(
      column: $table.priceDeltaCents, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$OptionGroupsTableAnnotationComposer get optionGroupId {
    final $$OptionGroupsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.optionGroupId,
        referencedTable: $db.optionGroups,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OptionGroupsTableAnnotationComposer(
              $db: $db,
              $table: $db.optionGroups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> productOptionChoiceOverridesRefs<T extends Object>(
      Expression<T> Function(
              $$ProductOptionChoiceOverridesTableAnnotationComposer a)
          f) {
    final $$ProductOptionChoiceOverridesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.productOptionChoiceOverrides,
            getReferencedColumn: (t) => t.optionChoiceId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ProductOptionChoiceOverridesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.productOptionChoiceOverrides,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$OptionChoicesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OptionChoicesTable,
    OptionChoiceRow,
    $$OptionChoicesTableFilterComposer,
    $$OptionChoicesTableOrderingComposer,
    $$OptionChoicesTableAnnotationComposer,
    $$OptionChoicesTableCreateCompanionBuilder,
    $$OptionChoicesTableUpdateCompanionBuilder,
    (OptionChoiceRow, $$OptionChoicesTableReferences),
    OptionChoiceRow,
    PrefetchHooks Function(
        {bool optionGroupId, bool productOptionChoiceOverridesRefs})> {
  $$OptionChoicesTableTableManager(_$AppDatabase db, $OptionChoicesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OptionChoicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OptionChoicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OptionChoicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> optionGroupId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> priceDeltaCents = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OptionChoicesCompanion(
            id: id,
            optionGroupId: optionGroupId,
            name: name,
            priceDeltaCents: priceDeltaCents,
            isDefault: isDefault,
            sortOrder: sortOrder,
            isActive: isActive,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String optionGroupId,
            required String name,
            Value<int> priceDeltaCents = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OptionChoicesCompanion.insert(
            id: id,
            optionGroupId: optionGroupId,
            name: name,
            priceDeltaCents: priceDeltaCents,
            isDefault: isDefault,
            sortOrder: sortOrder,
            isActive: isActive,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$OptionChoicesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {optionGroupId = false,
              productOptionChoiceOverridesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (productOptionChoiceOverridesRefs)
                  db.productOptionChoiceOverrides
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (optionGroupId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.optionGroupId,
                    referencedTable:
                        $$OptionChoicesTableReferences._optionGroupIdTable(db),
                    referencedColumn: $$OptionChoicesTableReferences
                        ._optionGroupIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (productOptionChoiceOverridesRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$OptionChoicesTableReferences
                            ._productOptionChoiceOverridesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$OptionChoicesTableReferences(db, table, p0)
                                .productOptionChoiceOverridesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.optionChoiceId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$OptionChoicesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OptionChoicesTable,
    OptionChoiceRow,
    $$OptionChoicesTableFilterComposer,
    $$OptionChoicesTableOrderingComposer,
    $$OptionChoicesTableAnnotationComposer,
    $$OptionChoicesTableCreateCompanionBuilder,
    $$OptionChoicesTableUpdateCompanionBuilder,
    (OptionChoiceRow, $$OptionChoicesTableReferences),
    OptionChoiceRow,
    PrefetchHooks Function(
        {bool optionGroupId, bool productOptionChoiceOverridesRefs})>;
typedef $$ProductOptionGroupsTableCreateCompanionBuilder
    = ProductOptionGroupsCompanion Function({
  required String id,
  required String productId,
  required String optionGroupId,
  Value<int> sortOrder,
  Value<bool?> isRequired,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ProductOptionGroupsTableUpdateCompanionBuilder
    = ProductOptionGroupsCompanion Function({
  Value<String> id,
  Value<String> productId,
  Value<String> optionGroupId,
  Value<int> sortOrder,
  Value<bool?> isRequired,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$ProductOptionGroupsTableReferences extends BaseReferences<
    _$AppDatabase, $ProductOptionGroupsTable, ProductOptionGroupRow> {
  $$ProductOptionGroupsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias($_aliasNameGenerator(
          db.productOptionGroups.productId, db.products.id));

  $$ProductsTableProcessedTableManager? get productId {
    if ($_item.productId == null) return null;
    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id($_item.productId!));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $OptionGroupsTable _optionGroupIdTable(_$AppDatabase db) =>
      db.optionGroups.createAlias($_aliasNameGenerator(
          db.productOptionGroups.optionGroupId, db.optionGroups.id));

  $$OptionGroupsTableProcessedTableManager? get optionGroupId {
    if ($_item.optionGroupId == null) return null;
    final manager = $$OptionGroupsTableTableManager($_db, $_db.optionGroups)
        .filter((f) => f.id($_item.optionGroupId!));
    final item = $_typedResult.readTableOrNull(_optionGroupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ProductOptionGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductOptionGroupsTable> {
  $$ProductOptionGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRequired => $composableBuilder(
      column: $table.isRequired, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$OptionGroupsTableFilterComposer get optionGroupId {
    final $$OptionGroupsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.optionGroupId,
        referencedTable: $db.optionGroups,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OptionGroupsTableFilterComposer(
              $db: $db,
              $table: $db.optionGroups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProductOptionGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductOptionGroupsTable> {
  $$ProductOptionGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRequired => $composableBuilder(
      column: $table.isRequired, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$OptionGroupsTableOrderingComposer get optionGroupId {
    final $$OptionGroupsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.optionGroupId,
        referencedTable: $db.optionGroups,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OptionGroupsTableOrderingComposer(
              $db: $db,
              $table: $db.optionGroups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProductOptionGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductOptionGroupsTable> {
  $$ProductOptionGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isRequired => $composableBuilder(
      column: $table.isRequired, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$OptionGroupsTableAnnotationComposer get optionGroupId {
    final $$OptionGroupsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.optionGroupId,
        referencedTable: $db.optionGroups,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OptionGroupsTableAnnotationComposer(
              $db: $db,
              $table: $db.optionGroups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProductOptionGroupsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductOptionGroupsTable,
    ProductOptionGroupRow,
    $$ProductOptionGroupsTableFilterComposer,
    $$ProductOptionGroupsTableOrderingComposer,
    $$ProductOptionGroupsTableAnnotationComposer,
    $$ProductOptionGroupsTableCreateCompanionBuilder,
    $$ProductOptionGroupsTableUpdateCompanionBuilder,
    (ProductOptionGroupRow, $$ProductOptionGroupsTableReferences),
    ProductOptionGroupRow,
    PrefetchHooks Function({bool productId, bool optionGroupId})> {
  $$ProductOptionGroupsTableTableManager(
      _$AppDatabase db, $ProductOptionGroupsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductOptionGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductOptionGroupsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductOptionGroupsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> productId = const Value.absent(),
            Value<String> optionGroupId = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<bool?> isRequired = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductOptionGroupsCompanion(
            id: id,
            productId: productId,
            optionGroupId: optionGroupId,
            sortOrder: sortOrder,
            isRequired: isRequired,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String productId,
            required String optionGroupId,
            Value<int> sortOrder = const Value.absent(),
            Value<bool?> isRequired = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductOptionGroupsCompanion.insert(
            id: id,
            productId: productId,
            optionGroupId: optionGroupId,
            sortOrder: sortOrder,
            isRequired: isRequired,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ProductOptionGroupsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({productId = false, optionGroupId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable: $$ProductOptionGroupsTableReferences
                        ._productIdTable(db),
                    referencedColumn: $$ProductOptionGroupsTableReferences
                        ._productIdTable(db)
                        .id,
                  ) as T;
                }
                if (optionGroupId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.optionGroupId,
                    referencedTable: $$ProductOptionGroupsTableReferences
                        ._optionGroupIdTable(db),
                    referencedColumn: $$ProductOptionGroupsTableReferences
                        ._optionGroupIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ProductOptionGroupsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProductOptionGroupsTable,
    ProductOptionGroupRow,
    $$ProductOptionGroupsTableFilterComposer,
    $$ProductOptionGroupsTableOrderingComposer,
    $$ProductOptionGroupsTableAnnotationComposer,
    $$ProductOptionGroupsTableCreateCompanionBuilder,
    $$ProductOptionGroupsTableUpdateCompanionBuilder,
    (ProductOptionGroupRow, $$ProductOptionGroupsTableReferences),
    ProductOptionGroupRow,
    PrefetchHooks Function({bool productId, bool optionGroupId})>;
typedef $$ProductOptionChoiceOverridesTableCreateCompanionBuilder
    = ProductOptionChoiceOverridesCompanion Function({
  required String id,
  required String productId,
  required String optionChoiceId,
  Value<int?> priceDeltaCents,
  Value<bool> isHidden,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ProductOptionChoiceOverridesTableUpdateCompanionBuilder
    = ProductOptionChoiceOverridesCompanion Function({
  Value<String> id,
  Value<String> productId,
  Value<String> optionChoiceId,
  Value<int?> priceDeltaCents,
  Value<bool> isHidden,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$ProductOptionChoiceOverridesTableReferences
    extends BaseReferences<_$AppDatabase, $ProductOptionChoiceOverridesTable,
        ProductOptionChoiceOverrideRow> {
  $$ProductOptionChoiceOverridesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias($_aliasNameGenerator(
          db.productOptionChoiceOverrides.productId, db.products.id));

  $$ProductsTableProcessedTableManager? get productId {
    if ($_item.productId == null) return null;
    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id($_item.productId!));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $OptionChoicesTable _optionChoiceIdTable(_$AppDatabase db) =>
      db.optionChoices.createAlias($_aliasNameGenerator(
          db.productOptionChoiceOverrides.optionChoiceId, db.optionChoices.id));

  $$OptionChoicesTableProcessedTableManager? get optionChoiceId {
    if ($_item.optionChoiceId == null) return null;
    final manager = $$OptionChoicesTableTableManager($_db, $_db.optionChoices)
        .filter((f) => f.id($_item.optionChoiceId!));
    final item = $_typedResult.readTableOrNull(_optionChoiceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ProductOptionChoiceOverridesTableFilterComposer
    extends Composer<_$AppDatabase, $ProductOptionChoiceOverridesTable> {
  $$ProductOptionChoiceOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priceDeltaCents => $composableBuilder(
      column: $table.priceDeltaCents,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isHidden => $composableBuilder(
      column: $table.isHidden, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$OptionChoicesTableFilterComposer get optionChoiceId {
    final $$OptionChoicesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.optionChoiceId,
        referencedTable: $db.optionChoices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OptionChoicesTableFilterComposer(
              $db: $db,
              $table: $db.optionChoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProductOptionChoiceOverridesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductOptionChoiceOverridesTable> {
  $$ProductOptionChoiceOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priceDeltaCents => $composableBuilder(
      column: $table.priceDeltaCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isHidden => $composableBuilder(
      column: $table.isHidden, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$OptionChoicesTableOrderingComposer get optionChoiceId {
    final $$OptionChoicesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.optionChoiceId,
        referencedTable: $db.optionChoices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OptionChoicesTableOrderingComposer(
              $db: $db,
              $table: $db.optionChoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProductOptionChoiceOverridesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductOptionChoiceOverridesTable> {
  $$ProductOptionChoiceOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get priceDeltaCents => $composableBuilder(
      column: $table.priceDeltaCents, builder: (column) => column);

  GeneratedColumn<bool> get isHidden =>
      $composableBuilder(column: $table.isHidden, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$OptionChoicesTableAnnotationComposer get optionChoiceId {
    final $$OptionChoicesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.optionChoiceId,
        referencedTable: $db.optionChoices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OptionChoicesTableAnnotationComposer(
              $db: $db,
              $table: $db.optionChoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProductOptionChoiceOverridesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductOptionChoiceOverridesTable,
    ProductOptionChoiceOverrideRow,
    $$ProductOptionChoiceOverridesTableFilterComposer,
    $$ProductOptionChoiceOverridesTableOrderingComposer,
    $$ProductOptionChoiceOverridesTableAnnotationComposer,
    $$ProductOptionChoiceOverridesTableCreateCompanionBuilder,
    $$ProductOptionChoiceOverridesTableUpdateCompanionBuilder,
    (
      ProductOptionChoiceOverrideRow,
      $$ProductOptionChoiceOverridesTableReferences
    ),
    ProductOptionChoiceOverrideRow,
    PrefetchHooks Function({bool productId, bool optionChoiceId})> {
  $$ProductOptionChoiceOverridesTableTableManager(
      _$AppDatabase db, $ProductOptionChoiceOverridesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductOptionChoiceOverridesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductOptionChoiceOverridesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductOptionChoiceOverridesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> productId = const Value.absent(),
            Value<String> optionChoiceId = const Value.absent(),
            Value<int?> priceDeltaCents = const Value.absent(),
            Value<bool> isHidden = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductOptionChoiceOverridesCompanion(
            id: id,
            productId: productId,
            optionChoiceId: optionChoiceId,
            priceDeltaCents: priceDeltaCents,
            isHidden: isHidden,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String productId,
            required String optionChoiceId,
            Value<int?> priceDeltaCents = const Value.absent(),
            Value<bool> isHidden = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductOptionChoiceOverridesCompanion.insert(
            id: id,
            productId: productId,
            optionChoiceId: optionChoiceId,
            priceDeltaCents: priceDeltaCents,
            isHidden: isHidden,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ProductOptionChoiceOverridesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({productId = false, optionChoiceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable:
                        $$ProductOptionChoiceOverridesTableReferences
                            ._productIdTable(db),
                    referencedColumn:
                        $$ProductOptionChoiceOverridesTableReferences
                            ._productIdTable(db)
                            .id,
                  ) as T;
                }
                if (optionChoiceId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.optionChoiceId,
                    referencedTable:
                        $$ProductOptionChoiceOverridesTableReferences
                            ._optionChoiceIdTable(db),
                    referencedColumn:
                        $$ProductOptionChoiceOverridesTableReferences
                            ._optionChoiceIdTable(db)
                            .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ProductOptionChoiceOverridesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $ProductOptionChoiceOverridesTable,
        ProductOptionChoiceOverrideRow,
        $$ProductOptionChoiceOverridesTableFilterComposer,
        $$ProductOptionChoiceOverridesTableOrderingComposer,
        $$ProductOptionChoiceOverridesTableAnnotationComposer,
        $$ProductOptionChoiceOverridesTableCreateCompanionBuilder,
        $$ProductOptionChoiceOverridesTableUpdateCompanionBuilder,
        (
          ProductOptionChoiceOverrideRow,
          $$ProductOptionChoiceOverridesTableReferences
        ),
        ProductOptionChoiceOverrideRow,
        PrefetchHooks Function({bool productId, bool optionChoiceId})>;
typedef $$MemberLevelsTableCreateCompanionBuilder = MemberLevelsCompanion
    Function({
  required String id,
  required String name,
  Value<double> discountRate,
  Value<int> minSpend,
  Value<int> minPoints,
  Value<String?> color,
  Value<int> sortOrder,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$MemberLevelsTableUpdateCompanionBuilder = MemberLevelsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<double> discountRate,
  Value<int> minSpend,
  Value<int> minPoints,
  Value<String?> color,
  Value<int> sortOrder,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$MemberLevelsTableFilterComposer
    extends Composer<_$AppDatabase, $MemberLevelsTable> {
  $$MemberLevelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get discountRate => $composableBuilder(
      column: $table.discountRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minSpend => $composableBuilder(
      column: $table.minSpend, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minPoints => $composableBuilder(
      column: $table.minPoints, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$MemberLevelsTableOrderingComposer
    extends Composer<_$AppDatabase, $MemberLevelsTable> {
  $$MemberLevelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get discountRate => $composableBuilder(
      column: $table.discountRate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minSpend => $composableBuilder(
      column: $table.minSpend, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minPoints => $composableBuilder(
      column: $table.minPoints, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$MemberLevelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemberLevelsTable> {
  $$MemberLevelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get discountRate => $composableBuilder(
      column: $table.discountRate, builder: (column) => column);

  GeneratedColumn<int> get minSpend =>
      $composableBuilder(column: $table.minSpend, builder: (column) => column);

  GeneratedColumn<int> get minPoints =>
      $composableBuilder(column: $table.minPoints, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$MemberLevelsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MemberLevelsTable,
    MemberLevelRow,
    $$MemberLevelsTableFilterComposer,
    $$MemberLevelsTableOrderingComposer,
    $$MemberLevelsTableAnnotationComposer,
    $$MemberLevelsTableCreateCompanionBuilder,
    $$MemberLevelsTableUpdateCompanionBuilder,
    (
      MemberLevelRow,
      BaseReferences<_$AppDatabase, $MemberLevelsTable, MemberLevelRow>
    ),
    MemberLevelRow,
    PrefetchHooks Function()> {
  $$MemberLevelsTableTableManager(_$AppDatabase db, $MemberLevelsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemberLevelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemberLevelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemberLevelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> discountRate = const Value.absent(),
            Value<int> minSpend = const Value.absent(),
            Value<int> minPoints = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MemberLevelsCompanion(
            id: id,
            name: name,
            discountRate: discountRate,
            minSpend: minSpend,
            minPoints: minPoints,
            color: color,
            sortOrder: sortOrder,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<double> discountRate = const Value.absent(),
            Value<int> minSpend = const Value.absent(),
            Value<int> minPoints = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MemberLevelsCompanion.insert(
            id: id,
            name: name,
            discountRate: discountRate,
            minSpend: minSpend,
            minPoints: minPoints,
            color: color,
            sortOrder: sortOrder,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MemberLevelsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MemberLevelsTable,
    MemberLevelRow,
    $$MemberLevelsTableFilterComposer,
    $$MemberLevelsTableOrderingComposer,
    $$MemberLevelsTableAnnotationComposer,
    $$MemberLevelsTableCreateCompanionBuilder,
    $$MemberLevelsTableUpdateCompanionBuilder,
    (
      MemberLevelRow,
      BaseReferences<_$AppDatabase, $MemberLevelsTable, MemberLevelRow>
    ),
    MemberLevelRow,
    PrefetchHooks Function()>;
typedef $$MembersTableCreateCompanionBuilder = MembersCompanion Function({
  required String id,
  required String phone,
  required String name,
  Value<String?> email,
  Value<DateTime?> birthday,
  Value<int> points,
  Value<int> totalSpentCents,
  Value<String?> levelId,
  Value<String?> qrCode,
  required DateTime joinedAt,
  Value<DateTime?> lastVisitAt,
  Value<String?> note,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$MembersTableUpdateCompanionBuilder = MembersCompanion Function({
  Value<String> id,
  Value<String> phone,
  Value<String> name,
  Value<String?> email,
  Value<DateTime?> birthday,
  Value<int> points,
  Value<int> totalSpentCents,
  Value<String?> levelId,
  Value<String?> qrCode,
  Value<DateTime> joinedAt,
  Value<DateTime?> lastVisitAt,
  Value<String?> note,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$MembersTableFilterComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get birthday => $composableBuilder(
      column: $table.birthday, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get points => $composableBuilder(
      column: $table.points, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalSpentCents => $composableBuilder(
      column: $table.totalSpentCents,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get levelId => $composableBuilder(
      column: $table.levelId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get qrCode => $composableBuilder(
      column: $table.qrCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get joinedAt => $composableBuilder(
      column: $table.joinedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastVisitAt => $composableBuilder(
      column: $table.lastVisitAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$MembersTableOrderingComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get birthday => $composableBuilder(
      column: $table.birthday, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get points => $composableBuilder(
      column: $table.points, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalSpentCents => $composableBuilder(
      column: $table.totalSpentCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get levelId => $composableBuilder(
      column: $table.levelId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get qrCode => $composableBuilder(
      column: $table.qrCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get joinedAt => $composableBuilder(
      column: $table.joinedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastVisitAt => $composableBuilder(
      column: $table.lastVisitAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$MembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<DateTime> get birthday =>
      $composableBuilder(column: $table.birthday, builder: (column) => column);

  GeneratedColumn<int> get points =>
      $composableBuilder(column: $table.points, builder: (column) => column);

  GeneratedColumn<int> get totalSpentCents => $composableBuilder(
      column: $table.totalSpentCents, builder: (column) => column);

  GeneratedColumn<String> get levelId =>
      $composableBuilder(column: $table.levelId, builder: (column) => column);

  GeneratedColumn<String> get qrCode =>
      $composableBuilder(column: $table.qrCode, builder: (column) => column);

  GeneratedColumn<DateTime> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastVisitAt => $composableBuilder(
      column: $table.lastVisitAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$MembersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MembersTable,
    MemberRow,
    $$MembersTableFilterComposer,
    $$MembersTableOrderingComposer,
    $$MembersTableAnnotationComposer,
    $$MembersTableCreateCompanionBuilder,
    $$MembersTableUpdateCompanionBuilder,
    (MemberRow, BaseReferences<_$AppDatabase, $MembersTable, MemberRow>),
    MemberRow,
    PrefetchHooks Function()> {
  $$MembersTableTableManager(_$AppDatabase db, $MembersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> phone = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<DateTime?> birthday = const Value.absent(),
            Value<int> points = const Value.absent(),
            Value<int> totalSpentCents = const Value.absent(),
            Value<String?> levelId = const Value.absent(),
            Value<String?> qrCode = const Value.absent(),
            Value<DateTime> joinedAt = const Value.absent(),
            Value<DateTime?> lastVisitAt = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MembersCompanion(
            id: id,
            phone: phone,
            name: name,
            email: email,
            birthday: birthday,
            points: points,
            totalSpentCents: totalSpentCents,
            levelId: levelId,
            qrCode: qrCode,
            joinedAt: joinedAt,
            lastVisitAt: lastVisitAt,
            note: note,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String phone,
            required String name,
            Value<String?> email = const Value.absent(),
            Value<DateTime?> birthday = const Value.absent(),
            Value<int> points = const Value.absent(),
            Value<int> totalSpentCents = const Value.absent(),
            Value<String?> levelId = const Value.absent(),
            Value<String?> qrCode = const Value.absent(),
            required DateTime joinedAt,
            Value<DateTime?> lastVisitAt = const Value.absent(),
            Value<String?> note = const Value.absent(),
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MembersCompanion.insert(
            id: id,
            phone: phone,
            name: name,
            email: email,
            birthday: birthday,
            points: points,
            totalSpentCents: totalSpentCents,
            levelId: levelId,
            qrCode: qrCode,
            joinedAt: joinedAt,
            lastVisitAt: lastVisitAt,
            note: note,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MembersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MembersTable,
    MemberRow,
    $$MembersTableFilterComposer,
    $$MembersTableOrderingComposer,
    $$MembersTableAnnotationComposer,
    $$MembersTableCreateCompanionBuilder,
    $$MembersTableUpdateCompanionBuilder,
    (MemberRow, BaseReferences<_$AppDatabase, $MembersTable, MemberRow>),
    MemberRow,
    PrefetchHooks Function()>;
typedef $$CouponsTableCreateCompanionBuilder = CouponsCompanion Function({
  required String id,
  required String code,
  required String type,
  required double value,
  Value<String?> memberId,
  Value<int> minSpendCents,
  Value<DateTime?> expiresAt,
  Value<DateTime?> usedAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$CouponsTableUpdateCompanionBuilder = CouponsCompanion Function({
  Value<String> id,
  Value<String> code,
  Value<String> type,
  Value<double> value,
  Value<String?> memberId,
  Value<int> minSpendCents,
  Value<DateTime?> expiresAt,
  Value<DateTime?> usedAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$CouponsTableFilterComposer
    extends Composer<_$AppDatabase, $CouponsTable> {
  $$CouponsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memberId => $composableBuilder(
      column: $table.memberId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minSpendCents => $composableBuilder(
      column: $table.minSpendCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get usedAt => $composableBuilder(
      column: $table.usedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$CouponsTableOrderingComposer
    extends Composer<_$AppDatabase, $CouponsTable> {
  $$CouponsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memberId => $composableBuilder(
      column: $table.memberId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minSpendCents => $composableBuilder(
      column: $table.minSpendCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get usedAt => $composableBuilder(
      column: $table.usedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CouponsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CouponsTable> {
  $$CouponsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<int> get minSpendCents => $composableBuilder(
      column: $table.minSpendCents, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get usedAt =>
      $composableBuilder(column: $table.usedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CouponsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CouponsTable,
    CouponRow,
    $$CouponsTableFilterComposer,
    $$CouponsTableOrderingComposer,
    $$CouponsTableAnnotationComposer,
    $$CouponsTableCreateCompanionBuilder,
    $$CouponsTableUpdateCompanionBuilder,
    (CouponRow, BaseReferences<_$AppDatabase, $CouponsTable, CouponRow>),
    CouponRow,
    PrefetchHooks Function()> {
  $$CouponsTableTableManager(_$AppDatabase db, $CouponsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CouponsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CouponsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CouponsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<double> value = const Value.absent(),
            Value<String?> memberId = const Value.absent(),
            Value<int> minSpendCents = const Value.absent(),
            Value<DateTime?> expiresAt = const Value.absent(),
            Value<DateTime?> usedAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CouponsCompanion(
            id: id,
            code: code,
            type: type,
            value: value,
            memberId: memberId,
            minSpendCents: minSpendCents,
            expiresAt: expiresAt,
            usedAt: usedAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String code,
            required String type,
            required double value,
            Value<String?> memberId = const Value.absent(),
            Value<int> minSpendCents = const Value.absent(),
            Value<DateTime?> expiresAt = const Value.absent(),
            Value<DateTime?> usedAt = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CouponsCompanion.insert(
            id: id,
            code: code,
            type: type,
            value: value,
            memberId: memberId,
            minSpendCents: minSpendCents,
            expiresAt: expiresAt,
            usedAt: usedAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CouponsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CouponsTable,
    CouponRow,
    $$CouponsTableFilterComposer,
    $$CouponsTableOrderingComposer,
    $$CouponsTableAnnotationComposer,
    $$CouponsTableCreateCompanionBuilder,
    $$CouponsTableUpdateCompanionBuilder,
    (CouponRow, BaseReferences<_$AppDatabase, $CouponsTable, CouponRow>),
    CouponRow,
    PrefetchHooks Function()>;
typedef $$PointTransactionsTableCreateCompanionBuilder
    = PointTransactionsCompanion Function({
  required String id,
  required String memberId,
  required int delta,
  required String reason,
  Value<String?> orderId,
  Value<DateTime?> expiresAt,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$PointTransactionsTableUpdateCompanionBuilder
    = PointTransactionsCompanion Function({
  Value<String> id,
  Value<String> memberId,
  Value<int> delta,
  Value<String> reason,
  Value<String?> orderId,
  Value<DateTime?> expiresAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$PointTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $PointTransactionsTable> {
  $$PointTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memberId => $composableBuilder(
      column: $table.memberId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get delta => $composableBuilder(
      column: $table.delta, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orderId => $composableBuilder(
      column: $table.orderId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PointTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PointTransactionsTable> {
  $$PointTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memberId => $composableBuilder(
      column: $table.memberId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get delta => $composableBuilder(
      column: $table.delta, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orderId => $composableBuilder(
      column: $table.orderId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PointTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PointTransactionsTable> {
  $$PointTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<int> get delta =>
      $composableBuilder(column: $table.delta, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PointTransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PointTransactionsTable,
    PointTransactionRow,
    $$PointTransactionsTableFilterComposer,
    $$PointTransactionsTableOrderingComposer,
    $$PointTransactionsTableAnnotationComposer,
    $$PointTransactionsTableCreateCompanionBuilder,
    $$PointTransactionsTableUpdateCompanionBuilder,
    (
      PointTransactionRow,
      BaseReferences<_$AppDatabase, $PointTransactionsTable,
          PointTransactionRow>
    ),
    PointTransactionRow,
    PrefetchHooks Function()> {
  $$PointTransactionsTableTableManager(
      _$AppDatabase db, $PointTransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PointTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PointTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PointTransactionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> memberId = const Value.absent(),
            Value<int> delta = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<String?> orderId = const Value.absent(),
            Value<DateTime?> expiresAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PointTransactionsCompanion(
            id: id,
            memberId: memberId,
            delta: delta,
            reason: reason,
            orderId: orderId,
            expiresAt: expiresAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String memberId,
            required int delta,
            required String reason,
            Value<String?> orderId = const Value.absent(),
            Value<DateTime?> expiresAt = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PointTransactionsCompanion.insert(
            id: id,
            memberId: memberId,
            delta: delta,
            reason: reason,
            orderId: orderId,
            expiresAt: expiresAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PointTransactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PointTransactionsTable,
    PointTransactionRow,
    $$PointTransactionsTableFilterComposer,
    $$PointTransactionsTableOrderingComposer,
    $$PointTransactionsTableAnnotationComposer,
    $$PointTransactionsTableCreateCompanionBuilder,
    $$PointTransactionsTableUpdateCompanionBuilder,
    (
      PointTransactionRow,
      BaseReferences<_$AppDatabase, $PointTransactionsTable,
          PointTransactionRow>
    ),
    PointTransactionRow,
    PrefetchHooks Function()>;
typedef $$OrdersTableCreateCompanionBuilder = OrdersCompanion Function({
  required String id,
  required String storeId,
  required String terminalId,
  required String cashierId,
  Value<String?> memberId,
  Value<String> status,
  Value<int> subtotalCents,
  Value<int> discountCents,
  Value<int> taxCents,
  Value<int> totalCents,
  Value<int> refundedCents,
  Value<String?> invoiceNumber,
  Value<String?> invoiceCarrier,
  Value<String?> note,
  Value<String?> orderNo,
  Value<String?> tableLabel,
  Value<String?> primaryPaymentMethod,
  Value<String?> sourceGuestOrderId,
  required DateTime createdAt,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$OrdersTableUpdateCompanionBuilder = OrdersCompanion Function({
  Value<String> id,
  Value<String> storeId,
  Value<String> terminalId,
  Value<String> cashierId,
  Value<String?> memberId,
  Value<String> status,
  Value<int> subtotalCents,
  Value<int> discountCents,
  Value<int> taxCents,
  Value<int> totalCents,
  Value<int> refundedCents,
  Value<String?> invoiceNumber,
  Value<String?> invoiceCarrier,
  Value<String?> note,
  Value<String?> orderNo,
  Value<String?> tableLabel,
  Value<String?> primaryPaymentMethod,
  Value<String?> sourceGuestOrderId,
  Value<DateTime> createdAt,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

class $$OrdersTableFilterComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storeId => $composableBuilder(
      column: $table.storeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get terminalId => $composableBuilder(
      column: $table.terminalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cashierId => $composableBuilder(
      column: $table.cashierId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memberId => $composableBuilder(
      column: $table.memberId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get subtotalCents => $composableBuilder(
      column: $table.subtotalCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get discountCents => $composableBuilder(
      column: $table.discountCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get taxCents => $composableBuilder(
      column: $table.taxCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalCents => $composableBuilder(
      column: $table.totalCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get refundedCents => $composableBuilder(
      column: $table.refundedCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get invoiceCarrier => $composableBuilder(
      column: $table.invoiceCarrier,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orderNo => $composableBuilder(
      column: $table.orderNo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tableLabel => $composableBuilder(
      column: $table.tableLabel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get primaryPaymentMethod => $composableBuilder(
      column: $table.primaryPaymentMethod,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceGuestOrderId => $composableBuilder(
      column: $table.sourceGuestOrderId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$OrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storeId => $composableBuilder(
      column: $table.storeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get terminalId => $composableBuilder(
      column: $table.terminalId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cashierId => $composableBuilder(
      column: $table.cashierId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memberId => $composableBuilder(
      column: $table.memberId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get subtotalCents => $composableBuilder(
      column: $table.subtotalCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get discountCents => $composableBuilder(
      column: $table.discountCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get taxCents => $composableBuilder(
      column: $table.taxCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalCents => $composableBuilder(
      column: $table.totalCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get refundedCents => $composableBuilder(
      column: $table.refundedCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get invoiceCarrier => $composableBuilder(
      column: $table.invoiceCarrier,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orderNo => $composableBuilder(
      column: $table.orderNo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tableLabel => $composableBuilder(
      column: $table.tableLabel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get primaryPaymentMethod => $composableBuilder(
      column: $table.primaryPaymentMethod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceGuestOrderId => $composableBuilder(
      column: $table.sourceGuestOrderId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$OrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get terminalId => $composableBuilder(
      column: $table.terminalId, builder: (column) => column);

  GeneratedColumn<String> get cashierId =>
      $composableBuilder(column: $table.cashierId, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get subtotalCents => $composableBuilder(
      column: $table.subtotalCents, builder: (column) => column);

  GeneratedColumn<int> get discountCents => $composableBuilder(
      column: $table.discountCents, builder: (column) => column);

  GeneratedColumn<int> get taxCents =>
      $composableBuilder(column: $table.taxCents, builder: (column) => column);

  GeneratedColumn<int> get totalCents => $composableBuilder(
      column: $table.totalCents, builder: (column) => column);

  GeneratedColumn<int> get refundedCents => $composableBuilder(
      column: $table.refundedCents, builder: (column) => column);

  GeneratedColumn<String> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber, builder: (column) => column);

  GeneratedColumn<String> get invoiceCarrier => $composableBuilder(
      column: $table.invoiceCarrier, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get orderNo =>
      $composableBuilder(column: $table.orderNo, builder: (column) => column);

  GeneratedColumn<String> get tableLabel => $composableBuilder(
      column: $table.tableLabel, builder: (column) => column);

  GeneratedColumn<String> get primaryPaymentMethod => $composableBuilder(
      column: $table.primaryPaymentMethod, builder: (column) => column);

  GeneratedColumn<String> get sourceGuestOrderId => $composableBuilder(
      column: $table.sourceGuestOrderId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$OrdersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OrdersTable,
    OrderRow,
    $$OrdersTableFilterComposer,
    $$OrdersTableOrderingComposer,
    $$OrdersTableAnnotationComposer,
    $$OrdersTableCreateCompanionBuilder,
    $$OrdersTableUpdateCompanionBuilder,
    (OrderRow, BaseReferences<_$AppDatabase, $OrdersTable, OrderRow>),
    OrderRow,
    PrefetchHooks Function()> {
  $$OrdersTableTableManager(_$AppDatabase db, $OrdersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> storeId = const Value.absent(),
            Value<String> terminalId = const Value.absent(),
            Value<String> cashierId = const Value.absent(),
            Value<String?> memberId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> subtotalCents = const Value.absent(),
            Value<int> discountCents = const Value.absent(),
            Value<int> taxCents = const Value.absent(),
            Value<int> totalCents = const Value.absent(),
            Value<int> refundedCents = const Value.absent(),
            Value<String?> invoiceNumber = const Value.absent(),
            Value<String?> invoiceCarrier = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> orderNo = const Value.absent(),
            Value<String?> tableLabel = const Value.absent(),
            Value<String?> primaryPaymentMethod = const Value.absent(),
            Value<String?> sourceGuestOrderId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OrdersCompanion(
            id: id,
            storeId: storeId,
            terminalId: terminalId,
            cashierId: cashierId,
            memberId: memberId,
            status: status,
            subtotalCents: subtotalCents,
            discountCents: discountCents,
            taxCents: taxCents,
            totalCents: totalCents,
            refundedCents: refundedCents,
            invoiceNumber: invoiceNumber,
            invoiceCarrier: invoiceCarrier,
            note: note,
            orderNo: orderNo,
            tableLabel: tableLabel,
            primaryPaymentMethod: primaryPaymentMethod,
            sourceGuestOrderId: sourceGuestOrderId,
            createdAt: createdAt,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String storeId,
            required String terminalId,
            required String cashierId,
            Value<String?> memberId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> subtotalCents = const Value.absent(),
            Value<int> discountCents = const Value.absent(),
            Value<int> taxCents = const Value.absent(),
            Value<int> totalCents = const Value.absent(),
            Value<int> refundedCents = const Value.absent(),
            Value<String?> invoiceNumber = const Value.absent(),
            Value<String?> invoiceCarrier = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> orderNo = const Value.absent(),
            Value<String?> tableLabel = const Value.absent(),
            Value<String?> primaryPaymentMethod = const Value.absent(),
            Value<String?> sourceGuestOrderId = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OrdersCompanion.insert(
            id: id,
            storeId: storeId,
            terminalId: terminalId,
            cashierId: cashierId,
            memberId: memberId,
            status: status,
            subtotalCents: subtotalCents,
            discountCents: discountCents,
            taxCents: taxCents,
            totalCents: totalCents,
            refundedCents: refundedCents,
            invoiceNumber: invoiceNumber,
            invoiceCarrier: invoiceCarrier,
            note: note,
            orderNo: orderNo,
            tableLabel: tableLabel,
            primaryPaymentMethod: primaryPaymentMethod,
            sourceGuestOrderId: sourceGuestOrderId,
            createdAt: createdAt,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OrdersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OrdersTable,
    OrderRow,
    $$OrdersTableFilterComposer,
    $$OrdersTableOrderingComposer,
    $$OrdersTableAnnotationComposer,
    $$OrdersTableCreateCompanionBuilder,
    $$OrdersTableUpdateCompanionBuilder,
    (OrderRow, BaseReferences<_$AppDatabase, $OrdersTable, OrderRow>),
    OrderRow,
    PrefetchHooks Function()>;
typedef $$OrderLinesTableCreateCompanionBuilder = OrderLinesCompanion Function({
  required String id,
  required String orderId,
  required String productId,
  required String productName,
  required String sku,
  required double qty,
  required int unitPriceCents,
  Value<int> lineDiscountCents,
  required int lineTotalCents,
  Value<double> taxRate,
  Value<String?> note,
  Value<String?> optionsJson,
  Value<int> rowid,
});
typedef $$OrderLinesTableUpdateCompanionBuilder = OrderLinesCompanion Function({
  Value<String> id,
  Value<String> orderId,
  Value<String> productId,
  Value<String> productName,
  Value<String> sku,
  Value<double> qty,
  Value<int> unitPriceCents,
  Value<int> lineDiscountCents,
  Value<int> lineTotalCents,
  Value<double> taxRate,
  Value<String?> note,
  Value<String?> optionsJson,
  Value<int> rowid,
});

class $$OrderLinesTableFilterComposer
    extends Composer<_$AppDatabase, $OrderLinesTable> {
  $$OrderLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orderId => $composableBuilder(
      column: $table.orderId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get qty => $composableBuilder(
      column: $table.qty, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get unitPriceCents => $composableBuilder(
      column: $table.unitPriceCents,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lineDiscountCents => $composableBuilder(
      column: $table.lineDiscountCents,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lineTotalCents => $composableBuilder(
      column: $table.lineTotalCents,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get taxRate => $composableBuilder(
      column: $table.taxRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get optionsJson => $composableBuilder(
      column: $table.optionsJson, builder: (column) => ColumnFilters(column));
}

class $$OrderLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $OrderLinesTable> {
  $$OrderLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orderId => $composableBuilder(
      column: $table.orderId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get qty => $composableBuilder(
      column: $table.qty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get unitPriceCents => $composableBuilder(
      column: $table.unitPriceCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lineDiscountCents => $composableBuilder(
      column: $table.lineDiscountCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lineTotalCents => $composableBuilder(
      column: $table.lineTotalCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get taxRate => $composableBuilder(
      column: $table.taxRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get optionsJson => $composableBuilder(
      column: $table.optionsJson, builder: (column) => ColumnOrderings(column));
}

class $$OrderLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrderLinesTable> {
  $$OrderLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<double> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<int> get unitPriceCents => $composableBuilder(
      column: $table.unitPriceCents, builder: (column) => column);

  GeneratedColumn<int> get lineDiscountCents => $composableBuilder(
      column: $table.lineDiscountCents, builder: (column) => column);

  GeneratedColumn<int> get lineTotalCents => $composableBuilder(
      column: $table.lineTotalCents, builder: (column) => column);

  GeneratedColumn<double> get taxRate =>
      $composableBuilder(column: $table.taxRate, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get optionsJson => $composableBuilder(
      column: $table.optionsJson, builder: (column) => column);
}

class $$OrderLinesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OrderLinesTable,
    OrderLineRow,
    $$OrderLinesTableFilterComposer,
    $$OrderLinesTableOrderingComposer,
    $$OrderLinesTableAnnotationComposer,
    $$OrderLinesTableCreateCompanionBuilder,
    $$OrderLinesTableUpdateCompanionBuilder,
    (
      OrderLineRow,
      BaseReferences<_$AppDatabase, $OrderLinesTable, OrderLineRow>
    ),
    OrderLineRow,
    PrefetchHooks Function()> {
  $$OrderLinesTableTableManager(_$AppDatabase db, $OrderLinesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrderLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrderLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrderLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> orderId = const Value.absent(),
            Value<String> productId = const Value.absent(),
            Value<String> productName = const Value.absent(),
            Value<String> sku = const Value.absent(),
            Value<double> qty = const Value.absent(),
            Value<int> unitPriceCents = const Value.absent(),
            Value<int> lineDiscountCents = const Value.absent(),
            Value<int> lineTotalCents = const Value.absent(),
            Value<double> taxRate = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> optionsJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OrderLinesCompanion(
            id: id,
            orderId: orderId,
            productId: productId,
            productName: productName,
            sku: sku,
            qty: qty,
            unitPriceCents: unitPriceCents,
            lineDiscountCents: lineDiscountCents,
            lineTotalCents: lineTotalCents,
            taxRate: taxRate,
            note: note,
            optionsJson: optionsJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String orderId,
            required String productId,
            required String productName,
            required String sku,
            required double qty,
            required int unitPriceCents,
            Value<int> lineDiscountCents = const Value.absent(),
            required int lineTotalCents,
            Value<double> taxRate = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> optionsJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OrderLinesCompanion.insert(
            id: id,
            orderId: orderId,
            productId: productId,
            productName: productName,
            sku: sku,
            qty: qty,
            unitPriceCents: unitPriceCents,
            lineDiscountCents: lineDiscountCents,
            lineTotalCents: lineTotalCents,
            taxRate: taxRate,
            note: note,
            optionsJson: optionsJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OrderLinesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OrderLinesTable,
    OrderLineRow,
    $$OrderLinesTableFilterComposer,
    $$OrderLinesTableOrderingComposer,
    $$OrderLinesTableAnnotationComposer,
    $$OrderLinesTableCreateCompanionBuilder,
    $$OrderLinesTableUpdateCompanionBuilder,
    (
      OrderLineRow,
      BaseReferences<_$AppDatabase, $OrderLinesTable, OrderLineRow>
    ),
    OrderLineRow,
    PrefetchHooks Function()>;
typedef $$PaymentsTableCreateCompanionBuilder = PaymentsCompanion Function({
  required String id,
  required String orderId,
  required String method,
  required int amountCents,
  Value<String> status,
  Value<String?> gatewayRef,
  Value<String?> gatewayResponseJson,
  Value<int?> tenderedCents,
  Value<int?> changeDueCents,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$PaymentsTableUpdateCompanionBuilder = PaymentsCompanion Function({
  Value<String> id,
  Value<String> orderId,
  Value<String> method,
  Value<int> amountCents,
  Value<String> status,
  Value<String?> gatewayRef,
  Value<String?> gatewayResponseJson,
  Value<int?> tenderedCents,
  Value<int?> changeDueCents,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$PaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orderId => $composableBuilder(
      column: $table.orderId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gatewayRef => $composableBuilder(
      column: $table.gatewayRef, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gatewayResponseJson => $composableBuilder(
      column: $table.gatewayResponseJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tenderedCents => $composableBuilder(
      column: $table.tenderedCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get changeDueCents => $composableBuilder(
      column: $table.changeDueCents,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orderId => $composableBuilder(
      column: $table.orderId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gatewayRef => $composableBuilder(
      column: $table.gatewayRef, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gatewayResponseJson => $composableBuilder(
      column: $table.gatewayResponseJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tenderedCents => $composableBuilder(
      column: $table.tenderedCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get changeDueCents => $composableBuilder(
      column: $table.changeDueCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get gatewayRef => $composableBuilder(
      column: $table.gatewayRef, builder: (column) => column);

  GeneratedColumn<String> get gatewayResponseJson => $composableBuilder(
      column: $table.gatewayResponseJson, builder: (column) => column);

  GeneratedColumn<int> get tenderedCents => $composableBuilder(
      column: $table.tenderedCents, builder: (column) => column);

  GeneratedColumn<int> get changeDueCents => $composableBuilder(
      column: $table.changeDueCents, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PaymentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PaymentsTable,
    PaymentRow,
    $$PaymentsTableFilterComposer,
    $$PaymentsTableOrderingComposer,
    $$PaymentsTableAnnotationComposer,
    $$PaymentsTableCreateCompanionBuilder,
    $$PaymentsTableUpdateCompanionBuilder,
    (PaymentRow, BaseReferences<_$AppDatabase, $PaymentsTable, PaymentRow>),
    PaymentRow,
    PrefetchHooks Function()> {
  $$PaymentsTableTableManager(_$AppDatabase db, $PaymentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> orderId = const Value.absent(),
            Value<String> method = const Value.absent(),
            Value<int> amountCents = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> gatewayRef = const Value.absent(),
            Value<String?> gatewayResponseJson = const Value.absent(),
            Value<int?> tenderedCents = const Value.absent(),
            Value<int?> changeDueCents = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PaymentsCompanion(
            id: id,
            orderId: orderId,
            method: method,
            amountCents: amountCents,
            status: status,
            gatewayRef: gatewayRef,
            gatewayResponseJson: gatewayResponseJson,
            tenderedCents: tenderedCents,
            changeDueCents: changeDueCents,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String orderId,
            required String method,
            required int amountCents,
            Value<String> status = const Value.absent(),
            Value<String?> gatewayRef = const Value.absent(),
            Value<String?> gatewayResponseJson = const Value.absent(),
            Value<int?> tenderedCents = const Value.absent(),
            Value<int?> changeDueCents = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PaymentsCompanion.insert(
            id: id,
            orderId: orderId,
            method: method,
            amountCents: amountCents,
            status: status,
            gatewayRef: gatewayRef,
            gatewayResponseJson: gatewayResponseJson,
            tenderedCents: tenderedCents,
            changeDueCents: changeDueCents,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PaymentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PaymentsTable,
    PaymentRow,
    $$PaymentsTableFilterComposer,
    $$PaymentsTableOrderingComposer,
    $$PaymentsTableAnnotationComposer,
    $$PaymentsTableCreateCompanionBuilder,
    $$PaymentsTableUpdateCompanionBuilder,
    (PaymentRow, BaseReferences<_$AppDatabase, $PaymentsTable, PaymentRow>),
    PaymentRow,
    PrefetchHooks Function()>;
typedef $$RefundsTableCreateCompanionBuilder = RefundsCompanion Function({
  required String id,
  required String orderId,
  required String userId,
  required String method,
  required int totalAmountCents,
  Value<String?> reason,
  Value<String?> gatewayRef,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$RefundsTableUpdateCompanionBuilder = RefundsCompanion Function({
  Value<String> id,
  Value<String> orderId,
  Value<String> userId,
  Value<String> method,
  Value<int> totalAmountCents,
  Value<String?> reason,
  Value<String?> gatewayRef,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$RefundsTableFilterComposer
    extends Composer<_$AppDatabase, $RefundsTable> {
  $$RefundsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orderId => $composableBuilder(
      column: $table.orderId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalAmountCents => $composableBuilder(
      column: $table.totalAmountCents,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gatewayRef => $composableBuilder(
      column: $table.gatewayRef, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$RefundsTableOrderingComposer
    extends Composer<_$AppDatabase, $RefundsTable> {
  $$RefundsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orderId => $composableBuilder(
      column: $table.orderId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalAmountCents => $composableBuilder(
      column: $table.totalAmountCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gatewayRef => $composableBuilder(
      column: $table.gatewayRef, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$RefundsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RefundsTable> {
  $$RefundsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<int> get totalAmountCents => $composableBuilder(
      column: $table.totalAmountCents, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get gatewayRef => $composableBuilder(
      column: $table.gatewayRef, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$RefundsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RefundsTable,
    RefundRow,
    $$RefundsTableFilterComposer,
    $$RefundsTableOrderingComposer,
    $$RefundsTableAnnotationComposer,
    $$RefundsTableCreateCompanionBuilder,
    $$RefundsTableUpdateCompanionBuilder,
    (RefundRow, BaseReferences<_$AppDatabase, $RefundsTable, RefundRow>),
    RefundRow,
    PrefetchHooks Function()> {
  $$RefundsTableTableManager(_$AppDatabase db, $RefundsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RefundsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RefundsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RefundsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> orderId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> method = const Value.absent(),
            Value<int> totalAmountCents = const Value.absent(),
            Value<String?> reason = const Value.absent(),
            Value<String?> gatewayRef = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RefundsCompanion(
            id: id,
            orderId: orderId,
            userId: userId,
            method: method,
            totalAmountCents: totalAmountCents,
            reason: reason,
            gatewayRef: gatewayRef,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String orderId,
            required String userId,
            required String method,
            required int totalAmountCents,
            Value<String?> reason = const Value.absent(),
            Value<String?> gatewayRef = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              RefundsCompanion.insert(
            id: id,
            orderId: orderId,
            userId: userId,
            method: method,
            totalAmountCents: totalAmountCents,
            reason: reason,
            gatewayRef: gatewayRef,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RefundsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RefundsTable,
    RefundRow,
    $$RefundsTableFilterComposer,
    $$RefundsTableOrderingComposer,
    $$RefundsTableAnnotationComposer,
    $$RefundsTableCreateCompanionBuilder,
    $$RefundsTableUpdateCompanionBuilder,
    (RefundRow, BaseReferences<_$AppDatabase, $RefundsTable, RefundRow>),
    RefundRow,
    PrefetchHooks Function()>;
typedef $$RefundLinesTableCreateCompanionBuilder = RefundLinesCompanion
    Function({
  required String id,
  required String refundId,
  required String orderLineId,
  required double qty,
  required int amountCents,
  Value<int> rowid,
});
typedef $$RefundLinesTableUpdateCompanionBuilder = RefundLinesCompanion
    Function({
  Value<String> id,
  Value<String> refundId,
  Value<String> orderLineId,
  Value<double> qty,
  Value<int> amountCents,
  Value<int> rowid,
});

class $$RefundLinesTableFilterComposer
    extends Composer<_$AppDatabase, $RefundLinesTable> {
  $$RefundLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get refundId => $composableBuilder(
      column: $table.refundId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orderLineId => $composableBuilder(
      column: $table.orderLineId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get qty => $composableBuilder(
      column: $table.qty, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => ColumnFilters(column));
}

class $$RefundLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $RefundLinesTable> {
  $$RefundLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get refundId => $composableBuilder(
      column: $table.refundId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orderLineId => $composableBuilder(
      column: $table.orderLineId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get qty => $composableBuilder(
      column: $table.qty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => ColumnOrderings(column));
}

class $$RefundLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RefundLinesTable> {
  $$RefundLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get refundId =>
      $composableBuilder(column: $table.refundId, builder: (column) => column);

  GeneratedColumn<String> get orderLineId => $composableBuilder(
      column: $table.orderLineId, builder: (column) => column);

  GeneratedColumn<double> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => column);
}

class $$RefundLinesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RefundLinesTable,
    RefundLineRow,
    $$RefundLinesTableFilterComposer,
    $$RefundLinesTableOrderingComposer,
    $$RefundLinesTableAnnotationComposer,
    $$RefundLinesTableCreateCompanionBuilder,
    $$RefundLinesTableUpdateCompanionBuilder,
    (
      RefundLineRow,
      BaseReferences<_$AppDatabase, $RefundLinesTable, RefundLineRow>
    ),
    RefundLineRow,
    PrefetchHooks Function()> {
  $$RefundLinesTableTableManager(_$AppDatabase db, $RefundLinesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RefundLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RefundLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RefundLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> refundId = const Value.absent(),
            Value<String> orderLineId = const Value.absent(),
            Value<double> qty = const Value.absent(),
            Value<int> amountCents = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RefundLinesCompanion(
            id: id,
            refundId: refundId,
            orderLineId: orderLineId,
            qty: qty,
            amountCents: amountCents,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String refundId,
            required String orderLineId,
            required double qty,
            required int amountCents,
            Value<int> rowid = const Value.absent(),
          }) =>
              RefundLinesCompanion.insert(
            id: id,
            refundId: refundId,
            orderLineId: orderLineId,
            qty: qty,
            amountCents: amountCents,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RefundLinesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RefundLinesTable,
    RefundLineRow,
    $$RefundLinesTableFilterComposer,
    $$RefundLinesTableOrderingComposer,
    $$RefundLinesTableAnnotationComposer,
    $$RefundLinesTableCreateCompanionBuilder,
    $$RefundLinesTableUpdateCompanionBuilder,
    (
      RefundLineRow,
      BaseReferences<_$AppDatabase, $RefundLinesTable, RefundLineRow>
    ),
    RefundLineRow,
    PrefetchHooks Function()>;
typedef $$InventoryLevelsTableCreateCompanionBuilder = InventoryLevelsCompanion
    Function({
  required String id,
  required String storeId,
  required String productId,
  Value<double> onHand,
  Value<double> safetyStock,
  Value<double> reserved,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$InventoryLevelsTableUpdateCompanionBuilder = InventoryLevelsCompanion
    Function({
  Value<String> id,
  Value<String> storeId,
  Value<String> productId,
  Value<double> onHand,
  Value<double> safetyStock,
  Value<double> reserved,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$InventoryLevelsTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryLevelsTable> {
  $$InventoryLevelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storeId => $composableBuilder(
      column: $table.storeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get onHand => $composableBuilder(
      column: $table.onHand, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get safetyStock => $composableBuilder(
      column: $table.safetyStock, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get reserved => $composableBuilder(
      column: $table.reserved, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$InventoryLevelsTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryLevelsTable> {
  $$InventoryLevelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storeId => $composableBuilder(
      column: $table.storeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get onHand => $composableBuilder(
      column: $table.onHand, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get safetyStock => $composableBuilder(
      column: $table.safetyStock, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get reserved => $composableBuilder(
      column: $table.reserved, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$InventoryLevelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryLevelsTable> {
  $$InventoryLevelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<double> get onHand =>
      $composableBuilder(column: $table.onHand, builder: (column) => column);

  GeneratedColumn<double> get safetyStock => $composableBuilder(
      column: $table.safetyStock, builder: (column) => column);

  GeneratedColumn<double> get reserved =>
      $composableBuilder(column: $table.reserved, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$InventoryLevelsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InventoryLevelsTable,
    InventoryLevelRow,
    $$InventoryLevelsTableFilterComposer,
    $$InventoryLevelsTableOrderingComposer,
    $$InventoryLevelsTableAnnotationComposer,
    $$InventoryLevelsTableCreateCompanionBuilder,
    $$InventoryLevelsTableUpdateCompanionBuilder,
    (
      InventoryLevelRow,
      BaseReferences<_$AppDatabase, $InventoryLevelsTable, InventoryLevelRow>
    ),
    InventoryLevelRow,
    PrefetchHooks Function()> {
  $$InventoryLevelsTableTableManager(
      _$AppDatabase db, $InventoryLevelsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryLevelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryLevelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryLevelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> storeId = const Value.absent(),
            Value<String> productId = const Value.absent(),
            Value<double> onHand = const Value.absent(),
            Value<double> safetyStock = const Value.absent(),
            Value<double> reserved = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InventoryLevelsCompanion(
            id: id,
            storeId: storeId,
            productId: productId,
            onHand: onHand,
            safetyStock: safetyStock,
            reserved: reserved,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String storeId,
            required String productId,
            Value<double> onHand = const Value.absent(),
            Value<double> safetyStock = const Value.absent(),
            Value<double> reserved = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              InventoryLevelsCompanion.insert(
            id: id,
            storeId: storeId,
            productId: productId,
            onHand: onHand,
            safetyStock: safetyStock,
            reserved: reserved,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$InventoryLevelsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InventoryLevelsTable,
    InventoryLevelRow,
    $$InventoryLevelsTableFilterComposer,
    $$InventoryLevelsTableOrderingComposer,
    $$InventoryLevelsTableAnnotationComposer,
    $$InventoryLevelsTableCreateCompanionBuilder,
    $$InventoryLevelsTableUpdateCompanionBuilder,
    (
      InventoryLevelRow,
      BaseReferences<_$AppDatabase, $InventoryLevelsTable, InventoryLevelRow>
    ),
    InventoryLevelRow,
    PrefetchHooks Function()>;
typedef $$InventoryMovementsTableCreateCompanionBuilder
    = InventoryMovementsCompanion Function({
  required String id,
  required String storeId,
  required String productId,
  required double qtyDelta,
  required String reason,
  Value<String?> refType,
  Value<String?> refId,
  Value<String?> terminalId,
  Value<String?> userId,
  Value<String?> note,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$InventoryMovementsTableUpdateCompanionBuilder
    = InventoryMovementsCompanion Function({
  Value<String> id,
  Value<String> storeId,
  Value<String> productId,
  Value<double> qtyDelta,
  Value<String> reason,
  Value<String?> refType,
  Value<String?> refId,
  Value<String?> terminalId,
  Value<String?> userId,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$InventoryMovementsTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryMovementsTable> {
  $$InventoryMovementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storeId => $composableBuilder(
      column: $table.storeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get qtyDelta => $composableBuilder(
      column: $table.qtyDelta, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get refType => $composableBuilder(
      column: $table.refType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get refId => $composableBuilder(
      column: $table.refId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get terminalId => $composableBuilder(
      column: $table.terminalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$InventoryMovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryMovementsTable> {
  $$InventoryMovementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storeId => $composableBuilder(
      column: $table.storeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get qtyDelta => $composableBuilder(
      column: $table.qtyDelta, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get refType => $composableBuilder(
      column: $table.refType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get refId => $composableBuilder(
      column: $table.refId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get terminalId => $composableBuilder(
      column: $table.terminalId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$InventoryMovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryMovementsTable> {
  $$InventoryMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<double> get qtyDelta =>
      $composableBuilder(column: $table.qtyDelta, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get refType =>
      $composableBuilder(column: $table.refType, builder: (column) => column);

  GeneratedColumn<String> get refId =>
      $composableBuilder(column: $table.refId, builder: (column) => column);

  GeneratedColumn<String> get terminalId => $composableBuilder(
      column: $table.terminalId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$InventoryMovementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InventoryMovementsTable,
    InventoryMovementRow,
    $$InventoryMovementsTableFilterComposer,
    $$InventoryMovementsTableOrderingComposer,
    $$InventoryMovementsTableAnnotationComposer,
    $$InventoryMovementsTableCreateCompanionBuilder,
    $$InventoryMovementsTableUpdateCompanionBuilder,
    (
      InventoryMovementRow,
      BaseReferences<_$AppDatabase, $InventoryMovementsTable,
          InventoryMovementRow>
    ),
    InventoryMovementRow,
    PrefetchHooks Function()> {
  $$InventoryMovementsTableTableManager(
      _$AppDatabase db, $InventoryMovementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryMovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryMovementsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> storeId = const Value.absent(),
            Value<String> productId = const Value.absent(),
            Value<double> qtyDelta = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<String?> refType = const Value.absent(),
            Value<String?> refId = const Value.absent(),
            Value<String?> terminalId = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InventoryMovementsCompanion(
            id: id,
            storeId: storeId,
            productId: productId,
            qtyDelta: qtyDelta,
            reason: reason,
            refType: refType,
            refId: refId,
            terminalId: terminalId,
            userId: userId,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String storeId,
            required String productId,
            required double qtyDelta,
            required String reason,
            Value<String?> refType = const Value.absent(),
            Value<String?> refId = const Value.absent(),
            Value<String?> terminalId = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> note = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              InventoryMovementsCompanion.insert(
            id: id,
            storeId: storeId,
            productId: productId,
            qtyDelta: qtyDelta,
            reason: reason,
            refType: refType,
            refId: refId,
            terminalId: terminalId,
            userId: userId,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$InventoryMovementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InventoryMovementsTable,
    InventoryMovementRow,
    $$InventoryMovementsTableFilterComposer,
    $$InventoryMovementsTableOrderingComposer,
    $$InventoryMovementsTableAnnotationComposer,
    $$InventoryMovementsTableCreateCompanionBuilder,
    $$InventoryMovementsTableUpdateCompanionBuilder,
    (
      InventoryMovementRow,
      BaseReferences<_$AppDatabase, $InventoryMovementsTable,
          InventoryMovementRow>
    ),
    InventoryMovementRow,
    PrefetchHooks Function()>;
typedef $$TransferOrdersTableCreateCompanionBuilder = TransferOrdersCompanion
    Function({
  required String id,
  required String fromStoreId,
  required String toStoreId,
  Value<String> status,
  Value<DateTime?> dispatchedAt,
  Value<DateTime?> receivedAt,
  Value<String?> note,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$TransferOrdersTableUpdateCompanionBuilder = TransferOrdersCompanion
    Function({
  Value<String> id,
  Value<String> fromStoreId,
  Value<String> toStoreId,
  Value<String> status,
  Value<DateTime?> dispatchedAt,
  Value<DateTime?> receivedAt,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$TransferOrdersTableFilterComposer
    extends Composer<_$AppDatabase, $TransferOrdersTable> {
  $$TransferOrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fromStoreId => $composableBuilder(
      column: $table.fromStoreId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toStoreId => $composableBuilder(
      column: $table.toStoreId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dispatchedAt => $composableBuilder(
      column: $table.dispatchedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$TransferOrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $TransferOrdersTable> {
  $$TransferOrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fromStoreId => $composableBuilder(
      column: $table.fromStoreId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toStoreId => $composableBuilder(
      column: $table.toStoreId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dispatchedAt => $composableBuilder(
      column: $table.dispatchedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$TransferOrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransferOrdersTable> {
  $$TransferOrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fromStoreId => $composableBuilder(
      column: $table.fromStoreId, builder: (column) => column);

  GeneratedColumn<String> get toStoreId =>
      $composableBuilder(column: $table.toStoreId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get dispatchedAt => $composableBuilder(
      column: $table.dispatchedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TransferOrdersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransferOrdersTable,
    TransferOrderRow,
    $$TransferOrdersTableFilterComposer,
    $$TransferOrdersTableOrderingComposer,
    $$TransferOrdersTableAnnotationComposer,
    $$TransferOrdersTableCreateCompanionBuilder,
    $$TransferOrdersTableUpdateCompanionBuilder,
    (
      TransferOrderRow,
      BaseReferences<_$AppDatabase, $TransferOrdersTable, TransferOrderRow>
    ),
    TransferOrderRow,
    PrefetchHooks Function()> {
  $$TransferOrdersTableTableManager(
      _$AppDatabase db, $TransferOrdersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransferOrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransferOrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransferOrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> fromStoreId = const Value.absent(),
            Value<String> toStoreId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime?> dispatchedAt = const Value.absent(),
            Value<DateTime?> receivedAt = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransferOrdersCompanion(
            id: id,
            fromStoreId: fromStoreId,
            toStoreId: toStoreId,
            status: status,
            dispatchedAt: dispatchedAt,
            receivedAt: receivedAt,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String fromStoreId,
            required String toStoreId,
            Value<String> status = const Value.absent(),
            Value<DateTime?> dispatchedAt = const Value.absent(),
            Value<DateTime?> receivedAt = const Value.absent(),
            Value<String?> note = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TransferOrdersCompanion.insert(
            id: id,
            fromStoreId: fromStoreId,
            toStoreId: toStoreId,
            status: status,
            dispatchedAt: dispatchedAt,
            receivedAt: receivedAt,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TransferOrdersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransferOrdersTable,
    TransferOrderRow,
    $$TransferOrdersTableFilterComposer,
    $$TransferOrdersTableOrderingComposer,
    $$TransferOrdersTableAnnotationComposer,
    $$TransferOrdersTableCreateCompanionBuilder,
    $$TransferOrdersTableUpdateCompanionBuilder,
    (
      TransferOrderRow,
      BaseReferences<_$AppDatabase, $TransferOrdersTable, TransferOrderRow>
    ),
    TransferOrderRow,
    PrefetchHooks Function()>;
typedef $$TransferLinesTableCreateCompanionBuilder = TransferLinesCompanion
    Function({
  required String id,
  required String transferId,
  required String productId,
  required double qty,
  Value<double?> receivedQty,
  Value<int> rowid,
});
typedef $$TransferLinesTableUpdateCompanionBuilder = TransferLinesCompanion
    Function({
  Value<String> id,
  Value<String> transferId,
  Value<String> productId,
  Value<double> qty,
  Value<double?> receivedQty,
  Value<int> rowid,
});

class $$TransferLinesTableFilterComposer
    extends Composer<_$AppDatabase, $TransferLinesTable> {
  $$TransferLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transferId => $composableBuilder(
      column: $table.transferId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get qty => $composableBuilder(
      column: $table.qty, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get receivedQty => $composableBuilder(
      column: $table.receivedQty, builder: (column) => ColumnFilters(column));
}

class $$TransferLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $TransferLinesTable> {
  $$TransferLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transferId => $composableBuilder(
      column: $table.transferId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get qty => $composableBuilder(
      column: $table.qty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get receivedQty => $composableBuilder(
      column: $table.receivedQty, builder: (column) => ColumnOrderings(column));
}

class $$TransferLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransferLinesTable> {
  $$TransferLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get transferId => $composableBuilder(
      column: $table.transferId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<double> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<double> get receivedQty => $composableBuilder(
      column: $table.receivedQty, builder: (column) => column);
}

class $$TransferLinesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransferLinesTable,
    TransferLineRow,
    $$TransferLinesTableFilterComposer,
    $$TransferLinesTableOrderingComposer,
    $$TransferLinesTableAnnotationComposer,
    $$TransferLinesTableCreateCompanionBuilder,
    $$TransferLinesTableUpdateCompanionBuilder,
    (
      TransferLineRow,
      BaseReferences<_$AppDatabase, $TransferLinesTable, TransferLineRow>
    ),
    TransferLineRow,
    PrefetchHooks Function()> {
  $$TransferLinesTableTableManager(_$AppDatabase db, $TransferLinesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransferLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransferLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransferLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> transferId = const Value.absent(),
            Value<String> productId = const Value.absent(),
            Value<double> qty = const Value.absent(),
            Value<double?> receivedQty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransferLinesCompanion(
            id: id,
            transferId: transferId,
            productId: productId,
            qty: qty,
            receivedQty: receivedQty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String transferId,
            required String productId,
            required double qty,
            Value<double?> receivedQty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransferLinesCompanion.insert(
            id: id,
            transferId: transferId,
            productId: productId,
            qty: qty,
            receivedQty: receivedQty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TransferLinesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransferLinesTable,
    TransferLineRow,
    $$TransferLinesTableFilterComposer,
    $$TransferLinesTableOrderingComposer,
    $$TransferLinesTableAnnotationComposer,
    $$TransferLinesTableCreateCompanionBuilder,
    $$TransferLinesTableUpdateCompanionBuilder,
    (
      TransferLineRow,
      BaseReferences<_$AppDatabase, $TransferLinesTable, TransferLineRow>
    ),
    TransferLineRow,
    PrefetchHooks Function()>;
typedef $$StocktakesTableCreateCompanionBuilder = StocktakesCompanion Function({
  required String id,
  required String storeId,
  Value<DateTime?> completedAt,
  Value<String?> note,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$StocktakesTableUpdateCompanionBuilder = StocktakesCompanion Function({
  Value<String> id,
  Value<String> storeId,
  Value<DateTime?> completedAt,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$StocktakesTableFilterComposer
    extends Composer<_$AppDatabase, $StocktakesTable> {
  $$StocktakesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storeId => $composableBuilder(
      column: $table.storeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$StocktakesTableOrderingComposer
    extends Composer<_$AppDatabase, $StocktakesTable> {
  $$StocktakesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storeId => $composableBuilder(
      column: $table.storeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$StocktakesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StocktakesTable> {
  $$StocktakesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$StocktakesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StocktakesTable,
    StocktakeRow,
    $$StocktakesTableFilterComposer,
    $$StocktakesTableOrderingComposer,
    $$StocktakesTableAnnotationComposer,
    $$StocktakesTableCreateCompanionBuilder,
    $$StocktakesTableUpdateCompanionBuilder,
    (
      StocktakeRow,
      BaseReferences<_$AppDatabase, $StocktakesTable, StocktakeRow>
    ),
    StocktakeRow,
    PrefetchHooks Function()> {
  $$StocktakesTableTableManager(_$AppDatabase db, $StocktakesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StocktakesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StocktakesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StocktakesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> storeId = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StocktakesCompanion(
            id: id,
            storeId: storeId,
            completedAt: completedAt,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String storeId,
            Value<DateTime?> completedAt = const Value.absent(),
            Value<String?> note = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              StocktakesCompanion.insert(
            id: id,
            storeId: storeId,
            completedAt: completedAt,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StocktakesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StocktakesTable,
    StocktakeRow,
    $$StocktakesTableFilterComposer,
    $$StocktakesTableOrderingComposer,
    $$StocktakesTableAnnotationComposer,
    $$StocktakesTableCreateCompanionBuilder,
    $$StocktakesTableUpdateCompanionBuilder,
    (
      StocktakeRow,
      BaseReferences<_$AppDatabase, $StocktakesTable, StocktakeRow>
    ),
    StocktakeRow,
    PrefetchHooks Function()>;
typedef $$StocktakeLinesTableCreateCompanionBuilder = StocktakeLinesCompanion
    Function({
  required String id,
  required String stocktakeId,
  required String productId,
  required double expectedQty,
  required double actualQty,
  Value<int> rowid,
});
typedef $$StocktakeLinesTableUpdateCompanionBuilder = StocktakeLinesCompanion
    Function({
  Value<String> id,
  Value<String> stocktakeId,
  Value<String> productId,
  Value<double> expectedQty,
  Value<double> actualQty,
  Value<int> rowid,
});

class $$StocktakeLinesTableFilterComposer
    extends Composer<_$AppDatabase, $StocktakeLinesTable> {
  $$StocktakeLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stocktakeId => $composableBuilder(
      column: $table.stocktakeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get expectedQty => $composableBuilder(
      column: $table.expectedQty, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get actualQty => $composableBuilder(
      column: $table.actualQty, builder: (column) => ColumnFilters(column));
}

class $$StocktakeLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $StocktakeLinesTable> {
  $$StocktakeLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stocktakeId => $composableBuilder(
      column: $table.stocktakeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get expectedQty => $composableBuilder(
      column: $table.expectedQty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get actualQty => $composableBuilder(
      column: $table.actualQty, builder: (column) => ColumnOrderings(column));
}

class $$StocktakeLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StocktakeLinesTable> {
  $$StocktakeLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get stocktakeId => $composableBuilder(
      column: $table.stocktakeId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<double> get expectedQty => $composableBuilder(
      column: $table.expectedQty, builder: (column) => column);

  GeneratedColumn<double> get actualQty =>
      $composableBuilder(column: $table.actualQty, builder: (column) => column);
}

class $$StocktakeLinesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StocktakeLinesTable,
    StocktakeLineRow,
    $$StocktakeLinesTableFilterComposer,
    $$StocktakeLinesTableOrderingComposer,
    $$StocktakeLinesTableAnnotationComposer,
    $$StocktakeLinesTableCreateCompanionBuilder,
    $$StocktakeLinesTableUpdateCompanionBuilder,
    (
      StocktakeLineRow,
      BaseReferences<_$AppDatabase, $StocktakeLinesTable, StocktakeLineRow>
    ),
    StocktakeLineRow,
    PrefetchHooks Function()> {
  $$StocktakeLinesTableTableManager(
      _$AppDatabase db, $StocktakeLinesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StocktakeLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StocktakeLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StocktakeLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> stocktakeId = const Value.absent(),
            Value<String> productId = const Value.absent(),
            Value<double> expectedQty = const Value.absent(),
            Value<double> actualQty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StocktakeLinesCompanion(
            id: id,
            stocktakeId: stocktakeId,
            productId: productId,
            expectedQty: expectedQty,
            actualQty: actualQty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String stocktakeId,
            required String productId,
            required double expectedQty,
            required double actualQty,
            Value<int> rowid = const Value.absent(),
          }) =>
              StocktakeLinesCompanion.insert(
            id: id,
            stocktakeId: stocktakeId,
            productId: productId,
            expectedQty: expectedQty,
            actualQty: actualQty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StocktakeLinesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StocktakeLinesTable,
    StocktakeLineRow,
    $$StocktakeLinesTableFilterComposer,
    $$StocktakeLinesTableOrderingComposer,
    $$StocktakeLinesTableAnnotationComposer,
    $$StocktakeLinesTableCreateCompanionBuilder,
    $$StocktakeLinesTableUpdateCompanionBuilder,
    (
      StocktakeLineRow,
      BaseReferences<_$AppDatabase, $StocktakeLinesTable, StocktakeLineRow>
    ),
    StocktakeLineRow,
    PrefetchHooks Function()>;
typedef $$PromotionsTableCreateCompanionBuilder = PromotionsCompanion Function({
  required String id,
  required String name,
  required String strategy,
  required String configJson,
  Value<int> priority,
  Value<DateTime?> startsAt,
  Value<DateTime?> endsAt,
  Value<bool> isActive,
  Value<bool> stackable,
  Value<String> applicableProductIdsJson,
  Value<String> applicableCategoryIdsJson,
  Value<String> memberLevelIdsJson,
  Value<String?> description,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$PromotionsTableUpdateCompanionBuilder = PromotionsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> strategy,
  Value<String> configJson,
  Value<int> priority,
  Value<DateTime?> startsAt,
  Value<DateTime?> endsAt,
  Value<bool> isActive,
  Value<bool> stackable,
  Value<String> applicableProductIdsJson,
  Value<String> applicableCategoryIdsJson,
  Value<String> memberLevelIdsJson,
  Value<String?> description,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$PromotionsTableFilterComposer
    extends Composer<_$AppDatabase, $PromotionsTable> {
  $$PromotionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get strategy => $composableBuilder(
      column: $table.strategy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get configJson => $composableBuilder(
      column: $table.configJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startsAt => $composableBuilder(
      column: $table.startsAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endsAt => $composableBuilder(
      column: $table.endsAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get stackable => $composableBuilder(
      column: $table.stackable, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get applicableProductIdsJson => $composableBuilder(
      column: $table.applicableProductIdsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get applicableCategoryIdsJson => $composableBuilder(
      column: $table.applicableCategoryIdsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memberLevelIdsJson => $composableBuilder(
      column: $table.memberLevelIdsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$PromotionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PromotionsTable> {
  $$PromotionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get strategy => $composableBuilder(
      column: $table.strategy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get configJson => $composableBuilder(
      column: $table.configJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startsAt => $composableBuilder(
      column: $table.startsAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endsAt => $composableBuilder(
      column: $table.endsAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get stackable => $composableBuilder(
      column: $table.stackable, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get applicableProductIdsJson => $composableBuilder(
      column: $table.applicableProductIdsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get applicableCategoryIdsJson => $composableBuilder(
      column: $table.applicableCategoryIdsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memberLevelIdsJson => $composableBuilder(
      column: $table.memberLevelIdsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$PromotionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PromotionsTable> {
  $$PromotionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get strategy =>
      $composableBuilder(column: $table.strategy, builder: (column) => column);

  GeneratedColumn<String> get configJson => $composableBuilder(
      column: $table.configJson, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<DateTime> get startsAt =>
      $composableBuilder(column: $table.startsAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endsAt =>
      $composableBuilder(column: $table.endsAt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get stackable =>
      $composableBuilder(column: $table.stackable, builder: (column) => column);

  GeneratedColumn<String> get applicableProductIdsJson => $composableBuilder(
      column: $table.applicableProductIdsJson, builder: (column) => column);

  GeneratedColumn<String> get applicableCategoryIdsJson => $composableBuilder(
      column: $table.applicableCategoryIdsJson, builder: (column) => column);

  GeneratedColumn<String> get memberLevelIdsJson => $composableBuilder(
      column: $table.memberLevelIdsJson, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$PromotionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PromotionsTable,
    PromotionRow,
    $$PromotionsTableFilterComposer,
    $$PromotionsTableOrderingComposer,
    $$PromotionsTableAnnotationComposer,
    $$PromotionsTableCreateCompanionBuilder,
    $$PromotionsTableUpdateCompanionBuilder,
    (
      PromotionRow,
      BaseReferences<_$AppDatabase, $PromotionsTable, PromotionRow>
    ),
    PromotionRow,
    PrefetchHooks Function()> {
  $$PromotionsTableTableManager(_$AppDatabase db, $PromotionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PromotionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PromotionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PromotionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> strategy = const Value.absent(),
            Value<String> configJson = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<DateTime?> startsAt = const Value.absent(),
            Value<DateTime?> endsAt = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<bool> stackable = const Value.absent(),
            Value<String> applicableProductIdsJson = const Value.absent(),
            Value<String> applicableCategoryIdsJson = const Value.absent(),
            Value<String> memberLevelIdsJson = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PromotionsCompanion(
            id: id,
            name: name,
            strategy: strategy,
            configJson: configJson,
            priority: priority,
            startsAt: startsAt,
            endsAt: endsAt,
            isActive: isActive,
            stackable: stackable,
            applicableProductIdsJson: applicableProductIdsJson,
            applicableCategoryIdsJson: applicableCategoryIdsJson,
            memberLevelIdsJson: memberLevelIdsJson,
            description: description,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String strategy,
            required String configJson,
            Value<int> priority = const Value.absent(),
            Value<DateTime?> startsAt = const Value.absent(),
            Value<DateTime?> endsAt = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<bool> stackable = const Value.absent(),
            Value<String> applicableProductIdsJson = const Value.absent(),
            Value<String> applicableCategoryIdsJson = const Value.absent(),
            Value<String> memberLevelIdsJson = const Value.absent(),
            Value<String?> description = const Value.absent(),
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PromotionsCompanion.insert(
            id: id,
            name: name,
            strategy: strategy,
            configJson: configJson,
            priority: priority,
            startsAt: startsAt,
            endsAt: endsAt,
            isActive: isActive,
            stackable: stackable,
            applicableProductIdsJson: applicableProductIdsJson,
            applicableCategoryIdsJson: applicableCategoryIdsJson,
            memberLevelIdsJson: memberLevelIdsJson,
            description: description,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PromotionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PromotionsTable,
    PromotionRow,
    $$PromotionsTableFilterComposer,
    $$PromotionsTableOrderingComposer,
    $$PromotionsTableAnnotationComposer,
    $$PromotionsTableCreateCompanionBuilder,
    $$PromotionsTableUpdateCompanionBuilder,
    (
      PromotionRow,
      BaseReferences<_$AppDatabase, $PromotionsTable, PromotionRow>
    ),
    PromotionRow,
    PrefetchHooks Function()>;
typedef $$InvoicesTableCreateCompanionBuilder = InvoicesCompanion Function({
  required String id,
  required String orderId,
  Value<String> status,
  Value<String?> invoiceNumber,
  Value<DateTime?> invoiceDate,
  required int totalCents,
  required int taxCents,
  Value<int> taxType,
  Value<String?> carrierType,
  Value<String?> carrierCode,
  Value<String?> taxId,
  Value<String?> companyName,
  Value<String?> donationCode,
  Value<String?> gateway,
  Value<String?> gatewayRef,
  Value<String?> lastError,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$InvoicesTableUpdateCompanionBuilder = InvoicesCompanion Function({
  Value<String> id,
  Value<String> orderId,
  Value<String> status,
  Value<String?> invoiceNumber,
  Value<DateTime?> invoiceDate,
  Value<int> totalCents,
  Value<int> taxCents,
  Value<int> taxType,
  Value<String?> carrierType,
  Value<String?> carrierCode,
  Value<String?> taxId,
  Value<String?> companyName,
  Value<String?> donationCode,
  Value<String?> gateway,
  Value<String?> gatewayRef,
  Value<String?> lastError,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$InvoicesTableFilterComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orderId => $composableBuilder(
      column: $table.orderId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get invoiceDate => $composableBuilder(
      column: $table.invoiceDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalCents => $composableBuilder(
      column: $table.totalCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get taxCents => $composableBuilder(
      column: $table.taxCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get taxType => $composableBuilder(
      column: $table.taxType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get carrierType => $composableBuilder(
      column: $table.carrierType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get carrierCode => $composableBuilder(
      column: $table.carrierCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taxId => $composableBuilder(
      column: $table.taxId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companyName => $composableBuilder(
      column: $table.companyName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get donationCode => $composableBuilder(
      column: $table.donationCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gateway => $composableBuilder(
      column: $table.gateway, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gatewayRef => $composableBuilder(
      column: $table.gatewayRef, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$InvoicesTableOrderingComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orderId => $composableBuilder(
      column: $table.orderId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get invoiceDate => $composableBuilder(
      column: $table.invoiceDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalCents => $composableBuilder(
      column: $table.totalCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get taxCents => $composableBuilder(
      column: $table.taxCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get taxType => $composableBuilder(
      column: $table.taxType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get carrierType => $composableBuilder(
      column: $table.carrierType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get carrierCode => $composableBuilder(
      column: $table.carrierCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taxId => $composableBuilder(
      column: $table.taxId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companyName => $composableBuilder(
      column: $table.companyName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get donationCode => $composableBuilder(
      column: $table.donationCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gateway => $composableBuilder(
      column: $table.gateway, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gatewayRef => $composableBuilder(
      column: $table.gatewayRef, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$InvoicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber, builder: (column) => column);

  GeneratedColumn<DateTime> get invoiceDate => $composableBuilder(
      column: $table.invoiceDate, builder: (column) => column);

  GeneratedColumn<int> get totalCents => $composableBuilder(
      column: $table.totalCents, builder: (column) => column);

  GeneratedColumn<int> get taxCents =>
      $composableBuilder(column: $table.taxCents, builder: (column) => column);

  GeneratedColumn<int> get taxType =>
      $composableBuilder(column: $table.taxType, builder: (column) => column);

  GeneratedColumn<String> get carrierType => $composableBuilder(
      column: $table.carrierType, builder: (column) => column);

  GeneratedColumn<String> get carrierCode => $composableBuilder(
      column: $table.carrierCode, builder: (column) => column);

  GeneratedColumn<String> get taxId =>
      $composableBuilder(column: $table.taxId, builder: (column) => column);

  GeneratedColumn<String> get companyName => $composableBuilder(
      column: $table.companyName, builder: (column) => column);

  GeneratedColumn<String> get donationCode => $composableBuilder(
      column: $table.donationCode, builder: (column) => column);

  GeneratedColumn<String> get gateway =>
      $composableBuilder(column: $table.gateway, builder: (column) => column);

  GeneratedColumn<String> get gatewayRef => $composableBuilder(
      column: $table.gatewayRef, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$InvoicesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InvoicesTable,
    InvoiceRow,
    $$InvoicesTableFilterComposer,
    $$InvoicesTableOrderingComposer,
    $$InvoicesTableAnnotationComposer,
    $$InvoicesTableCreateCompanionBuilder,
    $$InvoicesTableUpdateCompanionBuilder,
    (InvoiceRow, BaseReferences<_$AppDatabase, $InvoicesTable, InvoiceRow>),
    InvoiceRow,
    PrefetchHooks Function()> {
  $$InvoicesTableTableManager(_$AppDatabase db, $InvoicesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> orderId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> invoiceNumber = const Value.absent(),
            Value<DateTime?> invoiceDate = const Value.absent(),
            Value<int> totalCents = const Value.absent(),
            Value<int> taxCents = const Value.absent(),
            Value<int> taxType = const Value.absent(),
            Value<String?> carrierType = const Value.absent(),
            Value<String?> carrierCode = const Value.absent(),
            Value<String?> taxId = const Value.absent(),
            Value<String?> companyName = const Value.absent(),
            Value<String?> donationCode = const Value.absent(),
            Value<String?> gateway = const Value.absent(),
            Value<String?> gatewayRef = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InvoicesCompanion(
            id: id,
            orderId: orderId,
            status: status,
            invoiceNumber: invoiceNumber,
            invoiceDate: invoiceDate,
            totalCents: totalCents,
            taxCents: taxCents,
            taxType: taxType,
            carrierType: carrierType,
            carrierCode: carrierCode,
            taxId: taxId,
            companyName: companyName,
            donationCode: donationCode,
            gateway: gateway,
            gatewayRef: gatewayRef,
            lastError: lastError,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String orderId,
            Value<String> status = const Value.absent(),
            Value<String?> invoiceNumber = const Value.absent(),
            Value<DateTime?> invoiceDate = const Value.absent(),
            required int totalCents,
            required int taxCents,
            Value<int> taxType = const Value.absent(),
            Value<String?> carrierType = const Value.absent(),
            Value<String?> carrierCode = const Value.absent(),
            Value<String?> taxId = const Value.absent(),
            Value<String?> companyName = const Value.absent(),
            Value<String?> donationCode = const Value.absent(),
            Value<String?> gateway = const Value.absent(),
            Value<String?> gatewayRef = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              InvoicesCompanion.insert(
            id: id,
            orderId: orderId,
            status: status,
            invoiceNumber: invoiceNumber,
            invoiceDate: invoiceDate,
            totalCents: totalCents,
            taxCents: taxCents,
            taxType: taxType,
            carrierType: carrierType,
            carrierCode: carrierCode,
            taxId: taxId,
            companyName: companyName,
            donationCode: donationCode,
            gateway: gateway,
            gatewayRef: gatewayRef,
            lastError: lastError,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$InvoicesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InvoicesTable,
    InvoiceRow,
    $$InvoicesTableFilterComposer,
    $$InvoicesTableOrderingComposer,
    $$InvoicesTableAnnotationComposer,
    $$InvoicesTableCreateCompanionBuilder,
    $$InvoicesTableUpdateCompanionBuilder,
    (InvoiceRow, BaseReferences<_$AppDatabase, $InvoicesTable, InvoiceRow>),
    InvoiceRow,
    PrefetchHooks Function()>;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  required String id,
  required String op,
  required String payloadJson,
  Value<int> retries,
  required DateTime nextRetryAt,
  required DateTime createdAt,
  Value<String?> lastError,
  Value<int> rowid,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<String> id,
  Value<String> op,
  Value<String> payloadJson,
  Value<int> retries,
  Value<DateTime> nextRetryAt,
  Value<DateTime> createdAt,
  Value<String?> lastError,
  Value<int> rowid,
});

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get op => $composableBuilder(
      column: $table.op, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retries => $composableBuilder(
      column: $table.retries, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get op => $composableBuilder(
      column: $table.op, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retries => $composableBuilder(
      column: $table.retries, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<int> get retries =>
      $composableBuilder(column: $table.retries, builder: (column) => column);

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueRow,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueRow,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueRow>
    ),
    SyncQueueRow,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> op = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<int> retries = const Value.absent(),
            Value<DateTime> nextRetryAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncQueueCompanion(
            id: id,
            op: op,
            payloadJson: payloadJson,
            retries: retries,
            nextRetryAt: nextRetryAt,
            createdAt: createdAt,
            lastError: lastError,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String op,
            required String payloadJson,
            Value<int> retries = const Value.absent(),
            required DateTime nextRetryAt,
            required DateTime createdAt,
            Value<String?> lastError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncQueueCompanion.insert(
            id: id,
            op: op,
            payloadJson: payloadJson,
            retries: retries,
            nextRetryAt: nextRetryAt,
            createdAt: createdAt,
            lastError: lastError,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueRow,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueRow,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueRow>
    ),
    SyncQueueRow,
    PrefetchHooks Function()>;
typedef $$HeldCartsTableCreateCompanionBuilder = HeldCartsCompanion Function({
  required String id,
  required String label,
  required String payload,
  Value<String?> pendingGuestOrderId,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$HeldCartsTableUpdateCompanionBuilder = HeldCartsCompanion Function({
  Value<String> id,
  Value<String> label,
  Value<String> payload,
  Value<String?> pendingGuestOrderId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$HeldCartsTableFilterComposer
    extends Composer<_$AppDatabase, $HeldCartsTable> {
  $$HeldCartsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pendingGuestOrderId => $composableBuilder(
      column: $table.pendingGuestOrderId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$HeldCartsTableOrderingComposer
    extends Composer<_$AppDatabase, $HeldCartsTable> {
  $$HeldCartsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pendingGuestOrderId => $composableBuilder(
      column: $table.pendingGuestOrderId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$HeldCartsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HeldCartsTable> {
  $$HeldCartsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get pendingGuestOrderId => $composableBuilder(
      column: $table.pendingGuestOrderId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$HeldCartsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HeldCartsTable,
    HeldCartRow,
    $$HeldCartsTableFilterComposer,
    $$HeldCartsTableOrderingComposer,
    $$HeldCartsTableAnnotationComposer,
    $$HeldCartsTableCreateCompanionBuilder,
    $$HeldCartsTableUpdateCompanionBuilder,
    (HeldCartRow, BaseReferences<_$AppDatabase, $HeldCartsTable, HeldCartRow>),
    HeldCartRow,
    PrefetchHooks Function()> {
  $$HeldCartsTableTableManager(_$AppDatabase db, $HeldCartsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HeldCartsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HeldCartsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HeldCartsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<String?> pendingGuestOrderId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HeldCartsCompanion(
            id: id,
            label: label,
            payload: payload,
            pendingGuestOrderId: pendingGuestOrderId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String label,
            required String payload,
            Value<String?> pendingGuestOrderId = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              HeldCartsCompanion.insert(
            id: id,
            label: label,
            payload: payload,
            pendingGuestOrderId: pendingGuestOrderId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HeldCartsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HeldCartsTable,
    HeldCartRow,
    $$HeldCartsTableFilterComposer,
    $$HeldCartsTableOrderingComposer,
    $$HeldCartsTableAnnotationComposer,
    $$HeldCartsTableCreateCompanionBuilder,
    $$HeldCartsTableUpdateCompanionBuilder,
    (HeldCartRow, BaseReferences<_$AppDatabase, $HeldCartsTable, HeldCartRow>),
    HeldCartRow,
    PrefetchHooks Function()>;
typedef $$KvMetaTableCreateCompanionBuilder = KvMetaCompanion Function({
  required String key,
  Value<String?> value,
  Value<int> rowid,
});
typedef $$KvMetaTableUpdateCompanionBuilder = KvMetaCompanion Function({
  Value<String> key,
  Value<String?> value,
  Value<int> rowid,
});

class $$KvMetaTableFilterComposer
    extends Composer<_$AppDatabase, $KvMetaTable> {
  $$KvMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$KvMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $KvMetaTable> {
  $$KvMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$KvMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $KvMetaTable> {
  $$KvMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KvMetaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $KvMetaTable,
    KvMetaRow,
    $$KvMetaTableFilterComposer,
    $$KvMetaTableOrderingComposer,
    $$KvMetaTableAnnotationComposer,
    $$KvMetaTableCreateCompanionBuilder,
    $$KvMetaTableUpdateCompanionBuilder,
    (KvMetaRow, BaseReferences<_$AppDatabase, $KvMetaTable, KvMetaRow>),
    KvMetaRow,
    PrefetchHooks Function()> {
  $$KvMetaTableTableManager(_$AppDatabase db, $KvMetaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KvMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KvMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KvMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              KvMetaCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            Value<String?> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              KvMetaCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$KvMetaTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $KvMetaTable,
    KvMetaRow,
    $$KvMetaTableFilterComposer,
    $$KvMetaTableOrderingComposer,
    $$KvMetaTableAnnotationComposer,
    $$KvMetaTableCreateCompanionBuilder,
    $$KvMetaTableUpdateCompanionBuilder,
    (KvMetaRow, BaseReferences<_$AppDatabase, $KvMetaTable, KvMetaRow>),
    KvMetaRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$StoresTableTableManager get stores =>
      $$StoresTableTableManager(_db, _db.stores);
  $$TerminalsTableTableManager get terminals =>
      $$TerminalsTableTableManager(_db, _db.terminals);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$BookDetailsTableTableManager get bookDetails =>
      $$BookDetailsTableTableManager(_db, _db.bookDetails);
  $$ProductBarcodesTableTableManager get productBarcodes =>
      $$ProductBarcodesTableTableManager(_db, _db.productBarcodes);
  $$OptionGroupsTableTableManager get optionGroups =>
      $$OptionGroupsTableTableManager(_db, _db.optionGroups);
  $$OptionChoicesTableTableManager get optionChoices =>
      $$OptionChoicesTableTableManager(_db, _db.optionChoices);
  $$ProductOptionGroupsTableTableManager get productOptionGroups =>
      $$ProductOptionGroupsTableTableManager(_db, _db.productOptionGroups);
  $$ProductOptionChoiceOverridesTableTableManager
      get productOptionChoiceOverrides =>
          $$ProductOptionChoiceOverridesTableTableManager(
              _db, _db.productOptionChoiceOverrides);
  $$MemberLevelsTableTableManager get memberLevels =>
      $$MemberLevelsTableTableManager(_db, _db.memberLevels);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db, _db.members);
  $$CouponsTableTableManager get coupons =>
      $$CouponsTableTableManager(_db, _db.coupons);
  $$PointTransactionsTableTableManager get pointTransactions =>
      $$PointTransactionsTableTableManager(_db, _db.pointTransactions);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db, _db.orders);
  $$OrderLinesTableTableManager get orderLines =>
      $$OrderLinesTableTableManager(_db, _db.orderLines);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db, _db.payments);
  $$RefundsTableTableManager get refunds =>
      $$RefundsTableTableManager(_db, _db.refunds);
  $$RefundLinesTableTableManager get refundLines =>
      $$RefundLinesTableTableManager(_db, _db.refundLines);
  $$InventoryLevelsTableTableManager get inventoryLevels =>
      $$InventoryLevelsTableTableManager(_db, _db.inventoryLevels);
  $$InventoryMovementsTableTableManager get inventoryMovements =>
      $$InventoryMovementsTableTableManager(_db, _db.inventoryMovements);
  $$TransferOrdersTableTableManager get transferOrders =>
      $$TransferOrdersTableTableManager(_db, _db.transferOrders);
  $$TransferLinesTableTableManager get transferLines =>
      $$TransferLinesTableTableManager(_db, _db.transferLines);
  $$StocktakesTableTableManager get stocktakes =>
      $$StocktakesTableTableManager(_db, _db.stocktakes);
  $$StocktakeLinesTableTableManager get stocktakeLines =>
      $$StocktakeLinesTableTableManager(_db, _db.stocktakeLines);
  $$PromotionsTableTableManager get promotions =>
      $$PromotionsTableTableManager(_db, _db.promotions);
  $$InvoicesTableTableManager get invoices =>
      $$InvoicesTableTableManager(_db, _db.invoices);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$HeldCartsTableTableManager get heldCarts =>
      $$HeldCartsTableTableManager(_db, _db.heldCarts);
  $$KvMetaTableTableManager get kvMeta =>
      $$KvMetaTableTableManager(_db, _db.kvMeta);
}
