import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/family_model.dart';

class FamilyProvider with ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  List<FamilyModel> families = [];

  Future<void> fetchFamilies() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService.getFamilies();
      families = data.map((e) => FamilyModel.fromJson(e)).toList();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> addFamily(Map<String, dynamic> familyData) async {
    try {
      await ApiService.createFamily(familyData);
      await fetchFamilies();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ✅ NEW: Admin sets/resets a family's portal PIN
  Future<bool> setFamilyPin(String familyId, String pin) async {
    try {
      await ApiService.setFamilyPin(familyId, pin);
      await fetchFamilies();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}