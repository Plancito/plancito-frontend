import 'dart:convert';

import 'package:hackathon_frontend/models/notification_model.dart';
import 'package:hackathon_frontend/services/base_api_service.dart';
import 'package:http/http.dart' as http;

class NotificationService extends BaseApiService {
  NotificationService();

  Future<List<Notification>> fetchNotifications() async {
    final headers = await authHeaders();
    final url = Uri.parse('$baseUrl/api/notifications');

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 401) {
      await handleUnauthorized();
      throw NotificationException('Sesión expirada. Por favor inicia sesión nuevamente.');
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      return data.map((item) => Notification.fromJson(item as Map<String, dynamic>)).toList();
    }

    throw NotificationException('Failed to load notifications');
  }

  Future<void> markAllAsRead() async {
    final headers = await authHeaders();
    final url = Uri.parse('$baseUrl/api/notifications/mark-all-read');

    final response = await http.put(url, headers: headers);

    if (response.statusCode == 401) {
      await handleUnauthorized();
      throw NotificationException('Sesión expirada. Por favor inicia sesión nuevamente.');
    }

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw NotificationException('Failed to mark all notifications as read');
    }
  }
}

class NotificationException implements Exception {
  NotificationException(this.message);

  final String message;

  @override
  String toString() => message;
}
