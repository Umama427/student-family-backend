import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ClassProvider with ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  List<dynamic> classes = [];
  List<dynamic> subjects = [];

  Future<void> fetchClasses() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      classes = await ApiService.getClasses();
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> addClass(Map<String, dynamic> data) async {
    try {
      await ApiService.createClass(data);
      await fetchClasses();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeClass(String id) async {
    try {
      await ApiService.deleteClass(id);
      await fetchClasses();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchSubjects(String classId) async {
    isLoading = true;
    notifyListeners();
    try {
      subjects = await ApiService.getSubjects(classId: classId);
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> addSubject(Map<String, dynamic> data) async {
    try {
      await ApiService.createSubject(data);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeSubject(String id) async {
    try {
      await ApiService.deleteSubject(id);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}