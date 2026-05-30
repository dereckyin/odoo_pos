import 'package:pos_core/pos_core.dart';

import 'option.dart';

class Product {
  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.price,
    this.barcodes = const [],
    this.categoryId,
    this.imageUrl,
    this.taxRate = 0.05,
    this.isWeighted = false,
    this.unit = '個',
    this.cost,
    this.isActive = true,
    this.updatedAt,
    this.hideFromPublicOrdering = false,
    this.hideFromPosBrowse = false,
    this.optionConfigs = const [],
  });

  final String id;
  final String sku;
  final String name;
  final Money price;
  final List<String> barcodes;
  final String? categoryId;
  final String? imageUrl;

  /// 0.05 = 5% (台灣營業稅)
  final double taxRate;

  /// 計重商品（單位為公斤等），數量可為小數。
  final bool isWeighted;
  final String unit;
  final Money? cost;
  final bool isActive;
  final DateTime? updatedAt;
  final bool hideFromPublicOrdering;
  final bool hideFromPosBrowse;
  final List<ProductOptionConfig> optionConfigs;

  bool get hasOptions => optionConfigs.isNotEmpty;

  Product copyWith({
    String? id,
    String? sku,
    String? name,
    Money? price,
    List<String>? barcodes,
    String? categoryId,
    String? imageUrl,
    double? taxRate,
    bool? isWeighted,
    String? unit,
    Money? cost,
    bool? isActive,
    DateTime? updatedAt,
    bool? hideFromPublicOrdering,
    bool? hideFromPosBrowse,
    List<ProductOptionConfig>? optionConfigs,
  }) =>
      Product(
        id: id ?? this.id,
        sku: sku ?? this.sku,
        name: name ?? this.name,
        price: price ?? this.price,
        barcodes: barcodes ?? this.barcodes,
        categoryId: categoryId ?? this.categoryId,
        imageUrl: imageUrl ?? this.imageUrl,
        taxRate: taxRate ?? this.taxRate,
        isWeighted: isWeighted ?? this.isWeighted,
        unit: unit ?? this.unit,
        cost: cost ?? this.cost,
        isActive: isActive ?? this.isActive,
        updatedAt: updatedAt ?? this.updatedAt,
        hideFromPublicOrdering: hideFromPublicOrdering ?? this.hideFromPublicOrdering,
        hideFromPosBrowse: hideFromPosBrowse ?? this.hideFromPosBrowse,
        optionConfigs: optionConfigs ?? this.optionConfigs,
      );
}
