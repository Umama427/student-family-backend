import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/families_screen.dart';
import '../screens/students_screen.dart';
import '../screens/fee_challans_screen.dart';
import '../screens/staff_salary_screen.dart';
import '../screens/attendance_screen.dart';
import '../screens/attendance_history_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/exams_screen.dart';
import '../screens/audit_logs_screen.dart';
import '../screens/classes_screen.dart';
import '../screens/my_children_screen.dart';
import '../screens/bulk_fee_challan_screen.dart';
import '../screens/bulk_result_entry_screen.dart';
import '../screens/support_screen.dart';

class MenuItem {
  final String title;
  final IconData icon;
  final String route;
  final List<String> allowedRoles;
  final Widget Function() screenBuilder;

  const MenuItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.allowedRoles,
    required this.screenBuilder,
  });
}

final List<MenuItem> allMenuItems = [
  MenuItem(
    title: 'Dashboard',
    icon: Icons.dashboard_rounded,
    route: '/dashboard',
    allowedRoles: ['admin', 'teacher', 'parent'],
    screenBuilder: () => const DashboardScreen(),
  ),
  MenuItem(
    title: 'Families',
    icon: Icons.groups_rounded,
    route: '/families',
    allowedRoles: ['admin'],
    screenBuilder: () => const FamiliesScreen(),
  ),
  MenuItem(
    title: 'Students',
    icon: Icons.person_rounded,
    route: '/students',
    allowedRoles: ['admin', 'teacher'],
    screenBuilder: () => const StudentsScreen(),
  ),
  MenuItem(
    title: 'Classes',
    icon: Icons.class_rounded,
    route: '/classes',
    allowedRoles: ['admin'],
    screenBuilder: () => const ClassesScreen(),
  ),
  MenuItem(
    title: 'My Children',
    icon: Icons.family_restroom_rounded,
    route: '/my-children',
    allowedRoles: ['parent'],
    screenBuilder: () => const MyChildrenScreen(),
  ),
  MenuItem(
    title: 'Fee Challans',
    icon: Icons.receipt_long_rounded,
    route: '/challans',
    allowedRoles: ['admin', 'parent'],
    screenBuilder: () => const FeeChallansScreen(),
  ),
  MenuItem(
    title: 'Bulk Fee Challans',
    icon: Icons.receipt_rounded,
    route: '/bulk-challans',
    allowedRoles: ['admin'],
    screenBuilder: () => const BulkFeeChallanScreen(),
  ),
  MenuItem(
    title: 'Staff & Salary',
    icon: Icons.badge_rounded,
    route: '/staff',
    allowedRoles: ['admin'],
    screenBuilder: () => const StaffSalaryScreen(),
  ),
  MenuItem(
    title: 'Attendance',
    icon: Icons.fact_check_rounded,
    route: '/attendance',
    allowedRoles: ['admin', 'teacher', 'parent'],
    screenBuilder: () => const AttendanceScreen(),
  ),
  MenuItem(
    title: 'Attendance History',
    icon: Icons.calendar_month_rounded,
    route: '/attendance-history',
    allowedRoles: ['admin', 'teacher', 'parent'],
    screenBuilder: () => const AttendanceHistoryScreen(),
  ),
  MenuItem(
    title: 'Notifications',
    icon: Icons.notifications_rounded,
    route: '/notifications',
    allowedRoles: ['admin', 'teacher', 'parent'],
    screenBuilder: () => const NotificationsScreen(),
  ),
  MenuItem(
    title: 'Exams & Results',
    icon: Icons.grading_rounded,
    route: '/exams',
    allowedRoles: ['admin', 'teacher', 'parent'],
    screenBuilder: () => const ExamsScreen(),
  ),
  MenuItem(
    title: 'Bulk Result Entry',
    icon: Icons.table_chart_rounded,
    route: '/bulk-results',
    allowedRoles: ['admin', 'teacher'],
    screenBuilder: () => const BulkResultEntryScreen(),
  ),
  MenuItem(
    title: 'Support',
    icon: Icons.support_agent_rounded,
    route: '/support',
    allowedRoles: ['teacher', 'parent'],
    screenBuilder: () => const SupportScreen(),
  ),
  MenuItem(
    title: 'Audit Logs',
    icon: Icons.history_rounded,
    route: '/audit-logs',
    allowedRoles: ['admin'],
    screenBuilder: () => const AuditLogsScreen(),
  ),
];