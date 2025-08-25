import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer' as developer;

class AuthHelper {
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';
  static const String _decodedTokenKey = 'decoded_token';

  static void _log(String message) {
    developer.log(message, name: 'AuthHelper');
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString(_tokenKey);
      _log(
        'Checking login status - Token exists: ${token != null && token.isNotEmpty}',
      );

      if (token != null && token.isNotEmpty) {
        // Check if token is expired
        try {
          final decodedToken = await getDecodedToken();
          if (decodedToken?.expiry != null) {
            final isExpired = DateTime.now().isAfter(decodedToken!.expiry!);
            _log('Token expiry check - Expired: $isExpired');
            if (isExpired) {
              await logout();
              return false;
            }
          }
          return true;
        } catch (e) {
          _log('Error checking token expiry: $e');
          return true; // If we can't check expiry, assume it's valid
        }
      }
      return false;
    } catch (e) {
      _log('Error checking login status: $e');
      return false;
    }
  }

  /// Save JWT token and user data
  static Future<void> saveAuthData(AuthResponse authResponse) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      _log('Saving auth data - Token: ${authResponse.token.isNotEmpty}');

      // Save token
      bool tokenSaved = await prefs.setString(_tokenKey, authResponse.token);
      _log('Token saved: $tokenSaved');

      // Save user data
      if (authResponse.user != null) {
        String userJson = jsonEncode(authResponse.user!.toJson());
        bool userSaved = await prefs.setString(_userKey, userJson);
        _log('User data saved: $userSaved');
      }

      // Save decoded token data
      if (authResponse.decodedToken != null) {
        String decodedJson = jsonEncode(authResponse.decodedToken!.toJson());
        bool decodedSaved = await prefs.setString(
          _decodedTokenKey,
          decodedJson,
        );
        _log('Decoded token saved: $decodedSaved');
      }

      // Verify data was saved
      await Future.delayed(const Duration(milliseconds: 100));
      String? savedToken = prefs.getString(_tokenKey);
      _log(
        'Verification - Token retrieved: ${savedToken != null && savedToken.isNotEmpty}',
      );
    } catch (e) {
      _log('Error saving auth data: $e');
      rethrow;
    }
  }

  /// Get stored JWT token
  static Future<String?> getToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString(_tokenKey);
      _log('Retrieved token: ${token != null && token.isNotEmpty}');
      return token;
    } catch (e) {
      _log('Error getting token: $e');
      return null;
    }
  }

  /// Get stored user data
  static Future<User?> getUser() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userData = prefs.getString(_userKey);
      if (userData != null && userData.isNotEmpty) {
        _log('Retrieved user data successfully');
        return User.fromJson(jsonDecode(userData));
      }
      _log('No user data found');
      return null;
    } catch (e) {
      _log('Error getting user data: $e');
      return null;
    }
  }

  /// Get stored decoded token data
  static Future<DecodedToken?> getDecodedToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? decodedData = prefs.getString(_decodedTokenKey);
      if (decodedData != null && decodedData.isNotEmpty) {
        _log('Retrieved decoded token successfully');
        return DecodedToken.fromJson(jsonDecode(decodedData));
      }
      _log('No decoded token found');
      return null;
    } catch (e) {
      _log('Error getting decoded token: $e');
      return null;
    }
  }

  /// Logout and clear all stored data
  static Future<void> logout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      bool tokenRemoved = await prefs.remove(_tokenKey);
      bool userRemoved = await prefs.remove(_userKey);
      bool decodedRemoved = await prefs.remove(_decodedTokenKey);

      _log(
        'Logout - Token removed: $tokenRemoved, User removed: $userRemoved, Decoded removed: $decodedRemoved',
      );
    } catch (e) {
      _log('Error during logout: $e');
    }
  }

  /// Debug method to check all stored data
  static Future<void> debugPrintStoredData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      Set<String> keys = prefs.getKeys();
      _log('All SharedPreferences keys: $keys');

      String? token = prefs.getString(_tokenKey);
      String? user = prefs.getString(_userKey);
      String? decoded = prefs.getString(_decodedTokenKey);

      _log(
        'Stored token: ${token?.substring(0, token.length > 20 ? 20 : token.length)}...',
      );
      _log('Stored user: ${user != null ? 'exists' : 'null'}');
      _log('Stored decoded: ${decoded != null ? 'exists' : 'null'}');
    } catch (e) {
      _log('Error in debug print: $e');
    }
  }
}

class AuthResponse {
  final String token;
  final bool success;
  final String message;
  final User? user;
  final DecodedToken? decodedToken;

  AuthResponse({
    required this.token,
    this.success = true,
    this.message = '',
    this.user,
    this.decodedToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      decodedToken: json['decodedToken'] != null
          ? DecodedToken.fromJson(json['decodedToken'])
          : null,
    );
  }

  AuthResponse copyWith({
    String? token,
    bool? success,
    String? message,
    User? user,
    DecodedToken? decodedToken,
  }) {
    return AuthResponse(
      token: token ?? this.token,
      success: success ?? this.success,
      message: message ?? this.message,
      user: user ?? this.user,
      decodedToken: decodedToken ?? this.decodedToken,
    );
  }
}

class User {
  final String id;
  final String fullName;
  final String email;
  final String role;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'fullName': fullName, 'email': email, 'role': role};
  }
}

class DecodedToken {
  final String name;
  final String email;
  final String role;
  final String consumerId;
  final String branchId;
  final DateTime? expiry;

  DecodedToken({
    required this.name,
    required this.email,
    required this.role,
    required this.consumerId,
    required this.branchId,
    this.expiry,
  });

  factory DecodedToken.fromJson(Map<String, dynamic> json) {
    return DecodedToken(
      name:
          json["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"]
              ?.toString() ??
          json["name"]?.toString() ??
          '',
      email:
          json["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"]
              ?.toString() ??
          json["email"]?.toString() ??
          '',
      role:
          json["http://schemas.microsoft.com/ws/2008/06/identity/claims/role"]
              ?.toString() ??
          json["role"]?.toString() ??
          '',
      consumerId: json["ConsumerId"]?.toString() ?? '',
      branchId: json["BranchId"]?.toString() ?? '',
      expiry: json['exp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['exp'] as num).toInt() * 1000,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'ConsumerId': consumerId,
      'BranchId': branchId,
      'exp': expiry?.millisecondsSinceEpoch != null
          ? (expiry!.millisecondsSinceEpoch / 1000).round()
          : null,
    };
  }
}
