import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/auth_model.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  static const String baseUrl = 'https://api.teknolojiport.com/api';
  static const Duration timeoutDuration = Duration(seconds: 30);

  static void _log(String message) {
    developer.log(message, name: 'SubscriptionService');
  }

  /// Get available subscription plans
  static Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    try {
      _log('Fetching subscription plans');

      final token = await AuthHelper.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/subscription/plans'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(timeoutDuration);

      _log('Subscription plans response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        
        List<dynamic> plansData;
        if (responseData is List) {
          plansData = responseData;
        } else if (responseData is Map<String, dynamic>) {
          plansData = responseData['data'] as List<dynamic>? ?? 
                     responseData['plans'] as List<dynamic>? ?? 
                     [responseData];
        } else {
          throw Exception('Unexpected response format');
        }

        final plans = plansData
            .where((json) => json != null)
            .map((json) => SubscriptionPlan.fromJson(json as Map<String, dynamic>))
            .toList();

        _log('Successfully fetched ${plans.length} subscription plans');
        return plans;
      } else {
        // Return mock data for development
        return _getMockPlans();
      }
    } catch (e) {
      _log('Get subscription plans exception: $e');
      // Return mock data for development
      return _getMockPlans();
    }
  }

  /// Get user's current subscription
  static Future<UserSubscription?> getUserSubscription() async {
    try {
      _log('Fetching user subscription');

      final token = await AuthHelper.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/subscription/user'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(timeoutDuration);

      _log('User subscription response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        
        if (responseData == null) return null;
        
        Map<String, dynamic>? subscriptionData;
        if (responseData is Map<String, dynamic>) {
          subscriptionData = responseData;
        } else if (responseData is List && responseData.isNotEmpty) {
          subscriptionData = responseData.first as Map<String, dynamic>;
        }

        if (subscriptionData != null) {
          final subscription = UserSubscription.fromJson(subscriptionData);
          _log('Successfully fetched user subscription: ${subscription.id}');
          return subscription;
        }
      } else if (response.statusCode == 404) {
        _log('No active subscription found');
        return null;
      }

      return null;
    } catch (e) {
      _log('Get user subscription exception: $e');
      return null;
    }
  }

  /// Purchase a subscription plan
  static Future<bool> purchaseSubscription({
    required String planId,
    required String paymentMethodId,
  }) async {
    try {
      _log('Purchasing subscription: $planId');

      final token = await AuthHelper.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final requestBody = {
        'planId': planId,
        'paymentMethodId': paymentMethodId,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/subscription/purchase'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      ).timeout(timeoutDuration);

      _log('Purchase subscription response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _log('Successfully purchased subscription');
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = errorData['message']?.toString() ?? 
                             'Failed to purchase subscription';
        throw Exception(errorMessage);
      }
    } catch (e) {
      _log('Purchase subscription exception: $e');
      rethrow;
    }
  }

  /// Get available payment methods
  static List<PaymentMethod> getPaymentMethods() {
    return [
      PaymentMethod(
        id: 'credit_card',
        name: 'Kredi Kartı',
        icon: '💳',
      ),
      PaymentMethod(
        id: 'debit_card',
        name: 'Banka Kartı',
        icon: '💳',
      ),
      PaymentMethod(
        id: 'paypal',
        name: 'PayPal',
        icon: '🅿️',
        isEnabled: false,
      ),
      PaymentMethod(
        id: 'apple_pay',
        name: 'Apple Pay',
        icon: '🍎',
        isEnabled: false,
      ),
    ];
  }

  /// Mock data for development
  static List<SubscriptionPlan> _getMockPlans() {
    return [
      SubscriptionPlan(
        id: '1',
        name: 'Temel Plan',
        description: 'Başlangıç seviyesi için ideal',
        price: 99,
        durationDays: 30,
        maxEntries: 15,
        features: [
          '15 salon girişi',
          'Temel antrenman programları',
          'Mobil uygulama erişimi',
        ],
      ),
      SubscriptionPlan(
        id: '2',
        name: 'Premium Plan',
        description: 'En popüler seçim',
        price: 199,
        durationDays: 30,
        maxEntries: null, // unlimited
        features: [
          'Sınırsız salon girişi',
          'Tüm antrenman programları',
          'Kişisel antrenör desteği',
          'Beslenme planı',
          'Grup dersleri',
        ],
        isPopular: true,
      ),
      SubscriptionPlan(
        id: '3',
        name: 'Yıllık Premium',
        description: '2 ay ücretsiz!',
        price: 1999,
        durationDays: 365,
        maxEntries: null,
        features: [
          'Sınırsız salon girişi',
          'Tüm antrenman programları',
          'Kişisel antrenör desteği',
          'Beslenme planı',
          'Grup dersleri',
          'VIP soyunma odası',
          '2 ay ücretsiz',
        ],
      ),
    ];
  }
}