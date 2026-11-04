import 'dart:convert';

import 'package:http/http.dart' as http;

const String _renderUrl = 'https://lingo-backend.onrender.com';

class ApiMessages {
  final String nonJson;
  final String unexpected;
  final String failed;
  final String network;

  const ApiMessages({
    required this.nonJson,
    required this.unexpected,
    required this.failed,
    required this.network,
  });

  static const ApiMessages english = ApiMessages(
    nonJson:
        'API returned a non-JSON response (HTTP {status}). Please try again shortly.',
    unexpected: 'Unexpected API response (HTTP {status}).',
    failed: 'Request failed (HTTP {status}).',
    network:
        'Could not reach the server. Check your internet connection and try again.',
  );

  static const ApiMessages arabic = ApiMessages(
    nonJson: 'تعذرت قراءة استجابة الخادم (HTTP {status}). حاول مرة أخرى بعد قليل.',
    unexpected: 'وصلت استجابة غير متوقعة من الخادم (HTTP {status}).',
    failed: 'فشل الطلب (HTTP {status}).',
    network: 'تعذر الاتصال بالخادم. تحقق من اتصالك بالإنترنت وحاول مرة أخرى.',
  );
}

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

// Production: same-origin Vercel proxy first (avoids CORS), then Render
// directly as a fallback (the backend sends CORS headers).
List<String> _backendBases() {
  final host = Uri.base.host;
  if (host.isEmpty || host == 'localhost' || host == '127.0.0.1') {
    return ['http://localhost:8000', _renderUrl];
  }
  return [Uri.base.resolve('/api').toString(), _renderUrl];
}

Future<Map<String, dynamic>> apiPostJson(
  String path,
  Map<String, Object?> body, {
  ApiMessages messages = ApiMessages.english,
}) async {
  final payload = jsonEncode(body);
  var lastError = messages.network;

  for (var attempt = 0; attempt < 2; attempt++) {
    if (attempt > 0) await Future<void>.delayed(const Duration(seconds: 5));

    for (final base in _backendBases()) {
      final http.Response response;
      try {
        response = await http
            .post(
              Uri.parse('$base$path'),
              headers: {'Content-Type': 'application/json'},
              body: payload,
            )
            .timeout(const Duration(seconds: 45));
      } on Object {
        lastError = messages.network;
        continue;
      }

      final status = response.statusCode;
      Object? decoded;
      var isJson = true;
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true));
      } on FormatException {
        isJson = false;
      }

      if (!isJson) {
        lastError = messages.nonJson.replaceAll('{status}', '$status');
        continue;
      }
      if (decoded is! Map<String, dynamic>) {
        lastError = messages.unexpected.replaceAll('{status}', '$status');
        continue;
      }
      if (status < 200 || status >= 300) {
        throw ApiException(
          decoded['error']?.toString() ??
              messages.failed.replaceAll('{status}', '$status'),
        );
      }
      return decoded;
    }
  }
  throw ApiException(lastError);
}
