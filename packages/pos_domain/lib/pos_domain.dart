/// Pure Dart domain entities, value objects and repository interfaces.
///
/// This package is the heart of the system: anything that depends on this
/// MUST not transitively depend on Flutter, drift, dio, etc. That keeps
/// the domain layer testable and reusable in CLI tools / server code.
library pos_domain;

// Entities
export 'src/entities/product.dart';
export 'src/entities/option.dart';
export 'src/entities/category.dart';
export 'src/entities/category_tree.dart';
export 'src/entities/cart.dart';
export 'src/entities/order.dart';
export 'src/entities/payment.dart';
export 'src/entities/member.dart';
export 'src/entities/coupon.dart';
export 'src/entities/promotion.dart';
export 'src/entities/inventory.dart';
export 'src/entities/store.dart';
export 'src/entities/refund.dart';
export 'src/entities/invoice.dart';

// Repositories
export 'src/repositories/product_repository.dart';
export 'src/repositories/category_repository.dart';
export 'src/repositories/cart_repository.dart';
export 'src/repositories/order_repository.dart';
export 'src/repositories/member_repository.dart';
export 'src/repositories/inventory_repository.dart';
export 'src/repositories/promotion_repository.dart';
export 'src/repositories/auth_repository.dart';
export 'src/repositories/sync_repository.dart';

// Services (gateway interfaces)
export 'src/services/payment_gateway.dart';
export 'src/services/invoice_gateway.dart';
export 'src/services/printer_service.dart';
export 'src/services/barcode_scanner.dart';

// Engine
export 'src/promotion/promotion_engine.dart';
export 'src/promotion/promotion_rule.dart';
