import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/attendance_model.dart';

class AttendanceProvider with ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  List<AttendanceModel> records = [];

  // ✅ FIX: Always send a plain calendar date string ("yyyy-MM-dd") with
  // NO time component and NO timezone conversion. This guarantees the
  // exact date the user picked is the exact date that gets stored and
  // returned — regardless of server/browser timezone offset.
  // (Using date.toIso8601String() previously caused a day-shift bug
  // because it included local time without a 'Z', which the backend's
  // Date parser interpreted ambiguously.)
  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> fetchAttendance({
    String? type,
    String? refId,
    int? month,
    int? year,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService.getAttendance(
        type: type,
        refId: refId,
        month: month,
        year: year,
      );
      records = data.map((e) => AttendanceModel.fromJson(e)).toList();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> saveBulkAttendance({
    required String type,
    required DateTime date,
    required List<Map<String, dynamic>> records,
  }) async {
    try {
      await ApiService.bulkMarkAttendance(
        type: type,
        date: _formatDate(date), // ✅ FIXED: plain date string, no TZ shift
        records: records,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markSingleAttendance({
    required String type,
    required String refId,
    DateTime? date,
    required String status,
    String? remarks,
  }) async {
    try {
      await ApiService.markAttendance(
        type: type,
        refId: refId,
        date: date != null ? _formatDate(date) : null, // ✅ FIXED
        status: status,
        remarks: remarks,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeAttendance(String id) async {
    try {
      await ApiService.deleteAttendance(id);
      records.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchSummary({
    required String type,
    required String refId,
  }) async {
    return await ApiService.getAttendanceSummary(type: type, refId: refId);
  }
}