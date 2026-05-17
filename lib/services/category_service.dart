import 'dart:convert';

import 'package:hackathon_frontend/models/category_model.dart';
import 'package:hackathon_frontend/services/base_api_service.dart';
import 'package:http/http.dart' as http;

class CategoryService extends BaseApiService {
  CategoryService();

  Future<List<Category>> fetchCategories() async {
    final headers = await authHeaders();

    final uri = Uri.parse('$baseUrl/api/categories');

    http.Response response;
    try {
      response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw CategoryException('No fue posible conectar con el servidor');
    }

    if (response.statusCode == 401) {
      await handleUnauthorized();
      throw CategoryException('Sesión expirada. Por favor inicia sesión nuevamente.');
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      return data.map((item) => Category.fromJson(item as Map<String, dynamic>)).toList();
    }

    throw CategoryException('Failed to load categories');
  }
}

class CategoryException implements Exception {
  CategoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
