// ignore_for_file: deprecated_member_use
import 'dart:html' as html;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class PaymentExportService {
  // ---------- PAYMENTS ----------

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<String> createStripeCheckout(String challanId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.payments}/stripe/create-session'),
      headers: await _authHeaders(),
      body: jsonEncode({'challanId': challanId}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['url'] as String;
    }
    throw Exception(data['message'] ?? 'Stripe checkout failed');
  }

  // ✅ CHANGED: ab async hai — token ko query param me attach karta hai,
  // kyunki ye URL ek full browser page navigation (url_launcher) me khulta hai
  // jahan Authorization header bhejna possible nahi hota.
  static Future<String> getJazzCashRedirectUrl(String challanId) async {
    final token = await AuthService.getToken();
    final base = '${ApiConfig.payments}/jazzcash/redirect/$challanId';
    return token != null ? '$base?token=$token' : base;
  }

  static Future<String> getEasyPaisaRedirectUrl(String challanId) async {
    final token = await AuthService.getToken();
    final base = '${ApiConfig.payments}/easypaisa/redirect/$challanId';
    return token != null ? '$base?token=$token' : base;
  }

  static Future<Map<String, dynamic>> getPaymentStatus(String challanId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.payments}/status/$challanId'),
      headers: await _authHeaders(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Could not fetch payment status');
  }

  // Verify Stripe session after redirect back from Checkout
  static Future<Map<String, dynamic>> verifyStripeSession(String sessionId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.payments}/stripe/verify/$sessionId'),
      headers: await _authHeaders(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data; // { success: true, status: 'Paid' | 'Pending', challanId: ... }
    }
    throw Exception(data['message'] ?? 'Could not verify payment');
  }

  // ---------- EXPORT ----------

  static Future<void> exportModule(String module, String format) async {
    final url = '${ApiConfig.exportBase}/$module?format=$format';
    final response = await http.get(
      Uri.parse(url),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      String message = 'Export failed';
      try {
        final data = jsonDecode(response.body);
        message = data['message'] ?? message;
      } catch (_) {}
      throw Exception(message);
    }

    final ext = format == 'csv' ? 'csv' : 'xlsx';
    final mime = format == 'csv'
        ? 'text/csv'
        : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

    final blob = html.Blob([response.bodyBytes], mime);
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: blobUrl)
      ..setAttribute('download', '$module-export.$ext')
      ..click();

    html.Url.revokeObjectUrl(blobUrl);
  }
}