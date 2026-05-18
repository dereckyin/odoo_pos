import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import 'book_sale_demo.dart';

/// Latest books from TAAZE API (or offline fallback) for demo UI and scans.
final bookSaleDemoBooksProvider = FutureProvider<List<DemoBook>>((ref) async {
  if (!BookSaleDemo.enabled) return const [];
  final books = await BookSaleDemo.loadBooks();
  final db = ref.read(databaseProvider);
  await BookSaleDemo.ensureLocalCatalog(db, books: books);
  return books;
});
