import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  List<NotificationModel> notifications = [];

  Future<void> fetchNotifications({String? audience, String? type}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService.getNotifications(audience: audience, type: type);
      notifications = data.map((e) => NotificationModel.fromJson(e)).toList();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> addNotification({
    required String title,
    required String message,
    String? type,
    String? audience,
  }) async {
    try {
      await ApiService.createNotification(
        title: title,
        message: message,
        type: type,
        audience: audience,
      );
      await fetchNotifications();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      await ApiService.markNotificationAsRead(id);
      final idx = notifications.indexWhere((n) => n.id == id);
      if (idx != -1) {
        notifications[idx] = notifications[idx].copyWith(isRead: true);
        notifyListeners();
      }
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeNotification(String id) async {
    try {
      await ApiService.deleteNotification(id);
      notifications.removeWhere((n) => n.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}