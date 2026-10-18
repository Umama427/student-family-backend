import 'package:flutter/material.dart';
import '../models/exam_model.dart';
import '../services/api_service.dart';

class ExamProvider with ChangeNotifier {
  List<ExamModel> _exams = [];
  bool _isLoading = false;
  String? _error;

  List<ExamModel> get exams => _exams;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchExams({String? className}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.getExams(className: className);
      _exams = data.map((e) => ExamModel.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createExam(Map<String, dynamic> examData) async {
    try {
      await ApiService.createExam(examData);
      await fetchExams();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExam(String id) async {
    try {
      await ApiService.deleteExam(id);
      _exams.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}