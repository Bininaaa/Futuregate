import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../models/payment_model.dart';
import '../models/premium_config_model.dart';

class ChargilyPaymentService {
  static const String _workerBase = String.fromEnvironment(
    'WORKER_BASE_URL',
    defaultValue: 'https://avenirdz-api.yasserabh13.workers.dev',
  );

  Future<String?> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      return await user.getIdToken();
    } catch (_) {
      return null;
    }
  }

  Future<CheckoutResult> createCheckout({
    required PremiumConfigModel config,
  }) async {
    final token = await _getIdToken();
    if (token == null) {
      return CheckoutResult.error('Not authenticated. Please sign in again.');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_workerBase/api/subscriptions/chargily/create-checkout'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'plan': config.premiumPlan}),
          )
          .timeout(const Duration(seconds: 30));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final url = (body['checkoutUrl'] ?? body['checkout_url'] ?? '')
            .toString();
        final checkoutId = (body['checkoutId'] ?? '').toString();
        if (url.isEmpty) {
          return CheckoutResult.error('No checkout URL received from server.');
        }
        return CheckoutResult.success(
          checkoutUrl: url,
          checkoutId: checkoutId,
        );
      }

      final message = (body['error'] ?? 'Payment setup failed.').toString();
      return CheckoutResult.error(message);
    } on http.ClientException catch (e) {
      return CheckoutResult.error('Network error: ${e.message}');
    } catch (e) {
      return CheckoutResult.error('Could not start payment. Please try again.');
    }
  }

  Future<PaymentModel?> getPaymentByCheckout(String checkoutId) async {
    if (checkoutId.isEmpty) return null;
    final token = await _getIdToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_workerBase/api/payments/$checkoutId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return PaymentModel.fromMap(body);
      }
    } catch (_) {}
    return null;
  }

  Future<bool> syncSubscription() async {
    final token = await _getIdToken();
    if (token == null) return false;
    try {
      final response = await http
          .post(
            Uri.parse('$_workerBase/api/subscriptions/sync'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 20));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

class CheckoutResult {
  final bool ok;
  final String? checkoutUrl;
  final String? checkoutId;
  final String? errorMessage;

  CheckoutResult._({
    required this.ok,
    this.checkoutUrl,
    this.checkoutId,
    this.errorMessage,
  });

  factory CheckoutResult.success({
    required String checkoutUrl,
    required String checkoutId,
  }) {
    return CheckoutResult._(
      ok: true,
      checkoutUrl: checkoutUrl,
      checkoutId: checkoutId,
    );
  }

  factory CheckoutResult.error(String message) {
    return CheckoutResult._(ok: false, errorMessage: message);
  }
}
