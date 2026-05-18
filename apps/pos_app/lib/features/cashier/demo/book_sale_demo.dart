import 'package:drift/drift.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import '../../../config/env.dart';
import '../../../data/database/app_database.dart';
import 'taaze_book_api.dart';

/// Temporary demo catalog for book retail (scan → cart → checkout).
/// Remove this file and all `BookSaleDemo` references when real book data is live.
class BookSaleDemo {
  BookSaleDemo._();

  static bool get enabled => Env.bookSaleDemo;

  static const categoryId = 'demo-cat-books';
  static const categoryName = '書籍／桌遊';

  static final TaazeBookApi _api = TaazeBookApi(baseUrl: Env.bookSaleDemoApiUrl);

  static List<DemoBook> _cache = const [];
  static Future<List<DemoBook>>? _loadFuture;

  /// In-memory catalog after [loadBooks]; used by barcode scan on cashier page.
  static List<DemoBook> get books => _cache;

  static Future<List<DemoBook>> loadBooks({int limit = 30}) {
    return _loadFuture ??= _fetch(limit);
  }

  static Future<List<DemoBook>> _fetch(int limit) async {
    try {
      final dtos = await _api.fetchLatest(limit: limit);
      _cache = dtos.map(_fromDto).toList(growable: false);
    } catch (_) {
      _cache = _fallbackBooks;
    }
    return _cache;
  }

  static DemoBook _fromDto(TaazeBookDto dto) {
    final priceMajor = dto.price > 0 ? dto.price.round() : 1;
    return DemoBook(
      id: 'demo-book-${dto.id}',
      sku: dto.id,
      barcode: _barcodeFor(dto),
      title: dto.title,
      author: dto.author.isEmpty ? '—' : dto.author,
      price: Money.fromMajor(priceMajor),
      imageUrl: dto.imageUrl,
    );
  }

  static String _barcodeFor(TaazeBookDto dto) {
    final isbn = dto.isbn?.trim();
    if (isbn != null && isbn.isNotEmpty) return isbn;
    return dto.id;
  }

  static DemoBook? findByBarcode(String raw) {
    final code = raw.trim();
    if (code.isEmpty || _cache.isEmpty) return null;
    for (final b in _cache) {
      if (b.barcode == code || b.sku == code || b.id == code) return b;
    }
    return null;
  }

  static Product toProduct(DemoBook book) => Product(
        id: book.id,
        sku: book.sku,
        name: book.title,
        price: book.price,
        barcodes: [book.barcode],
        categoryId: categoryId,
        imageUrl: book.imageUrl,
        taxRate: 0.05,
        unit: '本',
        isActive: true,
        updatedAt: DateTime.now(),
        hideFromPublicOrdering: true,
        hideFromPosBrowse: true,
      );

  /// Upsert demo category + books into local SQLite so checkout FKs succeed.
  static Future<void> ensureLocalCatalog(AppDatabase db, {List<DemoBook>? books}) async {
    if (!enabled) return;
    final catalog = books ?? _cache;
    if (catalog.isEmpty) return;
    final now = DateTime.now();
    await db.batch((b) {
      b.insert(
        db.categories,
        CategoriesCompanion(
          id: const Value(categoryId),
          name: const Value(categoryName),
          sortOrder: const Value(900),
          hideFromPublicOrdering: const Value(true),
          hideFromPosBrowse: const Value(false),
          updatedAt: Value(now),
        ),
        mode: InsertMode.insertOrReplace,
      );
      for (final book in catalog) {
        b.insert(
          db.products,
          ProductsCompanion(
            id: Value(book.id),
            sku: Value(book.sku),
            name: Value(book.title),
            priceCents: Value(book.price.cents),
            categoryId: const Value(categoryId),
            imageUrl: Value(book.imageUrl),
            taxRate: const Value(0.05),
            unit: const Value('本'),
            isActive: const Value(true),
            hideFromPublicOrdering: const Value(true),
            hideFromPosBrowse: const Value(true),
            updatedAt: Value(now),
          ),
          mode: InsertMode.insertOrReplace,
        );
        b.insert(
          db.productBarcodes,
          ProductBarcodesCompanion(productId: Value(book.id), barcode: Value(book.barcode)),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  static final List<DemoBook> _fallbackBooks = [
    DemoBook(
      id: 'demo-book-fallback-001',
      sku: '11101089044',
      barcode: '11101089044',
      title: '開放年代：被誤解的民國',
      author: '馮客',
      price: Money.fromMajor(355),
      imageUrl:
          'https://media.taaze.tw/showLargeImage.html?sc=11101089044&height=200&width=150&fill=f',
    ),
  ];
}

class DemoBook {
  const DemoBook({
    required this.id,
    required this.sku,
    required this.barcode,
    required this.title,
    required this.author,
    required this.price,
    this.imageUrl,
  });

  final String id;
  final String sku;
  /// Barcode for scanner / productBarcodes (TAAZE id when ISBN absent).
  final String barcode;
  final String title;
  final String author;
  final Money price;
  final String? imageUrl;

  String get displaySubtitle => '$author · 條碼 $barcode';
}
