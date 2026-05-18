import 'package:dio/dio.dart';

/// TAAZE public book feed for the book-sale demo.
class TaazeBookApi {
  TaazeBookApi({Dio? dio, this.baseUrl = 'https://api.taaze.tw/api/v1/book/latest'})
      : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Future<List<TaazeBookDto>> fetchLatest({int? limit}) async {
    final res = await _dio.get<List<dynamic>>(
      baseUrl,
      options: Options(responseType: ResponseType.json),
    );
    final raw = res.data;
    if (raw == null) return const [];
    final items = raw
        .whereType<Map>()
        .map((e) => TaazeBookDto.fromJson(Map<String, dynamic>.from(e)))
        .where((b) => b.id.isNotEmpty && b.title.isNotEmpty)
        .toList(growable: false);
    if (limit != null && items.length > limit) {
      return items.sublist(0, limit);
    }
    return items;
  }
}

class TaazeBookDto {
  const TaazeBookDto({
    required this.id,
    required this.title,
    required this.author,
    required this.price,
    this.imageUrl,
    this.isbn,
  });

  factory TaazeBookDto.fromJson(Map<String, dynamic> json) => TaazeBookDto(
        id: '${json['id'] ?? ''}',
        title: '${json['title'] ?? ''}'.trim(),
        author: '${json['author'] ?? ''}'.trim(),
        price: (json['price'] as num?)?.toDouble() ?? 0,
        imageUrl: json['imageUrl'] as String?,
        isbn: json['isbn'] as String?,
      );

  final String id;
  final String title;
  final String author;
  final double price;
  final String? imageUrl;
  final String? isbn;
}
