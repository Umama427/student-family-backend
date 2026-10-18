import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/student_model.dart';

class StudentProvider with ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  List<StudentModel> students = [];

  Future<void> fetchStudents() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService.getStudents();
      students = data.map((e) => StudentModel.fromJson(e)).toList();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> addStudent(Map<String, dynamic> studentData) async {
    try {
      await ApiService.createStudent(studentData);
      await fetchStudents(); // Refresh list
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeStudent(String id) async {
    try {
      await ApiService.deleteStudent(id);
      students.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get students belonging to a specific family (for Sibling Tree)
  List<StudentModel> getStudentsByFamily(String familyId) {
    return students.where((s) => s.familyIdString == familyId).toList();
  }
}