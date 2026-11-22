import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

/// Ошибка API: человекочитаемое сообщение + ошибки валидации по полям.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.fieldErrors = const {}});

  final String message;
  final int? statusCode;
  final Map<String, List<String>> fieldErrors;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Тонкий клиент над REST API. Токен хранится в памяти и подставляется в заголовок.
class ApiClient {
  ApiClient({String? baseUrl, http.Client? httpClient})
      : baseUrl = baseUrl ?? defaultBaseUrl,
        _http = httpClient ?? http.Client();

  static const int port = 5099;
  static const Duration _timeout = Duration(seconds: 15);

  /// Адрес API по умолчанию: эмулятор Android видит хост как 10.0.2.2.
  /// Можно переопределить при запуске: --dart-define=API_BASE_URL=http://192.168.0.5:5099
  static String get defaultBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$port';
    }
    return 'http://127.0.0.1:$port';
  }

  final String baseUrl;
  final http.Client _http;
  String? token;

  bool get isAuthorized => token != null;

  // ---------- Авторизация ----------

  Future<AuthResult> login(String email, String password) async {
    final json = await _request('POST', '/api/auth/login', body: {
      'email': email,
      'password': password,
    });
    return AuthResult.fromJson(json as Map<String, dynamic>);
  }

  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final json = await _request('POST', '/api/auth/register', body: {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
    });
    return AuthResult.fromJson(json as Map<String, dynamic>);
  }

  Future<AppUser> me() async {
    final json = await _request('GET', '/api/auth/me', withAuth: true);
    return AppUser.fromJson(json as Map<String, dynamic>);
  }

  // ---------- Каталог ----------

  Future<List<ServiceCategory>> categories() async {
    final json = await _request('GET', '/api/categories') as List<dynamic>;
    return json.map((item) => ServiceCategory.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<PagedServices> services({String? query, String? categoryId, int page = 1, int pageSize = 50}) async {
    final params = <String, String>{'page': '$page', 'pageSize': '$pageSize'};
    final trimmedQuery = query?.trim() ?? '';
    if (trimmedQuery.isNotEmpty) {
      params['q'] = trimmedQuery;
    }
    if (categoryId != null) {
      params['categoryId'] = categoryId;
    }
    final path = Uri(path: '/api/services', queryParameters: params).toString();
    final json = await _request('GET', path);
    return PagedServices.fromJson(json as Map<String, dynamic>);
  }

  Future<ServiceDetails> serviceDetails(String id) async {
    final json = await _request('GET', '/api/services/$id');
    return ServiceDetails.fromJson(json as Map<String, dynamic>);
  }

  Future<ServiceSlots> slots(String serviceId, DateTime date, {String? masterId}) async {
    final params = <String, String>{'date': _dateOnly(date)};
    final onlyMaster = masterId;
    if (onlyMaster != null) {
      params['masterId'] = onlyMaster;
    }
    final path = Uri(path: '/api/services/$serviceId/slots', queryParameters: params).toString();
    final json = await _request('GET', path);
    return ServiceSlots.fromJson(json as Map<String, dynamic>);
  }

  // ---------- Записи ----------

  Future<Booking> createBooking({
    required String serviceId,
    required String masterId,
    required DateTime startAt,
    String? comment,
  }) async {
    final json = await _request('POST', '/api/bookings', withAuth: true, body: {
      'serviceId': serviceId,
      'masterId': masterId,
      'startAt': startAt.toUtc().toIso8601String(),
      'comment': comment,
    });
    return Booking.fromJson(json as Map<String, dynamic>);
  }

  Future<List<Booking>> bookings({String scope = 'all'}) async {
    final json = await _request('GET', '/api/bookings?scope=$scope', withAuth: true) as List<dynamic>;
    return json.map((item) => Booking.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Booking> cancelBooking(String id) async {
    final json = await _request('POST', '/api/bookings/$id/cancel', withAuth: true);
    return Booking.fromJson(json as Map<String, dynamic>);
  }

  // ---------- Профиль ----------

  Future<AppUser> updateProfile({required String fullName, required String phone}) async {
    final json = await _request('PUT', '/api/profile', withAuth: true, body: {
      'fullName': fullName,
      'phone': phone,
    });
    return AppUser.fromJson(json as Map<String, dynamic>);
  }

  // ---------- Внутреннее ----------

  Future<dynamic> _request(String method, String path, {Object? body, bool withAuth = false}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (withAuth && token != null) 'Authorization': 'Bearer $token',
    };
    final payload = body == null ? null : jsonEncode(body);

    http.Response response;
    try {
      response = switch (method) {
        'GET' => await _http.get(uri, headers: headers).timeout(_timeout),
        'POST' => await _http.post(uri, headers: headers, body: payload).timeout(_timeout),
        'PUT' => await _http.put(uri, headers: headers, body: payload).timeout(_timeout),
        _ => throw ArgumentError('Неподдерживаемый метод: $method'),
      };
    } on TimeoutException {
      throw ApiException('Сервер не отвечает. Проверьте, что API запущен.');
    } on http.ClientException catch (error) {
      throw ApiException('Не удалось подключиться к серверу (${error.message}).\n$baseUrl');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.bodyBytes.isEmpty) {
        return null;
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    throw _toException(response);
  }

  ApiException _toException(http.Response response) {
    final status = response.statusCode;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        final fieldErrors = <String, List<String>>{};
        final rawErrors = decoded['errors'];
        if (rawErrors is Map<String, dynamic>) {
          rawErrors.forEach((key, value) {
            if (value is List) {
              fieldErrors[key] = value.map((item) => item.toString()).toList();
            }
          });
        }

        final message = (decoded['detail'] ?? decoded['title'] ?? 'Ошибка запроса').toString();
        return ApiException(message, statusCode: status, fieldErrors: fieldErrors);
      }
    } on FormatException {
      // Ниже вернём общее сообщение.
    }

    return ApiException('Ошибка сервера ($status)', statusCode: status);
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
