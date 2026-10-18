import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart'; // ✅ ADDED

class DashboardProvider with ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  String role = 'admin'; // ✅ ADDED — track current role

  // Admin fields
  int totalStudents = 0;
  int totalFamilies = 0;
  int totalStaff = 0;

  int paidCount = 0;
  int pendingCount = 0;
  int overdueCount = 0;

  double paidAmount = 0;
  double pendingAmount = 0;

  double totalRevenueCollected = 0;
  double totalPendingAmount = 0;

  List<Map<String, dynamic>> revenueTrend = [];

  // ✅ ADDED — Teacher-specific fields
  List<String> assignedClasses = [];
  Map<String, dynamic> classWiseBreakdown = {};

  // ✅ ADDED — Parent-specific fields
  List<Map<String, dynamic>> children = [];
  int overdueChallanCount = 0;

  Future<void> fetchDashboardData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // ✅ Role pehle fetch karo
      role = await AuthService.getRole() ?? 'admin';

      final responseMap = await ApiService.getDashboardSummary();

      final summary = (responseMap['data'] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(responseMap['data'])
          : responseMap;

      // ✅ Top-level common fields (sab roles ke liye backend se aate hain)
      totalStudents = (responseMap['totalStudents'] ?? summary['totalStudents'] ?? 0) as int;
      totalFamilies = (responseMap['totalFamilies'] ?? summary['totalFamilies'] ?? 0) as int;
      totalStaff = (responseMap['totalStaff'] ?? summary['totalStaff'] ?? 0) as int;
      totalRevenueCollected =
          ((responseMap['totalRevenueCollected'] ?? summary['totalRevenueCollected'] ?? 0) as num).toDouble();
      totalPendingAmount =
          ((responseMap['totalPendingAmount'] ?? summary['totalPendingAmount'] ?? 0) as num).toDouble();

      // ✅ Admin-only: fee status breakdown
      final feeStatus = summary['feeStatusSummary'] is Map
          ? Map<String, dynamic>.from(summary['feeStatusSummary'])
          : {};

      final paidMap = feeStatus['paid'] is Map ? Map<String, dynamic>.from(feeStatus['paid']) : {};
      final pendingMap = feeStatus['pending'] is Map ? Map<String, dynamic>.from(feeStatus['pending']) : {};
      final overdueMap = feeStatus['overdue'] is Map ? Map<String, dynamic>.from(feeStatus['overdue']) : {};

      paidCount = (paidMap['count'] ?? 0) as int;
      pendingCount = (pendingMap['count'] ?? 0) as int;
      overdueCount = (overdueMap['count'] ?? 0) as int;
      paidAmount = ((paidMap['amount'] ?? 0) as num).toDouble();
      pendingAmount = ((pendingMap['amount'] ?? 0) as num).toDouble();

      // ✅ Teacher-specific data
      if (role == 'teacher') {
        assignedClasses = List<String>.from(summary['assignedClasses'] ?? []);
        classWiseBreakdown = Map<String, dynamic>.from(summary['classWiseBreakdown'] ?? {});
      }

      // ✅ Parent-specific data
      if (role == 'parent') {
        children = (summary['children'] as List? ?? [])
            .map((c) => Map<String, dynamic>.from(c))
            .toList();
        overdueChallanCount = (summary['overdueChallanCount'] ?? 0) as int;
      }

      // ✅ CRITICAL FIX: Revenue trend sirf Admin ke liye fetch karo
      if (role == 'admin') {
        try {
          final trend = await ApiService.getRevenueTrend();
          revenueTrend = trend.map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            return {
              'month': m['month'] ?? 10,
              'year': m['year'] ?? 2026,
              'amount': ((m['amount'] ?? 0) as num).toDouble(),
              'label': m['label'] ?? '',
            };
          }).toList();
        } catch (e) {
          // Revenue trend fail ho to bhi dashboard crash na ho
          revenueTrend = [];
          debugPrint('Revenue trend fetch skipped: $e');
        }
      } else {
        revenueTrend = []; // Teacher/Parent ke liye khali rakho
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }
}