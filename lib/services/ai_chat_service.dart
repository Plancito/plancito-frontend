import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:hackathon_frontend/models/ai_audio_reply.dart';
import 'package:hackathon_frontend/services/base_api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AIChatService extends BaseApiService {
  AIChatService();

  static const Set<String> _allowedAudioExtensions = {
    '.mp3',
    '.wav',
    '.webm',
    '.ogg',
    '.m4a',
    '.flac',
    '.aac',
  };

  Future<AIChatReply> sendMessage({
    required String prompt,
    String? conversationId,
  }) async {
    final headers = await authHeaders();

    final uri = Uri.parse('$baseUrl/api/ai/chat');

    final payload = <String, dynamic>{'message': prompt.trim()};

    if (conversationId != null && conversationId.isNotEmpty) {
      payload['conversationId'] = conversationId;
    }

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));
    } on Exception {
      throw AIChatException('No fue posible conectar con el servidor');
    }

    if (response.statusCode == 401) {
      await handleUnauthorized();
      throw AIChatException('Sesión expirada. Por favor inicia sesión nuevamente.');
    }

    if (response.statusCode == 200) {
      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
      return _parseResponse(decoded);
    }

    if (response.statusCode == 400 || response.statusCode == 422) {
      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
      final message = decoded is Map<String, dynamic>
          ? decoded['message'] as String? ?? 'Solicitud inválida'
          : 'Solicitud inválida';
      throw AIChatException(message);
    }

    throw AIChatException('Error inesperado (${response.statusCode})');
  }

  Future<AIAudioReply> sendAudioMessage({
    required String audioFilePath,
    String? fileName,
    String? conversationId,
    bool resetConversation = false,
  }) async {
    if (audioFilePath.trim().isEmpty) {
      throw AIChatException('Ruta del archivo de audio requerida');
    }

    final audioFile = File(audioFilePath);
    if (!audioFile.existsSync()) {
      throw AIChatException('Archivo de audio no encontrado');
    }

    final fileSize = audioFile.lengthSync();
    if (fileSize > 10 * 1024 * 1024) {
      throw AIChatException('El archivo de audio supera el límite de 10 MB');
    }

    final lowerPath = audioFilePath.toLowerCase();
    final lowerFileName = (fileName ?? '').toLowerCase();
    final hasValidExtension = _allowedAudioExtensions.any(
      (extension) =>
          lowerPath.endsWith(extension) || lowerFileName.endsWith(extension),
    );

    if (!hasValidExtension) {
      throw AIChatException(
        'Formato de audio no soportado. Usa uno de los siguientes: MP3, WAV, WebM, OGG, M4A, FLAC o AAC.',
      );
    }

    developer.log(
      'Enviando audio: path=$audioFilePath size=$fileSize conversation=${conversationId ?? 'new'} reset=$resetConversation',
      name: 'AIChatService.sendAudioMessage',
    );

    final token = (await authHeaders())['Authorization']?.replaceFirst('Bearer ', '') ?? '';

    final uri = Uri.parse('$baseUrl/api/ai/audio');

    final defaultFileName = audioFile.uri.pathSegments.isNotEmpty
        ? audioFile.uri.pathSegments.last
        : 'audio';
    final resolvedFileName = (fileName != null && fileName.isNotEmpty)
        ? fileName
        : defaultFileName;

    String? detectMimeType(String path) {
      final lower = path.toLowerCase();
      if (lower.endsWith('.mp3')) return 'audio/mpeg';
      if (lower.endsWith('.wav')) return 'audio/wav';
      if (lower.endsWith('.webm')) return 'audio/webm';
      if (lower.endsWith('.ogg')) return 'audio/ogg';
      if (lower.endsWith('.m4a')) return 'audio/mp4';
      if (lower.endsWith('.flac')) return 'audio/flac';
      if (lower.endsWith('.aac')) return 'audio/aac';
      return null;
    }

    final contentType =
        detectMimeType(resolvedFileName) ?? detectMimeType(audioFilePath);

    http.StreamedResponse streamedResponse;
    try {
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(
          await http.MultipartFile.fromPath(
            'audio',
            audioFilePath,
            filename: resolvedFileName,
            contentType: contentType != null
                ? MediaType.parse(contentType)
                : null,
          ),
        );

      if (conversationId != null && conversationId.isNotEmpty) {
        request.fields['conversationId'] = conversationId;
      }

      if (resetConversation) {
        request.fields['resetConversation'] = 'true';
      }

      streamedResponse = await request.send().timeout(
        const Duration(seconds: 45),
      );
    } on Exception {
      throw AIChatException('No fue posible conectar con el servidor');
    }

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 401) {
      await handleUnauthorized();
      throw AIChatException('Sesión expirada. Por favor inicia sesión nuevamente.');
    }

    if (response.statusCode == 200) {
      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
      return _parseAudioResponse(decoded);
    }

    if (response.statusCode == 400 || response.statusCode == 422) {
      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
      final message = decoded is Map<String, dynamic>
          ? decoded['message'] as String? ?? 'Solicitud inválida'
          : 'Solicitud inválida';
      throw AIChatException(message);
    }

    throw AIChatException('Error inesperado (${response.statusCode})');
  }

  Future<AIAudioReply> sendAudioFromUrl({
    required String audioUrl,
    String? fileName,
    String? conversationId,
    bool resetConversation = false,
  }) async {
    if (audioUrl.trim().isEmpty) {
      throw AIChatException('URL del archivo de audio requerida');
    }

    final token = (await authHeaders())['Authorization']?.replaceFirst('Bearer ', '') ?? '';

    final uri = Uri.parse('$baseUrl/api/ai/audio');

    final resolvedFileName = (fileName != null && fileName.isNotEmpty)
        ? fileName
        : 'audio.webm';

    http.StreamedResponse streamedResponse;
    try {
      final audioBytes = await http.readBytes(Uri.parse(audioUrl));

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(
          http.MultipartFile.fromBytes(
            'audio',
            audioBytes,
            filename: resolvedFileName,
            contentType: MediaType('audio', 'webm'),
          ),
        );

      if (conversationId != null && conversationId.isNotEmpty) {
        request.fields['conversationId'] = conversationId;
      }

      if (resetConversation) {
        request.fields['resetConversation'] = 'true';
      }

      streamedResponse = await request.send().timeout(
        const Duration(seconds: 45),
      );
    } on Exception {
      throw AIChatException('No fue posible conectar con el servidor');
    }

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 401) {
      await handleUnauthorized();
      throw AIChatException('Sesión expirada. Por favor inicia sesión nuevamente.');
    }

    if (response.statusCode == 200) {
      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
      return _parseAudioResponse(decoded);
    }

    if (response.statusCode == 400 || response.statusCode == 422) {
      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
      final message = decoded is Map<String, dynamic>
          ? decoded['message'] as String? ?? 'Solicitud inválida'
          : 'Solicitud inválida';
      throw AIChatException(message);
    }

    throw AIChatException('Error inesperado (${response.statusCode})');
  }

  AIChatReply _parseResponse(dynamic decoded) {
    if (decoded is String) {
      return AIChatReply(message: decoded);
    }

    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) {
        return AIChatReply(message: message);
      }

      final success = decoded['success'];
      if (success is bool && success) {
        final data = decoded['data'];
        if (data is Map<String, dynamic>) {
          final response = data['response'];
          final conversationId = data['conversationId'];
          if (response is String && response.trim().isNotEmpty) {
            return AIChatReply(
              message: response,
              conversationId: conversationId is String ? conversationId : null,
            );
          }
        }
      }
    }

    throw AIChatException('Respuesta inválida del servidor');
  }

  AIAudioReply _parseAudioResponse(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      return AIAudioReply.fromJson(decoded);
    }

    throw AIChatException('Respuesta inválida del servidor');
  }
}

class AIChatException implements Exception {
  AIChatException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AIChatReply {
  const AIChatReply({required this.message, this.conversationId});

  final String message;
  final String? conversationId;
}
