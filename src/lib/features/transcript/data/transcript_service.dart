import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/transcript_result.dart';

class TranscriptService {
  const TranscriptService(this.endpoint, {http.Client? client}) : _client = client;

  final String endpoint;
  final http.Client? _client;

  Future<TranscriptResult> transcribe(String url) async {
    if (endpoint.trim().isEmpty) {
      throw const TranscriptException(
        'Backend URL is missing. Deploy the backend and pass TRANSCRIPT_API_URL at build time.',
      );
    }

    final Uri? uri = Uri.tryParse(endpoint);
    if (uri == null) {
      throw const TranscriptException('Backend URL is invalid.');
    }

    final http.Client client = _client ?? http.Client();
    try {
      final http.Response response = await client
          .post(
            uri,
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(<String, String>{'url': url}),
          )
          .timeout(const Duration(minutes: 3));

      final Map<String, dynamic> body = _decodeResponseBody(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final String transcript = (body['transcript'] ?? body['text'] ?? '').toString().trim();
        if (transcript.isEmpty) {
          throw const TranscriptException('No speech was found in this Reel.');
        }
        return TranscriptResult(transcript: transcript);
      }

      final String message = (body['detail'] ?? body['error'] ?? 'Could not generate transcript.').toString();
      throw TranscriptException(message);
    } finally {
      if (_client == null) client.close();
    }
  }

  Map<String, dynamic> _decodeResponseBody(String rawBody) {
    try {
      final Object? decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Non-JSON error responses are converted to a generic message by caller.
    }
    return <String, dynamic>{};
  }
}
