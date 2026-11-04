import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:translator/translator.dart';

Response _jsonResponse(int statusCode, Map<String, Object?> body) {
  return Response(
    statusCode,
    body: jsonEncode(body),
    headers: {'Content-Type': 'application/json; charset=utf-8'},
  );
}

Map<String, dynamic>? _readJsonObject(String body) {
  final decoded = jsonDecode(body);
  if (decoded is Map<String, dynamic>) return decoded;
  return null;
}

void main() async {
  final app = Router();
  final translator = GoogleTranslator();

  // Language mapping used for the speech-detection fallback.
  const supportedLanguages = <String, String>{
    'العربية': 'ar',
    'русский': 'ru',
    'हिंदी': 'hi',
    'English': 'en',
  };

  app.get('/health', (Request request) => Response.ok('ok'));

  app.post('/translate', (Request request) async {
    try {
      final data = _readJsonObject(await request.readAsString());
      final text = data?['text'];
      final destLangCode = data?['dest_lang_code'];

      if (text is! String || text.trim().isEmpty) {
        return _jsonResponse(400, {'error': 'Text is required.'});
      }
      if (destLangCode is! String ||
          !RegExp(r'^[a-zA-Z]{2,3}(-[a-zA-Z0-9]+)?$')
              .hasMatch(destLangCode)) {
        return _jsonResponse(400, {'error': 'A valid destination language is required.'});
      }

      final translation = await translator.translate(
        text.trim(),
        to: destLangCode,
      );
      return _jsonResponse(200, {'result': translation.text});
    } catch (error, stackTrace) {
      stderr.writeln('Translation request failed: $error\n$stackTrace');
      return _jsonResponse(502, {
        'error': 'The translation provider could not complete the request. Please try again.',
      });
    }
  });

  app.post('/detect', (Request request) async {
    try {
      final data = _readJsonObject(await request.readAsString());
      final text = data?['text'];
      if (text is! String || text.trim().isEmpty) {
        return _jsonResponse(400, {'error': 'Text is required.'});
      }

      var detectedLang = supportedLanguages['English']!;
      if (RegExp(r'[\u0600-\u06FF]').hasMatch(text)) {
        detectedLang = supportedLanguages['العربية']!;
      } else if (RegExp(r'[\u0400-\u04FF]').hasMatch(text)) {
        detectedLang = supportedLanguages['русский']!;
      } else if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) {
        detectedLang = supportedLanguages['हिंदी']!;
      }

      return _jsonResponse(200, {'language': detectedLang});
    } catch (error, stackTrace) {
      stderr.writeln('Language detection failed: $error\n$stackTrace');
      return _jsonResponse(400, {'error': 'Could not detect the language.'});
    }
  });

  app.post('/speak', (Request request) async {
    try {
      final data = _readJsonObject(await request.readAsString());
      final text = data?['text'];
      final targetLang = data?['language'] ?? supportedLanguages['English'];
      if (text is! String || text.trim().isEmpty) {
        return _jsonResponse(400, {'error': 'Text is required.'});
      }
      if (targetLang is! String ||
          !RegExp(r'^[a-zA-Z]{2,3}(-[a-zA-Z0-9]+)?$').hasMatch(targetLang)) {
        return _jsonResponse(400, {'error': 'A valid language is required.'});
      }

      final uri = Uri.https('translate.google.com', '/translate_tts', {
        'ie': 'UTF-8',
        'q': text.trim(),
        'tl': targetLang,
        'client': 'tw-ob',
      });
      final response = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      }).timeout(const Duration(seconds: 25));

      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        stderr.writeln('TTS provider returned HTTP ${response.statusCode}.');
        return _jsonResponse(502, {'error': 'The speech provider could not create audio.'});
      }

      return _jsonResponse(200, {
        'audio': 'data:audio/mp3;base64,${base64Encode(response.bodyBytes)}',
      });
    } catch (error, stackTrace) {
      stderr.writeln('Speech request failed: $error\n$stackTrace');
      return _jsonResponse(502, {'error': 'Could not generate speech audio. Please try again.'});
    }
  });

  final handler = const Pipeline()
      .addMiddleware(corsHeaders())
      .addHandler(app);

  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8000;
  await io.serve(handler, InternetAddress.anyIPv4, port);
  print('Dart Shelf backend listening on port $port');
}
