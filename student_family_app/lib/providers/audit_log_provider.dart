import 'package:flutter/material.dart';
import '../models/audit_log_model.dart';
import '../services/api_service.dart';

class AuditLogProvider with ChangeNotifier {
  List<AuditLogModel> _logs = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;

  String? _moduleFilter;
  String? _actionFilter;

  List<AuditLogModel> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;
  String? get moduleFilter => _moduleFilter;
  String? get actionFilter => _actionFilter;

  Future<void> fetchLogs({int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getAuditLogs(
        module: _moduleFilter,
        action: _actionFilter,
        page: page,
      );

      final data = response['data'] as List;
      _logs = data.map((e) => AuditLogModel.fromJson(e)).toList();
      _currentPage = response['currentPage'] ?? 1;
      _totalPages = response['totalPages'] ?? 1;
      _totalCount = response['total'] ?? 0;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setModuleFilter(String? module) {
    _moduleFilter = module;
    fetchLogs(page: 1);
  }

  void setActionFilter(String? action) {
    _actionFilter = action;
    fetchLogs(page: 1);
  }

  void clearFilters() {
    _moduleFilter = null;
    _actionFilter = null;
    fetchLogs(page: 1);
  }

  void nextPage() {
    if (_currentPage < _totalPages) {
      fetchLogs(page: _currentPage + 1);
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      fetchLogs(page: _currentPage - 1);
    }
  }
}