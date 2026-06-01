import 'package:go_router/go_router.dart';

import '../../core/constants/route_constants.dart';
import 'admin/admin_complaints_list_page.dart';
import 'admin/admin_dashboard_page.dart';
import 'settings/settings_page.dart';
import 'sr/sr_dashboard_page.dart';
import 'sr/sr_review_detail_page.dart';
import 'staff/staff_complaint_detail_page.dart';
import 'staff/staff_dashboard_page.dart';

// REQUEST TO PAVAN: add route constant for /admin/complaints if desired.
final List<GoRoute> prabhavaRoutes = [
  GoRoute(
    path: Routes.staffHome,
    builder: (context, state) => const StaffDashboardPage(),
  ),
  GoRoute(
    path: Routes.staffComplaintDetail,
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return StaffComplaintDetailPage(complaintId: id);
    },
  ),
  GoRoute(
    path: Routes.srHome,
    builder: (context, state) => const SrDashboardPage(),
  ),
  GoRoute(
    path: Routes.srReviewDetail,
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return SrReviewDetailPage(complaintId: id);
    },
  ),
  GoRoute(
    path: Routes.adminHome,
    builder: (context, state) => const AdminDashboardPage(),
  ),
  GoRoute(
    path: '/admin/complaints',
    builder: (context, state) => const AdminComplaintsListPage(),
  ),
  GoRoute(
    path: Routes.settings,
    builder: (context, state) => const SettingsPage(),
  ),
];
