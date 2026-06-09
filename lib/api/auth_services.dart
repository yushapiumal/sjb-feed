// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _tokenKey = 'token';

  /// Returns true if a token is saved (user was previously logged in)
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Clears all saved auth data (call on logout)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('member_id');
    await prefs.remove('mobile_number');
    await prefs.remove('fname');
    await prefs.remove('email');
    await prefs.remove('role');
  }

  /// Get any saved value by key
  static Future<String?> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}