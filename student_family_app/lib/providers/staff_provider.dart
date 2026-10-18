import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StaffProvider with ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  List<dynamic> staffList = [];
  List<dynamic> salaryList = [];

  Future<void> fetchStaff() async {
    isLoading = true;
    notifyListeners();

    try {
      staffList = await ApiService.getStaff();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchSalaries() async {
    isLoading = true;
    notifyListeners();

    try {
      salaryList = await ApiService.getSalaries();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> addStaff(Map<String, dynamic> data) async {
    try {
      await ApiService.createStaff(data);
      await fetchStaff();
    } catch (e) {
      debugPrint('Error adding staff: $e');
    }
  }

  Future<void> generateSalary(Map<String, dynamic> data) async {
    try {
      await ApiService.createSalary(data);
      await fetchSalaries();
    } catch (e) {
      debugPrint('Error generating salary: $e');
    }
  }

  // ✅ NEW: Grant/update teacher portal access (email, password, assigned classes)
  Future<bool> setPortalAccess(
    String staffId, {
    String? email,
    String? password,
    List<String>? assignedClasses,
  }) async {
    try {
      await ApiService.setStaffCredentials(
        staffId,
        email: email,
        password: password,
        assignedClasses: assignedClasses,
      );
      await fetchStaff();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}