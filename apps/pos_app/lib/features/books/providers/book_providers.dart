import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_domain/pos_domain.dart';

import '../../../core/providers.dart';
import '../../products/providers/product_providers.dart';
import '../book_local_store.dart';

final bookLocalStoreProvider = Provider<BookLocalStore>((ref) {
  return BookLocalStore(ref.watch(databaseProvider));
});

final bookSearchProvider =
    FutureProvider.family<List<Product>, String>((ref, query) async {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return const [];
  final repo = ref.watch(productRepositoryProvider);
  return repo.searchConsignmentBooks(trimmed);
});
