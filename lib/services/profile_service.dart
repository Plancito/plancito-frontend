import 'dart:convert';
import 'dart:developer' as developer;

import 'package:hackathon_frontend/models/user_model.dart';
import 'package:hackathon_frontend/services/base_api_service.dart';
import 'package:http/http.dart' as http;

class ProfileService extends BaseApiService {
  ProfileService();

  Future<User> fetchUser(int id) async {
    final uri = Uri.parse('$baseUrl/api/users/$id');
    final headers = await authHeaders();

    http.Response response;
    try {
      response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw ProfileException('No fue posible conectar con el servidor');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return User.fromJson(data);
    }

    if (response.statusCode == 401) {
      await handleUnauthorized();
      throw ProfileException('Sesión expirada. Por favor inicia sesión nuevamente.');
    }

    if (response.statusCode == 404) {
      throw ProfileException('Usuario no encontrado');
    }

    throw ProfileException('Error inesperado (${response.statusCode})');
  }

  Future<User> updateUser({
    required String name,
    required String lastName,
    required String city,
    String? image,
  }) async {
    final uri = Uri.parse('$baseUrl/api/users/me');
    final headers = await authHeaders();
    final payload = <String, dynamic>{
      'name': name.trim(),
      'lastName': lastName.trim(),
      'city': city.trim(),
    };

    if (image != null) {
      payload['image'] = image;
    }

    developer.log(
      'updateUser -> PUT $uri, payload keys: ${payload.keys.join(', ')}',
      name: 'ProfileService',
    );

    http.Response response;
    try {
      response = await http
          .put(uri, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw ProfileException('No fue posible conectar con el servidor');
    }

    developer.log(
      'updateUser <- status: ${response.statusCode}',
      name: 'ProfileService',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return User.fromJson(data);
    }

    if (response.statusCode == 401) {
      await handleUnauthorized();
      throw ProfileException('Sesión expirada. Por favor inicia sesión nuevamente.');
    }

    if (response.statusCode == 400 || response.statusCode == 422) {
      final decoded =
          response.body.isNotEmpty ? jsonDecode(response.body) : null;
      final message = decoded is Map<String, dynamic>
          ? decoded['message'] as String? ?? 'Datos inválidos'
          : 'Datos inválidos';
      throw ProfileException(message);
    }

    if (response.statusCode == 404) {
      throw ProfileException('Usuario no encontrado');
    }

    throw ProfileException('Error inesperado (${response.statusCode})');
  }

  Future<User> updateProfileImage({required String image}) async {
    final uri = Uri.parse('$baseUrl/api/users/me');
    final headers = await authHeaders();
    final payload = {'image': image};

    developer.log(
      'updateProfileImage -> PUT $uri',
      name: 'ProfileService',
    );

    http.Response response;
    try {
      response = await http
          .put(uri, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 30));
    } on Exception catch (e, st) {
      developer.log(
        'updateProfileImage -> error',
        name: 'ProfileService',
        error: e,
        stackTrace: st,
      );
      throw ProfileException('No fue posible conectar con el servidor');
    }

    developer.log(
      'updateProfileImage <- status: ${response.statusCode}',
      name: 'ProfileService',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return User.fromJson(data);
    }

    if (response.statusCode == 401) {
      await handleUnauthorized();
      throw ProfileException('Sesión expirada. Por favor inicia sesión nuevamente.');
    }

    if (response.statusCode == 400 || response.statusCode == 422) {
      final decoded =
          response.body.isNotEmpty ? jsonDecode(response.body) : null;
      final message = decoded is Map<String, dynamic>
          ? decoded['message'] as String? ?? 'Datos inválidos'
          : 'Datos inválidos';
      throw ProfileException(message);
    }

    if (response.statusCode == 404) {
      throw ProfileException('Usuario no encontrado');
    }

    if (response.statusCode == 413) {
      throw ProfileException('La imagen es demasiado grande');
    }

    throw ProfileException('Error inesperado (${response.statusCode})');
  }
}

class ProfileException implements Exception {
  ProfileException(this.message);

  final String message;

  @override
  String toString() => message;
}
