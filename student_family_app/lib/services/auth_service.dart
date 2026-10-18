import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:5000/api/auth';

  // ==================== ADMIN LOGIN (Existing) ====================
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        await _saveSession(data, role: 'admin');
        return data;
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ==================== ✅ TEACHER LOGIN (New) ====================
  static Future<Map<String, dynamic>> loginTeacher(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/teacher/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        await _saveSession(data, role: 'teacher');
        return data;
      } else {
        throw Exception(data['message'] ?? 'Teacher login failed');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ==================== ✅ PARENT LOGIN (New) ====================
  static Future<Map<String, dynamic>> loginParent(String phone, String pin) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/parent/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'primaryPhone': phone, 'portalPin': pin}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        await _saveSession(data, role: 'parent');
        return data;
      } else {
        throw Exception(data['message'] ?? 'Parent login failed');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ==================== ✅ Common Session Saver ====================
  static Future<void> _saveSession(Map<String, dynamic> data, {required String role}) async {
    final prefs = await SharedPreferences.getInstance();

    if (data['token'] != null) {
      await prefs.setString('token', data['token']);
    }
    await prefs.setString('role', role);

    final userData = data['data'];
    if (userData != null) {
      // Role ke hisaab se alag naam field hota hai
      String displayName = '';
      if (role == 'admin') {
        displayName = userData['name'] ?? 'Admin';
      } else if (role == 'teacher') {
        displayName = userData['fullName'] ?? 'Teacher';
      } else if (role == 'parent') {
        displayName = userData['familyName'] ?? 'Parent';
      }

      await prefs.setString('userName', displayName);
      await prefs.setString('userId', userData['_id'] ?? '');

      // Teacher-specific: assignedClasses save karna (future use ke liye)
      if (role == 'teacher' && userData['assignedClasses'] != null) {
        await prefs.setStringList(
          'assignedClasses',
          List<String>.from(userData['assignedClasses']),
        );
      }

      // ✅ NEW: Teacher-specific: assignedSubjects save karna
      // (Bulk Result Entry mein teacher ko sirf apni subjects dikhane ke liye)
      if (role == 'teacher' && userData['assignedSubjects'] != null) {
        await prefs.setStringList(
          'assignedSubjects',
          List<String>.from(userData['assignedSubjects']),
        );
      }
    }
  }

  // REGISTER FIRST ADMIN (Unchanged)
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Registration failed');
    }
  }

  // FORGOT PASSWORD (Unchanged - admin only)
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Request failed');
    }
  }

  // RESET PASSWORD (Unchanged)
  static Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String password,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/reset-password/$token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Reset failed');
    }
  }

  // LOGOUT
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // CHECK IF LOGGED IN
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token');
  }

  // GET SAVED TOKEN
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ✅ GET SAVED ROLE
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  // ✅ GET SAVED USER NAME
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName');
  }

  // ✅ GET ASSIGNED CLASSES (teacher only)
  static Future<List<String>> getAssignedClasses() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('assignedClasses') ?? [];
  }

  // ✅ NEW: GET ASSIGNED SUBJECTS (teacher only)
  static Future<List<String>> getAssignedSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('assignedSubjects') ?? [];
  }
}