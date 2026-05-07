import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../features/auth/pages/login_page.dart';
import '../features/cashier/pages/cashier_page.dart';
import '../features/cashier/pages/checkout_page.dart';
import '../features/cashier/pages/scan_page.dart';
import '../features/history/pages/history_page.dart';
import '../features/inventory/pages/inventory_page.dart';
import '../features/members/pages/member_select_page.dart';
import '../features/members/pages/members_page.dart';
import '../features/products/pages/products_page.dart';
import '../features/promotions/pages/promotions_page.dart';
import '../features/refund/pages/refund_page.dart';
import '../features/settings/pages/settings_page.dart';
import '../features/sync/pages/sync_status_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = ref.read(authStateProvider).isLoggedIn;
      final goingToLogin = state.matchedLocation == '/login';
      if (!loggedIn && !goingToLogin) return '/login';
      if (loggedIn && goingToLogin) return '/';
      return null;
    },
    refreshListenable: _AuthListenable(ref),
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/', builder: (_, __) => const CashierPage()),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutPage()),
      GoRoute(path: '/scan', builder: (_, __) => const ScanPage()),
      GoRoute(path: '/products', builder: (_, __) => const ProductsPage()),
      GoRoute(path: '/members', builder: (_, __) => const MembersPage()),
      GoRoute(path: '/members/select', builder: (_, __) => const MemberSelectPage()),
      GoRoute(path: '/inventory', builder: (_, __) => const InventoryPage()),
      GoRoute(path: '/promotions', builder: (_, __) => const PromotionsPage()),
      GoRoute(path: '/history', builder: (_, __) => const HistoryPage()),
      GoRoute(
          path: '/refund/:id',
          builder: (_, state) => RefundPage(orderId: state.pathParameters['id']!)),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
      GoRoute(path: '/sync', builder: (_, __) => const SyncStatusPage()),
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _sub = _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
  late final ProviderSubscription _sub;
  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
