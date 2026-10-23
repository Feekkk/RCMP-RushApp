import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/helpdesk_home_screen.dart';
import '../screens/vendor_portal_screen.dart';
import '../screens/user_login_screen.dart';
import '../screens/operator_portal_screen.dart';
import '../screens/complaint/dashboard_screen.dart';
import '../screens/complaint/complaint_fill_details_screen.dart';
import '../screens/complaint/complaint_preview_review_screen.dart';
import '../screens/complaint/complaint_confirm_submissions_screen.dart';
import '../screens/complaint/complaint_submitted_screen.dart';
import '../screens/complaint/my_submissions_screen.dart';
import '../screens/complaint/ticket_detail_user_screen.dart';
import '../screens/dept_admin/admin_dashboard_screen.dart';
import '../screens/dept_admin/admin_all_tickets_screen.dart';
import '../screens/dept_admin/admin_manage_users_screen.dart';
import '../screens/dept_admin/admin_categories_screen.dart';
import '../screens/dept_admin/admin_reports_screen.dart';
import '../screens/hod/hod_dashboard_screen.dart';
import '../screens/hod/hod_reports_screen.dart';
import '../screens/dept/staff_dashboard_screen.dart';
import '../screens/dept/staff_all_tickets_screen.dart';
import '../screens/dept/ticket_workspace_screen.dart';
import '../screens/vendor/vendor_dashboard_screen.dart';
import '../screens/vendor/vendor_ticket_workspace_screen.dart';

/// Navigator key used app-wide (also referenced by Microsoft SSO / aad_oauth).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Wraps [child] in a [MaterialPage] that still carries `extra` as the
/// page's `arguments`, so existing screens reading
/// `ModalRoute.of(context)?.settings.arguments` keep working unchanged.
Page<void> _page(GoRouterState state, Widget child) {
  return MaterialPage<void>(
    key: state.pageKey,
    name: state.name,
    arguments: state.extra,
    child: child,
  );
}

final GoRouter appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _page(state, const HelpdeskHomeScreen()),
    ),
    GoRoute(
      path: '/vendor',
      pageBuilder: (context, state) => _page(state, const VendorPortalScreen()),
    ),
    GoRoute(
      path: '/operator',
      pageBuilder: (context, state) => _page(state, const OperatorPortalScreen()),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) =>
          _page(state, UserLoginScreen(department: state.extra as String?)),
    ),
    GoRoute(
      path: '/dashboard',
      pageBuilder: (context, state) => _page(state, const DashboardScreen()),
    ),
    GoRoute(
      path: '/complaint/fill',
      pageBuilder: (context, state) =>
          _page(state, const ComplaintFillDetailsScreen()),
    ),
    GoRoute(
      path: '/complaint/preview',
      pageBuilder: (context, state) =>
          _page(state, const ComplaintPreviewReviewScreen()),
    ),
    GoRoute(
      path: '/complaint/confirm',
      pageBuilder: (context, state) =>
          _page(state, const ComplaintConfirmSubmissionsScreen()),
    ),
    GoRoute(
      path: '/complaint/submitted',
      pageBuilder: (context, state) =>
          _page(state, const ComplaintSubmittedScreen()),
    ),
    GoRoute(
      path: '/my-submissions',
      pageBuilder: (context, state) => _page(state, const MySubmissionsScreen()),
    ),
    GoRoute(
      path: '/tickets/user-detail',
      pageBuilder: (context, state) =>
          _page(state, const TicketDetailUserScreen()),
    ),
    GoRoute(
      path: '/admin/dashboard',
      pageBuilder: (context, state) => _page(state, const AdminDashboardScreen()),
    ),
    GoRoute(
      path: '/admin/tickets',
      pageBuilder: (context, state) =>
          _page(state, const AdminAllTicketsScreen()),
    ),
    GoRoute(
      path: '/admin/users',
      pageBuilder: (context, state) =>
          _page(state, const AdminManageUsersScreen()),
    ),
    GoRoute(
      path: '/admin/vendors',
      pageBuilder: (context, state) =>
          _page(state, const AdminManageUsersScreen()),
    ),
    GoRoute(
      path: '/admin/categories',
      pageBuilder: (context, state) => _page(state, const AdminCategoriesScreen()),
    ),
    GoRoute(
      path: '/admin/reports',
      pageBuilder: (context, state) => _page(state, const AdminReportsScreen()),
    ),
    GoRoute(
      path: '/vendor/dashboard',
      pageBuilder: (context, state) => _page(state, VendorDashboardScreen()),
    ),
    GoRoute(
      path: '/vendor_ticket_workspace',
      pageBuilder: (context, state) =>
          _page(state, const VendorTicketWorkspaceScreen()),
    ),
    GoRoute(
      path: '/hod/dashboard',
      pageBuilder: (context, state) => _page(state, const HodDashboardScreen()),
    ),
    GoRoute(
      path: '/hod/reports',
      pageBuilder: (context, state) => _page(state, const HodReportsScreen()),
    ),
    GoRoute(
      path: '/staff/dashboard',
      pageBuilder: (context, state) => _page(state, const StaffDashboardScreen()),
    ),
    GoRoute(
      path: '/staff/tickets',
      pageBuilder: (context, state) =>
          _page(state, const StaffAllTicketsScreen()),
    ),
    GoRoute(
      path: '/tickets/workspace',
      pageBuilder: (context, state) => _page(state, const TicketWorkspaceScreen()),
    ),
  ],
  // Any unknown/legacy path (e.g. a stray '/helpdesk_home_screen') falls
  // back to the home screen, matching the old onGenerateRoute's default case.
  errorPageBuilder: (context, state) =>
      _page(state, const HelpdeskHomeScreen()),
);
