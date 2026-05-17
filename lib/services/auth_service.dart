import 'dart:convert';
import 'dart:developer' as developer;

import 'package:hackathon_frontend/models/user_model.dart';
import 'package:hackathon_frontend/services/base_api_service.dart';
import 'package:http/http.dart' as http;

class AuthService extends BaseApiService {
  AuthService();

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    developer.log('[AuthService] baseUrl: $baseUrl');

    final uri = Uri.parse('$baseUrl/api/auth/login');
    developer.log('[AuthService] uri: $uri');

    http.Response response;
    try {
      developer.log('[AuthService] Enviando POST a: $uri');
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));
      developer.log('[AuthService] Response status: ${response.statusCode}');
      developer.log('[AuthService] Response body: ${response.body}');
    } on Exception catch (e, st) {
      developer.log('[AuthService] Exception: $e', error: e, stackTrace: st);
      throw AuthException('No fue posible conectar con el servidor');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;

      if (token == null || userData == null) {
        throw AuthException('Respuesta inválida del servidor');
      }

      return AuthResponse(token: token, user: User.fromJson(userData));
    }

    if (response.statusCode == 400 || response.statusCode == 401) {
      throw AuthException('Credenciales inválidas');
    }

    throw AuthException('Error inesperado (${response.statusCode})');
  }

  Future<AuthResponse> signup({
    required String name,
    required String lastName,
    required String email,
    required String password,
    required String birthDate,
    required String gender,
    required String city,
    required String country,
  }) async {
    developer.log('[AuthService] signup baseUrl: $baseUrl');

    final uri = Uri.parse('$baseUrl/api/auth/signup');
    developer.log('[AuthService] signup uri: $uri');

    http.Response response;
    final payload = <String, dynamic>{
      'name': name,
      'lastName': lastName,
      'email': email,
      'password': password,
      'birthDate': birthDate,
      'gender': gender,
      'city': city,
      'country': country,
    };
    developer.log('[AuthService] signup payload keys: ${payload.keys.join(', ')}');
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));
      developer.log('[AuthService] signup response status: ${response.statusCode}');
      developer.log('[AuthService] signup response body: ${response.body}');
    } on Exception catch (e, st) {
      developer.log('[AuthService] signup Exception: $e', error: e, stackTrace: st);
      throw AuthException('No fue posible conectar con el servidor');
    }

    developer.log('[AuthService] signup final status: ${response.statusCode}');
    developer.log('[AuthService] signup final body: ${response.body}');
    if (response.statusCode == 201 || response.statusCode == 200) {
      if (response.body.isNotEmpty) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          developer.log('[AuthService] signup decoded data: $data');
          final token = data['token'] as String?;
          final userData = data['user'] as Map<String, dynamic>?;

          if (token != null && userData != null) {
            return AuthResponse(
              token: token,
              user: User.fromJson(userData),
            );
          }
        } on FormatException catch (e, st) {
          developer.log('[AuthService] signup FormatException: $e', error: e, stackTrace: st);
          throw AuthException('Respuesta de signup no es JSON');
        }
      }

      return login(email: email, password: password);
    }

    if (response.statusCode == 400 || response.statusCode == 409) {
      developer.log('[AuthService] signup error: No fue posible registrar la cuenta');
      throw AuthException('No fue posible registrar la cuenta');
    }

    developer.log('[AuthService] signup error inesperado: ${response.statusCode}');
    throw AuthException('Error inesperado (${response.statusCode})');
  }
}

class AuthResponse {
  AuthResponse({required this.token, required this.user});

  final String token;
  final User user;
}

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
