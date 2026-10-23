import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';

// hold sesi global. Tukar email di bawah untuk menguji jabatan berbeza!
String currentLoggedInUserEmail = "syaza@gmail.com";
List<dynamic> senaraiVendorGlobalJabatanSyafiqah = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init(); //  AKTIFKAN LOCENG PHONE!
  runApp(const RushApp());
}

/// RUSH (RCMP User Helpdesk) — UniKL RCMP
///
/// Routes are declared in `router/app_router.dart` (go_router):
///  '/'                    -> HelpdeskHomeScreen               (department picker)
///  '/vendor'              -> VendorPortalScreen                (vendor sign in)
///  '/login'               -> UserLoginScreen                   (staff/student Microsoft SSO)
///  '/operator'            -> OperatorPortalScreen               (operator sign in)
///  '/dashboard'           -> DashboardScreen                    (quick actions + recent activity)
///  '/complaint/fill'      -> ComplaintFillDetailsScreen         (step 1)
///  '/complaint/preview'   -> ComplaintPreviewReviewScreen       (step 2)
///  '/complaint/confirm'   -> ComplaintConfirmSubmissionsScreen  (step 3)
///  '/complaint/submitted' -> ComplaintSubmittedScreen           (success)
///  '/my-submissions'      -> MySubmissionsScreen
///  '/tickets/user-detail' -> TicketDetailUserScreen              (user-facing)
///  '/admin/dashboard'     -> AdminDashboardScreen                (IT Dept admin)
///  '/admin/tickets'       -> AdminAllTicketsScreen
///  '/admin/users'         -> AdminManageUsersScreen
///  '/admin/vendors'       -> AdminManageVendorsScreen
///  '/admin/categories'    -> AdminCategoriesScreen
///  '/admin/reports'       -> AdminReportsScreen
///  '/staff/dashboard'     -> StaffDashboardScreen
///  '/staff/tickets'       -> StaffAllTicketsScreen
///  '/tickets/workspace'   -> TicketWorkspaceScreen               (shared admin/staff)
///  '/hod/dashboard'       -> HodDashboardScreen
///  '/hod/reports'         -> HodReportsScreen
class RushApp extends StatelessWidget {
  const RushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RUSH — UniKL RCMP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.pageBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          primary: AppColors.navy,
          secondary: AppColors.gold,
        ),
        fontFamily: 'Roboto',
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.navyDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 10,
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
