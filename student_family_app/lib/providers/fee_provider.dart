import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/fee_challan_model.dart';

class FeeProvider with ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  List<FeeChallanModel> challans = [];

  Future<void> fetchChallans() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService.getChallans();
      challans = data.map((e) => FeeChallanModel.fromJson(e)).toList();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> addChallan(Map<String, dynamic> challanData) async {
    try {
      await ApiService.createChallan(challanData);
      await fetchChallans();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAsPaid(String challanId, double amount, String method) async {
    try {
      await ApiService.markChallanAsPaid(challanId, amount, method);
      await fetchChallans(); // Refresh list
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Filtered lists (useful for Fee Tracker screen tabs)
  List<FeeChallanModel> get paidChallans =>
      challans.where((c) => c.status == 'Paid').toList();

  List<FeeChallanModel> get pendingChallans =>
      challans.where((c) => c.status == 'Pending').toList();

  List<FeeChallanModel> get overdueChallans =>
      challans.where((c) => c.status == 'Overdue').toList();
}