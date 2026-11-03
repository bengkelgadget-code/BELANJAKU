import 'package:go_router/go_router.dart';

import '../../features/budgets/screens/budget_screen.dart';
import '../../features/home/screens/main_navigation_wrapper.dart';
import '../../features/reports/screens/report_screen.dart';
import '../../features/scan/screens/scan_camera_screen.dart';
import '../../features/scan/screens/scan_review_screen.dart';
import '../../features/scan/services/receipt_parser.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/transactions/models/transaction.dart';
import '../../features/transactions/screens/add_transaction_screen.dart';
import '../../features/transactions/screens/transaction_list_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainNavigationWrapper(),
      ),
      GoRoute(
        path: '/add-transaction',
        builder: (context, state) {
          final item = state.extra as TransactionItem?;
          return AddTransactionScreen(existingItem: item);
        },
      ),
      GoRoute(
        path: '/transactions',
        builder: (context, state) => const TransactionListScreen(),
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) => const ScanCameraScreen(),
      ),
      GoRoute(
        path: '/scan-review',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final parsed = extra['parsedResult'] as ParsedReceiptResult;
          final imagePath = extra['imagePath'] as String;
          return ScanReviewScreen(parsedResult: parsed, imagePath: imagePath);
        },
      ),
      GoRoute(
        path: '/budgets',
        builder: (context, state) => const BudgetScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
