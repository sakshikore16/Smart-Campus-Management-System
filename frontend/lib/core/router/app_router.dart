import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/admin_login_screen.dart';
import '../../features/student/student_dashboard.dart';
import '../../features/faculty/faculty_dashboard.dart';
import '../../features/admin/admin_dashboard.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/attendance/attendance_screen.dart';
import '../../features/leaves/leaves_screen.dart';
import '../../features/notices/notices_screen.dart';
import '../../features/files/fee_receipts_screen.dart';
import '../../features/student/attendance_grievance_screen.dart';
import '../../features/student/fee_payment_screen.dart';
import '../../features/student/fee_receipt_request_screen.dart';
import '../../features/student/marks_screen.dart';
import '../../features/files/certificates_screen.dart';
import '../../features/files/salary_slips_screen.dart';
import '../../features/timetable/timetable_screen.dart';
import '../../features/complaints/complaints_screen.dart';
import '../../features/admin/admin_complaints_screen.dart';
import '../../features/expenses/expenses_screen.dart';
import '../../features/admin/students_manage_screen.dart';
import '../../features/admin/faculty_manage_screen.dart';
import '../../features/admin/admin_attendance_screen.dart';
import '../../features/admin/admin_leaves_screen.dart';
import '../../features/admin/admin_notices_screen.dart';
import '../../features/admin/admin_fees_screen.dart';
import '../../features/admin/admin_send_notification_screen.dart';
import '../../features/faculty/mark_attendance_screen.dart';
import '../../features/faculty/grievance_review_screen.dart';
import '../../features/faculty/student_leaves_review_screen.dart';
import '../../features/faculty/id_card_request_screen.dart';
import '../../features/faculty/faculty_budget_requests_screen.dart';
import '../../features/faculty/upload_marks_screen.dart';
import '../../features/admin/admin_fee_payments_screen.dart';
import '../../features/admin/admin_fee_receipt_requests_screen.dart';
import '../../features/admin/admin_faculty_leaves_screen.dart';
import '../../features/admin/admin_budgets_screen.dart';
import '../../features/admin/admin_id_card_requests_screen.dart';
import '../../features/admin/admin_manage_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/admin-login', builder: (_, __) => const AdminLoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? (state.extra is Map ? (state.extra as Map)['email'] as String? : null);
          return RegisterScreen(prefilledEmail: email);
        },
      ),
      GoRoute(
        path: '/student',
        builder: (_, __) => const StudentDashboard(),
        routes: [
          GoRoute(path: 'attendance', builder: (_, __) => const AttendanceScreen()),
          GoRoute(path: 'attendance-grievance', builder: (_, __) => const AttendanceGrievanceScreen()),
          GoRoute(path: 'fee-payment', builder: (_, __) => const FeePaymentScreen()),
          GoRoute(path: 'fee-receipts', builder: (_, __) => const FeeReceiptsScreen()),
          GoRoute(path: 'fee-receipt-request', builder: (_, __) => const FeeReceiptRequestScreen()),
          GoRoute(path: 'marks', builder: (_, __) => const MarksScreen()),
          GoRoute(path: 'leaves', builder: (_, __) => const LeavesScreen()),
          GoRoute(path: 'certificates', builder: (_, __) => const CertificatesScreen()),
          GoRoute(path: 'timetable', builder: (_, __) => const TimetableScreen()),
          GoRoute(path: 'notices', builder: (_, __) => const NoticesScreen()),
          GoRoute(path: 'complaints', builder: (_, __) => const ComplaintsScreen()),
          GoRoute(path: 'notifications', builder: (_, __) => const NotificationsScreen()),
        ],
      ),
      GoRoute(
        path: '/faculty',
        builder: (_, __) => const FacultyDashboard(),
        routes: [
          GoRoute(path: 'mark-attendance', builder: (_, __) => const MarkAttendanceScreen()),
          GoRoute(path: 'grievance-review', builder: (_, __) => const GrievanceReviewScreen()),
          GoRoute(path: 'student-leaves', builder: (_, __) => const StudentLeavesReviewScreen()),
          GoRoute(path: 'upload-marks', builder: (_, __) => const UploadMarksScreen()),
          GoRoute(path: 'timetable', builder: (_, __) => const TimetableScreen()),
          GoRoute(path: 'salary-slips', builder: (_, __) => const SalarySlipsScreen()),
          GoRoute(path: 'leaves', builder: (_, __) => const LeavesScreen()),
          GoRoute(path: 'id-card-request', builder: (_, __) => const IdCardRequestScreen()),
          GoRoute(path: 'notices', builder: (_, __) => const NoticesScreen()),
          GoRoute(path: 'complaints', builder: (_, __) => const ComplaintsScreen()),
          GoRoute(path: 'budget-requests', builder: (_, __) => const FacultyBudgetRequestsScreen()),
          GoRoute(path: 'notifications', builder: (_, __) => const NotificationsScreen()),
        ],
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminDashboard(),
        routes: [
          GoRoute(path: 'students', builder: (_, __) => const StudentsManageScreen()),
          GoRoute(path: 'faculty', builder: (_, __) => const FacultyManageScreen()),
          GoRoute(path: 'attendance', builder: (_, __) => const AdminAttendanceScreen()),
          GoRoute(path: 'notices', builder: (_, __) => const AdminNoticesScreen()),
          GoRoute(path: 'leaves', builder: (_, __) => const AdminLeavesScreen()),
          GoRoute(path: 'faculty-leaves', builder: (_, __) => const AdminFacultyLeavesScreen()),
          GoRoute(path: 'fees', builder: (_, __) => const AdminFeesScreen()),
          GoRoute(path: 'fee-payments', builder: (_, __) => const AdminFeePaymentsScreen()),
          GoRoute(path: 'fee-receipt-requests', builder: (_, __) => const AdminFeeReceiptRequestsScreen()),
          GoRoute(path: 'expenses', builder: (_, __) => const ExpensesScreen()),
          GoRoute(path: 'budgets', builder: (_, __) => const AdminBudgetsScreen()),
          GoRoute(path: 'id-card-requests', builder: (_, __) => const AdminIdCardRequestsScreen()),
          GoRoute(path: 'complaints', builder: (_, __) => const AdminComplaintsScreen()),
          GoRoute(path: 'send-notification', builder: (_, __) => const AdminSendNotificationScreen()),
          GoRoute(path: 'notifications', builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: 'admins', builder: (_, __) => const AdminManageScreen()),
        ],
      ),
    ],
  );
}
