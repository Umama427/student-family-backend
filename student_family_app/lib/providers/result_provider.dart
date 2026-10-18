import 'package:flutter/material.dart';
import '../models/result_model.dart';
import '../services/api_service.dart';

class ResultProvider with ChangeNotifier {
  List<ResultModel> _examResults = [];
  List<ResultModel> _studentResults = [];
  Map<String, dynamic>? _classSummary;
  bool _isLoading = false;
  String? _error;

  List<ResultModel> get examResults => _examResults;
  List<ResultModel> get studentResults => _studentResults;
  Map<String, dynamic>? get classSummary => _classSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchResultsByExam(String examId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService.getResultsByExam(examId);
      _examResults = data.map((r) => ResultModel.fromJson(r)).toList();
      await fetchClassSummary(examId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchClassSummary(String examId) async {
    try {
      _classSummary = await ApiService.getClassSummary(examId);
    } catch (e) {
      debugPrint('Failed to load class summary: $e');
    }
  }

  Future<void> fetchResultsByStudent(String studentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService.getResultsByStudent(studentId);
      _studentResults = data.map((r) => ResultModel.fromJson(r)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createResult(Map<String, dynamic> data, String examId) async {
    try {
      await ApiService.createResult(data);
      await fetchResultsByExam(examId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteResult(String id, String examId) async {
    try {
      await ApiService.deleteResult(id);
      await fetchResultsByExam(examId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}