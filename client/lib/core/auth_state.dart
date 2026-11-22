import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'models.dart';

/// Состояние авторизации: токен + профиль, сохранение между запусками.
class AuthState extends ChangeNotifier {
  AuthState(this.api);

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  final ApiClient api;

  AppUser? user;
  bool restoring = true;

  bool get isAuthorized => api.isAuthorized;

  /// Вызывается один раз при старте приложения.
  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final cachedUser = prefs.getString(_userKey);

      if (token != null && token.isNotEmpty) {
        api.token = token;
        if (cachedUser != null) {
          user = AppUser.fromJson(jsonDecode(cachedUser) as Map<String, dynamic>);
        }

        try {
          user = await api.me();
          await _persist();
        } on ApiException catch (error) {
          if (error.isUnauthorized) {
            await logout();
          }
        }
      }
    } finally {
      restoring = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    final result = await api.login(email, password);
    await _apply(result);
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final result = await api.register(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
    );
    await _apply(result);
  }

  Future<void> updateProfile({required String fullName, required String phone}) async {
    user = await api.updateProfile(fullName: fullName, phone: phone);
    await _persist();
    notifyListeners();
  }

  Future<void> logout() async {
    api.token = null;
    user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    notifyListeners();
  }

  Future<void> _apply(AuthResult result) async {
    api.token = result.token;
    user = result.user;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (api.token != null) {
      await prefs.setString(_tokenKey, api.token!);
    }
    if (user != null) {
      await prefs.setString(_userKey, jsonEncode(user!.toJson()));
    }
  }
}
