import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:koi_dessert_bar/features/admin/views/admin_dashboard_view.dart';
import 'package:koi_dessert_bar/features/admin/views/admin_order_management_view.dart';
import 'package:koi_dessert_bar/features/admin/views/admin_product_form_view.dart';
import 'package:koi_dessert_bar/features/admin/views/admin_product_list_view.dart';
import 'package:koi_dessert_bar/features/auth/views/login_view.dart';
import 'package:koi_dessert_bar/features/auth/views/register_view.dart';
import 'package:koi_dessert_bar/features/customer/views/cart_view.dart';
import 'package:koi_dessert_bar/features/customer/views/checkout_view.dart';
import 'package:koi_dessert_bar/features/customer/views/home_view.dart';
import 'package:koi_dessert_bar/features/customer/views/main_wrapper.dart';
import 'package:koi_dessert_bar/features/customer/views/order_history_view.dart';
import 'package:koi_dessert_bar/features/customer/views/order_detail_view.dart';
import 'package:koi_dessert_bar/features/customer/views/order_success_view.dart';
import 'package:koi_dessert_bar/features/customer/views/product_detail_view.dart';
import 'package:koi_dessert_bar/features/customer/views/profile_view.dart';
import 'package:koi_dessert_bar/features/product/models/product_model.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';
  static const String productDetail = '/product/:id';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderSuccess = '/order-success';
  static const String orderHistory = '/history';
  static const String orderDetail = '/history/:id';
  static const String profile = '/profile';
  static const String adminDashboard = '/admin';
  static const String adminProducts = '/admin/products';
  static const String adminProductForm = '/admin/products/form';
  static const String adminOrders = '/admin/orders';
}

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      if (!isLoggedIn && !isAuthRoute) {
        return AppRoutes.login;
      }
      if (isLoggedIn && isAuthRoute) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (_, __) => const LoginView(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (_, __) => const RegisterView(),
      ),
      ShellRoute(
        builder: (_, __, child) => MainWrapper(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (_, __) => const HomeView(),
          ),
          GoRoute(
            path: AppRoutes.orderHistory,
            name: 'history',
            builder: (_, __) => const OrderHistoryView(),
          ),
          GoRoute(
            path: 'history/:id',
            name: 'orderDetail',
            builder: (_, state) =>
                OrderDetailView(order: state.extra! as dynamic),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (_, __) => const ProfileView(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        name: 'productDetail',
        builder: (_, state) =>
            ProductDetailView(product: state.extra! as ProductModel),
      ),
      GoRoute(
        path: AppRoutes.cart,
        name: 'cart',
        builder: (_, __) => const CartView(),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        name: 'checkout',
        builder: (_, __) => const CheckoutView(),
      ),
      GoRoute(
        path: AppRoutes.orderSuccess,
        name: 'orderSuccess',
        builder: (_, state) =>
            OrderSuccessView(orderId: state.extra! as String),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        name: 'adminDashboard',
        builder: (_, __) => const AdminDashboardView(),
        routes: [
          GoRoute(
            path: 'products',
            name: 'adminProducts',
            builder: (_, __) => const AdminProductListView(),
          ),
          GoRoute(
            path: 'products/form',
            name: 'adminProductForm',
            builder: (_, state) =>
                AdminProductFormView(product: state.extra as ProductModel?),
          ),
          GoRoute(
            path: 'orders',
            name: 'adminOrders',
            builder: (_, __) => const AdminOrderManagementView(),
          ),
        ],
      ),
    ],
  );
}
