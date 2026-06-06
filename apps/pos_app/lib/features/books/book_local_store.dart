import 'package:drift/drift.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import '../../data/api/dto.dart';
import '../../data/database/app_database.dart';

class BookLocalStore {
  BookLocalStore(this._db);
  final AppDatabase _db;

  Future<void> upsertFromDto(BookProductDto dto) async {
    final now = DateTime.now();
    await _db.batch((b) {
      b.insert(
        _db.products,
        ProductsCompanion(
          id: Value(dto.id),
          sku: Value(dto.sku),
          name: Value(dto.name),
          priceCents: Value(dto.priceCents),
          unit: Value(dto.unit),
          taxRate: const Value(0.05),
          isActive: const Value(true),
          hideFromPublicOrdering: const Value(true),
          hideFromPosBrowse: const Value(true),
          productKind: Value(dto.productKind),
          updatedAt: Value(now),
        ),
        mode: InsertMode.insertOrReplace,
      );
      for (final code in dto.barcodes) {
        b.insert(
          _db.productBarcodes,
          ProductBarcodesCompanion(productId: Value(dto.id), barcode: Value(code)),
          mode: InsertMode.insertOrReplace,
        );
      }
      b.insert(
        _db.bookDetails,
        BookDetailsCompanion(
          productId: Value(dto.id),
          barcode: Value(dto.barcodes.isNotEmpty ? dto.barcodes.first : dto.sku),
          author: Value(dto.author),
          updatedAt: Value(now),
        ),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Product toProduct(BookProductDto dto) => Product(
        id: dto.id,
        sku: dto.sku,
        name: dto.name,
        price: Money(dto.priceCents),
        barcodes: dto.barcodes,
        unit: dto.unit,
        taxRate: 0.05,
        isActive: true,
        hideFromPublicOrdering: true,
        hideFromPosBrowse: true,
        productKind: dto.productKind,
        bookAuthor: dto.author,
        updatedAt: DateTime.now(),
      );
}
