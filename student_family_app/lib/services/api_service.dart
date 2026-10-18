import 'dart:convert';
import 'dart:html' as html; // Flutter Web: PDF download ke liye
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static const Duration _timeout = Duration(seconds: 15);

  // ==================== AUTH HEADERS ====================

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== HELPERS ====================

  static Future<http.Response> _get(String url) async {
    debugPrint('GET $url');
    final res = await http
        .get(Uri.parse(url), headers: await _headers())
        .timeout(_timeout);
    debugPrint('  -> ${res.statusCode}');
    return res;
  }

  static Future<http.Response> _post(String url, Map<String, dynamic> body) async {
    debugPrint('POST $url  body: $body');
    final res = await http
        .post(Uri.parse(url), headers: await _headers(), body: jsonEncode(body))
        .timeout(_timeout);
    debugPrint('  -> ${res.statusCode}');
    return res;
  }

  static Future<http.Response> _put(String url, Map<String, dynamic> body) async {
    debugPrint('PUT $url  body: $body');
    final res = await http
        .put(Uri.parse(url), headers: await _headers(), body: jsonEncode(body))
        .timeout(_timeout);
    debugPrint('  -> ${res.statusCode}');
    return res;
  }

  static Future<http.Response> _delete(String url) async {
    debugPrint('DELETE $url');
    final res = await http
        .delete(Uri.parse(url), headers: await _headers())
        .timeout(_timeout);
    debugPrint('  -> ${res.statusCode}');
    return res;
  }

  static List<dynamic> _extractList(http.Response res, String what) {
    if (res.statusCode != 200) {
      throw Exception('Failed to load $what (${res.statusCode}): ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is List) return decoded;

    if (decoded is Map) {
      if (decoded['data'] is List) return decoded['data'];
      for (final value in decoded.values) {
        if (value is List) return value;
      }
    }
    debugPrint('Unexpected $what response shape: ${res.body}');
    return [];
  }

  static Map<String, dynamic> _extractMap(http.Response res, String what) {
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to $what (${res.statusCode}): ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is Map && decoded['data'] is Map) {
      return Map<String, dynamic>.from(decoded['data']);
    }
    return Map<String, dynamic>.from(decoded as Map);
  }

  // ==================== DASHBOARD ====================

  static Future<Map<String, dynamic>> getDashboardSummary() async {
    final res = await _get('${ApiConfig.dashboard}/summary');
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    throw Exception('Failed to load dashboard summary (${res.statusCode})');
  }

  static Future<List<dynamic>> getRevenueTrend() async {
    final res = await _get('${ApiConfig.dashboard}/revenue-trend');
    return _extractList(res, 'revenue trend');
  }

  static Future<List<dynamic>> getSalarySummary() async {
    final res = await _get('${ApiConfig.dashboard}/salary-summary');
    return _extractList(res, 'salary summary');
  }

  // ==================== FAMILIES ====================

  static Future<List<dynamic>> getFamilies() async {
    final res = await _get(ApiConfig.families);
    return _extractList(res, 'families');
  }

  static Future<Map<String, dynamic>> createFamily(Map<String, dynamic> data) async {
    final res = await _post(ApiConfig.families, data);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    throw Exception('Failed to create family (${res.statusCode}): ${res.body}');
  }

  static Future<Map<String, dynamic>> getFamilyById(String id) async {
    final res = await _get('${ApiConfig.families}/$id');
    return _extractMap(res, 'load family');
  }

  // ==================== STUDENTS ====================

  static Future<List<dynamic>> getStudents() async {
    final res = await _get(ApiConfig.students);
    return _extractList(res, 'students');
  }

  static Future<Map<String, dynamic>> createStudent(Map<String, dynamic> data) async {
    final res = await _post(ApiConfig.students, data);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    throw Exception('Failed to create student (${res.statusCode}): ${res.body}');
  }

  static Future<void> deleteStudent(String id) async {
    final res = await _delete('${ApiConfig.students}/$id');
    if (res.statusCode != 200) {
      throw Exception('Failed to delete student (${res.statusCode}): ${res.body}');
    }
  }

  static Future<List<dynamic>> getStudentsByFamily(String familyId) async {
    final allStudents = await getStudents();
    return allStudents.where((s) {
      final fam = s['familyId'];
      if (fam is Map) return fam['_id'] == familyId;
      return fam == familyId;
    }).toList();
  }

  // ✅ NEW: Update Student Progress
  static Future<Map<String, dynamic>> updateStudentProgress(
    String studentId, {
    required double attendancePercentage,
    required double currentGPA,
    String? remarks,
  }) async {
    final res = await _put('${ApiConfig.students}/$studentId/progress', {
      'attendancePercentage': attendancePercentage,
      'currentGPA': currentGPA,
      'remarks': remarks ?? '',
    });
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body)['data']);
    }
    throw Exception('Failed to update progress (${res.statusCode}): ${res.body}');
  }

  // ==================== FEE CHALLANS ====================

  static Future<List<dynamic>> getChallans() async {
    final res = await _get(ApiConfig.challans);
    return _extractList(res, 'challans');
  }

  static Future<Map<String, dynamic>> createChallan(Map<String, dynamic> data) async {
    final res = await _post(ApiConfig.challans, data);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    throw Exception('Failed to create challan (${res.statusCode}): ${res.body}');
  }

  static Future<Map<String, dynamic>> markChallanAsPaid(
      String challanId, double paidAmount, String paymentMethod) async {
    final res = await _put('${ApiConfig.challans}/$challanId/pay', {
      'paidAmount': paidAmount,
      'paymentMethod': paymentMethod,
    });
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    throw Exception('Failed to update challan (${res.statusCode}): ${res.body}');
  }

  // ✅ NEW: Apply Penalty on Overdue Challans
  static Future<Map<String, dynamic>> applyPenaltyOnOverdue({double penaltyAmount = 500}) async {
    final res = await _post('${ApiConfig.challans}/apply-penalty', {
      'penaltyAmount': penaltyAmount,
    });
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    throw Exception('Failed to apply penalty (${res.statusCode}): ${res.body}');
  }

  // ==================== STAFF ====================

  static Future<List<dynamic>> getStaff() async {
    final res = await _get(ApiConfig.staff);
    return _extractList(res, 'staff');
  }

  static Future<Map<String, dynamic>> createStaff(Map<String, dynamic> data) async {
    final res = await _post(ApiConfig.staff, data);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    throw Exception('Failed to create staff (${res.statusCode}): ${res.body}');
  }

  // ==================== SALARIES ====================

  static Future<List<dynamic>> getSalaries() async {
    final res = await _get(ApiConfig.salaries);
    return _extractList(res, 'salaries');
  }

  static Future<Map<String, dynamic>> createSalary(Map<String, dynamic> data) async {
    final res = await _post(ApiConfig.salaries, data);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    throw Exception('Failed to create salary (${res.statusCode}): ${res.body}');
  }

  // ==================== WHATSAPP ====================

  static Future<Map<String, dynamic>> getFeeReminderLink(String challanId) async {
    final res = await _get('${ApiConfig.whatsapp}/fee-reminder/$challanId');
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    throw Exception('Failed to generate WhatsApp link (${res.statusCode})');
  }

  static Future<Map<String, dynamic>> getPaymentConfirmationLink(String challanId) async {
    final res = await _get('${ApiConfig.whatsapp}/payment-confirmation/$challanId');
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    throw Exception('Failed to generate WhatsApp link (${res.statusCode})');
  }

  static Future<Map<String, dynamic>> getAnnouncementLink(
      String familyId, String message, String type) async {
    final res = await _post(
      '${ApiConfig.whatsapp}/announcement/$familyId',
      {'message': message, 'type': type},
    );
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    throw Exception('Failed to generate announcement link (${res.statusCode})');
  }

  static Future<Map<String, dynamic>> getBulkAnnouncementLinks(
      String message, String type) async {
    final res = await _post(
      '${ApiConfig.whatsapp}/bulk-announcement',
      {'message': message, 'type': type},
    );
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    throw Exception('Failed to generate bulk announcement (${res.statusCode})');
  }

  // ✅ NEW: Salary Slip WhatsApp Link
  static Future<Map<String, dynamic>> getSalaryWhatsAppLink(String salaryId) async {
    final res = await _get('${ApiConfig.whatsapp}/salary/$salaryId');
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    throw Exception('Failed to generate salary WhatsApp link (${res.statusCode})');
  }

  // ==================== PDF URLs ====================

  static String getChallanPdfUrl(String challanId) =>
      '${ApiConfig.challans}/$challanId/pdf';

  static String getReceiptPdfUrl(String challanId) =>
      '${ApiConfig.challans}/$challanId/receipt';

  // ==================== FILE DOWNLOAD (WITH TOKEN) ====================

  static Future<void> _downloadFile(String url, String fileName, String mimeType) async {
    debugPrint('FILE GET $url');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('Login token not found. Please login again.');
    }

    final res = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 30));
    debugPrint('  -> ${res.statusCode}');

    if (res.statusCode != 200) {
      throw Exception('Failed to download file (${res.statusCode}): ${res.body}');
    }

    final blob = html.Blob([res.bodyBytes], mimeType);
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: blobUrl)
      ..setAttribute('download', fileName);
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(blobUrl);
  }

  static Future<void> _downloadPdf(String url, String fileName) =>
      _downloadFile(url, fileName, 'application/pdf');

  /// Challan PDF download (Bank/Accounts/Academics/Student copies)
  static Future<void> downloadChallanPdf(String challanId) =>
      _downloadPdf(getChallanPdfUrl(challanId), 'Challan-$challanId.pdf');

  /// Payment receipt PDF download
  static Future<void> downloadReceiptPdf(String challanId) =>
      _downloadPdf(getReceiptPdfUrl(challanId), 'Receipt-$challanId.pdf');

  // ==================== ✅ REPORTS: EXCEL + REPORT CARD ====================

  static Future<void> downloadExamResultsExcel(String examId, String examName) => _downloadFile(
        '${ApiConfig.reports}/exam/$examId/excel',
        'Results-${examName.replaceAll(' ', '_')}.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

  static Future<void> downloadStudentReportCard(
          String studentId, String examId, String studentName) =>
      _downloadPdf(
        '${ApiConfig.reports}/student/$studentId/exam/$examId/pdf',
        'ReportCard-${studentName.replaceAll(' ', '_')}.pdf',
      );

  static Future<void> downloadClassReportCards(String examId, String className) =>
      _downloadPdf(
        '${ApiConfig.reports}/class/exam/$examId/pdf',
        'ReportCards-${className.replaceAll(' ', '_')}.pdf',
      );

  // ==================== ✅ BULK OPERATIONS ====================

  static Future<Map<String, dynamic>> bulkGenerateChallans(Map<String, dynamic> data) async {
    final res = await _post('${ApiConfig.bulk}/challans', data);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    throw Exception('Failed to bulk generate challans (${res.statusCode}): ${res.body}');
  }

  static Future<Map<String, dynamic>> bulkEnterResults(Map<String, dynamic> data) async {
    final res = await _post('${ApiConfig.bulk}/results', data);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    throw Exception('Failed to bulk enter results (${res.statusCode}): ${res.body}');
  }

  // ==================== ATTENDANCE ====================

  static Future<Map<String, dynamic>> markAttendance({
    required String type,
    required String refId,
    String? date,
    required String status,
    String? remarks,
  }) async {
    final res = await _post(ApiConfig.attendance, {
      'type': type,
      'refId': refId,
      if (date != null) 'date': date,
      'status': status,
      if (remarks != null) 'remarks': remarks,
    });
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body)['data']);
    }
    throw Exception('Failed to mark attendance (${res.statusCode}): ${res.body}');
  }

  static Future<void> bulkMarkAttendance({
    required String type,
    String? date,
    required List<Map<String, dynamic>> records,
  }) async {
    final res = await _post('${ApiConfig.attendance}/bulk', {
      'type': type,
      if (date != null) 'date': date,
      'records': records,
    });
    if (res.statusCode != 200) {
      throw Exception('Failed to bulk mark attendance (${res.statusCode}): ${res.body}');
    }
  }

  static Future<List<dynamic>> getAttendance({
    String? type,
    String? refId,
    int? month,
    int? year,
  }) async {
    final params = <String, String>{};
    if (type != null) params['type'] = type;
    if (refId != null) params['refId'] = refId;
    if (month != null) params['month'] = month.toString();
    if (year != null) params['year'] = year.toString();

    final uri = Uri.parse(ApiConfig.attendance).replace(queryParameters: params.isEmpty ? null : params);
    final res = await _get(uri.toString());
    return _extractList(res, 'attendance');
  }

  static Future<Map<String, dynamic>> getAttendanceSummary({
    required String type,
    required String refId,
  }) async {
    final uri = Uri.parse('${ApiConfig.attendance}/summary')
        .replace(queryParameters: {'type': type, 'refId': refId});
    final res = await _get(uri.toString());
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body)['data']);
    }
    throw Exception('Failed to load attendance summary (${res.statusCode}): ${res.body}');
  }

  static Future<void> deleteAttendance(String id) async {
    final res = await _delete('${ApiConfig.attendance}/$id');
    if (res.statusCode != 200) {
      throw Exception('Failed to delete attendance (${res.statusCode}): ${res.body}');
    }
  }

  // ==================== ✅ NEW (Round 3): ATTENDANCE HISTORY / DAILY ROSTER ====================

  /// Fetch the full roster (students or staff) for a given date, with their
  /// attendance status already applied (or null if not marked yet).
  /// Backed by GET /api/attendance/roster?type=&className=&date=
  static Future<List<dynamic>> getAttendanceRoster({
    required String type, // 'student' or 'staff'
    String? className, // only relevant when type == 'student'
    required DateTime date,
  }) async {
    final params = <String, String>{
      'type': type,
      'date':
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    };
    if (className != null && className.isNotEmpty) {
      params['className'] = className;
    }

    final uri = Uri.parse('${ApiConfig.attendance}/roster').replace(queryParameters: params);
    final res = await _get(uri.toString());
    return _extractList(res, 'attendance roster');
  }

  // ==================== NOTIFICATIONS ====================

  static Future<Map<String, dynamic>> createNotification({
    required String title,
    required String message,
    String? type,
    String? audience,
  }) async {
    final res = await _post(ApiConfig.notifications, {
      'title': title,
      'message': message,
      if (type != null) 'type': type,
      if (audience != null) 'audience': audience,
    });
    if (res.statusCode == 201 || res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body)['data']);
    }
    throw Exception('Failed to create notification (${res.statusCode}): ${res.body}');
  }

  static Future<List<dynamic>> getNotifications({
    String? audience,
    String? type,
  }) async {
    final params = <String, String>{};
    if (audience != null) params['audience'] = audience;
    if (type != null) params['type'] = type;

    final uri = Uri.parse(ApiConfig.notifications).replace(queryParameters: params.isEmpty ? null : params);
    final res = await _get(uri.toString());
    return _extractList(res, 'notifications');
  }

  static Future<Map<String, dynamic>> markNotificationAsRead(String id) async {
    final res = await _put('${ApiConfig.notifications}/$id/read', {});
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body)['data']);
    }
    throw Exception('Failed to mark notification as read (${res.statusCode}): ${res.body}');
  }

  static Future<void> deleteNotification(String id) async {
    final res = await _delete('${ApiConfig.notifications}/$id');
    if (res.statusCode != 200) {
      throw Exception('Failed to delete notification (${res.statusCode}): ${res.body}');
    }
  }

  // ==================== EXAMS ====================

  static Future<List<dynamic>> getExams({String? className}) async {
    final params = <String, String>{};
    if (className != null) params['className'] = className;
    final uri = Uri.parse(ApiConfig.exams)
        .replace(queryParameters: params.isEmpty ? null : params);
    final res = await _get(uri.toString());
    return _extractList(res, 'exams');
  }

  static Future<Map<String, dynamic>> createExam(Map<String, dynamic> data) async {
    final res = await _post(ApiConfig.exams, data);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return _extractMap(res, 'create exam');
    }
    throw Exception('Failed to create exam (${res.statusCode}): ${res.body}');
  }

  static Future<void> deleteExam(String id) async {
    final res = await _delete('${ApiConfig.exams}/$id');
    if (res.statusCode != 200) {
      throw Exception('Failed to delete exam (${res.statusCode}): ${res.body}');
    }
  }

  // ==================== RESULTS ====================

  static Future<List<dynamic>> getResultsByExam(String examId) async {
    final res = await _get('${ApiConfig.results}/by-exam/$examId');
    return _extractList(res, 'results');
  }

  static Future<List<dynamic>> getResultsByStudent(String studentId) async {
    final res = await _get('${ApiConfig.results}/by-student/$studentId');
    return _extractList(res, 'results');
  }

  static Future<Map<String, dynamic>> getClassSummary(String examId) async {
    final res = await _get('${ApiConfig.results}/class-summary/$examId');
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body)['data']);
    }
    throw Exception('Failed to load class summary (${res.statusCode}): ${res.body}');
  }

  static Future<Map<String, dynamic>> createResult(Map<String, dynamic> data) async {
    final res = await _post(ApiConfig.results, data);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return _extractMap(res, 'create result');
    }
    throw Exception('Failed to create result (${res.statusCode}): ${res.body}');
  }

  static Future<void> deleteResult(String id) async {
    final res = await _delete('${ApiConfig.results}/$id');
    if (res.statusCode != 200) {
      throw Exception('Failed to delete result (${res.statusCode}): ${res.body}');
    }
  }

  // ==================== AUDIT LOGS ====================

  static Future<Map<String, dynamic>> getAuditLogs({
    String? module,
    String? action,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (module != null && module.isNotEmpty) params['module'] = module;
    if (action != null && action.isNotEmpty) params['action'] = action;

    final uri = Uri.parse(ApiConfig.auditLogs).replace(queryParameters: params);
    final res = await _get(uri.toString());

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return Map<String, dynamic>.from(decoded);
    }
    throw Exception('Failed to load audit logs (${res.statusCode}): ${res.body}');
  }

  // ==================== ✅ CLASSES ====================

  static Future<List<dynamic>> getClasses() async {
    final res = await _get(ApiConfig.classes);
    return _extractList(res, 'classes');
  }

  static Future<Map<String, dynamic>> getClassById(String id) async {
    final res = await _get('${ApiConfig.classes}/$id');
    return _extractMap(res, 'load class');
  }

  static Future<Map<String, dynamic>> createClass(Map<String, dynamic> data) async {
    final res = await _post(ApiConfig.classes, data);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return _extractMap(res, 'create class');
    }
    throw Exception('Failed to create class (${res.statusCode}): ${res.body}');
  }

  static Future<Map<String, dynamic>> updateClass(String id, Map<String, dynamic> data) async {
    final res = await _put('${ApiConfig.classes}/$id', data);
    if (res.statusCode == 200) {
      return _extractMap(res, 'update class');
    }
    throw Exception('Failed to update class (${res.statusCode}): ${res.body}');
  }

  static Future<void> deleteClass(String id) async {
    final res = await _delete('${ApiConfig.classes}/$id');
    if (res.statusCode != 200) {
      throw Exception('Failed to delete class (${res.statusCode}): ${res.body}');
    }
  }

  // ==================== ✅ SUBJECTS ====================

  static Future<List<dynamic>> getSubjects({String? classId}) async {
    final uri = Uri.parse(ApiConfig.subjects).replace(
      queryParameters: classId != null ? {'classId': classId} : null,
    );
    final res = await _get(uri.toString());
    return _extractList(res, 'subjects');
  }

  static Future<Map<String, dynamic>> createSubject(Map<String, dynamic> data) async {
    final res = await _post(ApiConfig.subjects, data);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return _extractMap(res, 'create subject');
    }
    throw Exception('Failed to create subject (${res.statusCode}): ${res.body}');
  }

  static Future<void> deleteSubject(String id) async {
    final res = await _delete('${ApiConfig.subjects}/$id');
    if (res.statusCode != 200) {
      throw Exception('Failed to delete subject (${res.statusCode}): ${res.body}');
    }
  }

  // ==================== ✅ PORTAL ACCESS MANAGEMENT ====================

  static Future<Map<String, dynamic>> setStaffCredentials(
    String staffId, {
    String? email,
    String? password,
    List<String>? assignedClasses,
  }) async {
    final body = <String, dynamic>{};
    if (email != null) body['email'] = email;
    if (password != null && password.isNotEmpty) body['password'] = password;
    if (assignedClasses != null) body['assignedClasses'] = assignedClasses;

    final res = await _put('${ApiConfig.auth}/admin/set-staff-credentials/$staffId', body);
    if (res.statusCode == 200) {
      return _extractMap(res, 'set staff credentials');
    }
    throw Exception('Failed to set staff credentials (${res.statusCode}): ${res.body}');
  }

  static Future<Map<String, dynamic>> setFamilyPin(String familyId, String pin) async {
    final res = await _put('${ApiConfig.auth}/admin/set-family-pin/$familyId', {'portalPin': pin});
    if (res.statusCode == 200) {
      return _extractMap(res, 'set family pin');
    }
    throw Exception('Failed to set family PIN (${res.statusCode}): ${res.body}');
  }

  // ==================== ✅ PARENT: MY CHILDREN ====================

  static Future<List<dynamic>> getMyChildren() async {
    final res = await _get('${ApiConfig.parent}/my-children');
    return _extractList(res, 'my children');
  }

  static Future<List<dynamic>> getChildAttendance(String childId) async {
    final res = await _get('${ApiConfig.parent}/children/$childId/attendance');
    return _extractList(res, 'child attendance');
  }

  static Future<List<dynamic>> getChildChallans(String childId) async {
    final res = await _get('${ApiConfig.parent}/children/$childId/challans');
    return _extractList(res, 'child challans');
  }

  static Future<List<dynamic>> getChildResults(String childId) async {
    final res = await _get('${ApiConfig.parent}/children/$childId/results');
    return _extractList(res, 'child results');
  }

  // ==================== ✅ NEW (Round 3): SUPPORT ====================

  /// Send a new support message (Teacher/Parent portal "Send us a Message" form)
  static Future<Map<String, dynamic>> sendSupportMessage(Map<String, dynamic> data) async {
    final res = await _post(ApiConfig.support, data);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return _extractMap(res, 'send support message');
    }
    throw Exception('Failed to send support message (${res.statusCode}): ${res.body}');
  }

  /// Get support messages sent by the currently logged-in teacher/parent
  static Future<List<dynamic>> getMySupportMessages() async {
    final res = await _get('${ApiConfig.support}/my');
    return _extractList(res, 'my support messages');
  }

  /// Admin: get ALL support messages
  static Future<List<dynamic>> getAllSupportMessages() async {
    final res = await _get(ApiConfig.support);
    return _extractList(res, 'support messages');
  }

  /// Admin: mark a support message as resolved (optionally with a reply)
  static Future<Map<String, dynamic>> resolveSupportMessage(String id, {String? adminReply}) async {
    final res = await _put('${ApiConfig.support}/$id/resolve', {
      if (adminReply != null) 'adminReply': adminReply,
    });
    if (res.statusCode == 200) {
      return _extractMap(res, 'resolve support message');
    }
    throw Exception('Failed to resolve support message (${res.statusCode}): ${res.body}');
  }

  /// Admin: delete a support message
  static Future<void> deleteSupportMessage(String id) async {
    final res = await _delete('${ApiConfig.support}/$id');
    if (res.statusCode != 200) {
      throw Exception('Failed to delete support message (${res.statusCode}): ${res.body}');
    }
  }
}