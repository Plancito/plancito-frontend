import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hackathon_frontend/utils/app_navigator.dart';
import 'package:hackathon_frontend/utils/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstract base for all API services.
///
/// Provides shared [baseUrl], [authHeaders], and session-expiry handling.
/// When a 401 is received, call [handleUnauthorized] to clear stored
/// credentials and trigger [onSessionExpired] (set once in main.dart).
abstract class BaseApiService {
  /// Override this callback in main.dart to navigate to the login screen.
  static VoidCallback? onSessionExpired;

  String get baseUrl =>
      (dotenv.env['API_BASE_URL'] ?? 'https://hackathon-back-theta.vercel.app')
          .trim();

  Future<Map<String, String>> authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(StorageKeys.token) ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Call when any endpoint returns HTTP 401.
  /// Clears stored credentials and navigates to the login screen.
  Future<void> handleUnauthorized() async {
    developer.log('Session expired — clearing credentials', name: 'BaseApiService');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.token);
    await prefs.remove(StorageKeys.userId);
    await prefs.remove(StorageKeys.userRole);

    final callback = onSessionExpired;
    if (callback != null) {
      callback();
    } else {
      // Fallback: pop all routes and let root FutureBuilder re-evaluate.
      final state = appNavigatorKey.currentState;
      if (state != null) {
        unawaited(state.pushNamedAndRemoveUntil('/', (_) => false));
      }
    }
  }
}
