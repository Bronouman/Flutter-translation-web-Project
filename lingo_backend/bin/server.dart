import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:translator/translator.dart';

Response _json(int status, Map<String, Object?> body) => Response(
      status,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> _decodeObject(String body) {
  final decoded = jsonDecode(body);
  if (decoded is Map<String, dynamic>) return decoded;
  throw const FormatException('Expected a JSON object.');
}

void main() async {
  final app = Router();
  final translator = GoogleTranslator();

  const supportedLanguages = <String, String>{
    'العربية': 'ar',
    'русский': 'ru',
    'हिंदी': 'hi',
    'English': 'en',
  };

  app.get('/health', (Request request) => Response.ok('ok'));

  app.post('/translate', (Request request) async {
    try {
      final data = _decodeObject(await request.readAsString());
      final text = data['text'];
      final destination = data['dest_lang_code'];
      if (text is! String || text.trim().isEmpty) {
        return _json(400, {'error': 'Please enter text to translate.'});
      }
      if (destination is! String ||
          !RegExp(r'^[a-zA-Z]{2,3}(-[a-zA-Z0-9]+)?$').hasMatch(destination)) {
        return _json(400, {'error': 'Please select a valid target language.'});
      }

      final result = await translator
          .translate(text.trim(), to: destination)
          .timeout(const Duration(seconds: 60));
      return _json(200, {'result': result.text});
    } catch (error, stackTrace) {
      stderr.writeln('Translation failed: $error\n$stackTrace');
      return _json(502, {
        'error': 'Translation service is temporarily unavailable. Please try again shortly.'
      });
    }
  });

  app.post('/detect', (Request request) async {
    try {
      final data = _decodeObject(await request.readAsString());
      final text = data['text'];
      if (text is! String || text.trim().isEmpty) {
        return _json(400, {'error': 'Please enter text to detect.'});
      }

      var language = supportedLanguages['English']!;
      if (RegExp(r'[\u0600-\u06FF]').hasMatch(text)) {
        language = supportedLanguages['العربية']!;
      } else if (RegExp(r'[\u0400-\u04FF]').hasMatch(text)) {
        language = supportedLanguages['русский']!;
      } else if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) {
        language = supportedLanguages['हिंदी']!;
      }
      return _json(200, {'language': language});
    } catch (error, stackTrace) {
      stderr.writeln('Language detection failed: $error\n$stackTrace');
      return _json(400, {'error': 'Could not detect the language.'});
    }
  });

  app.post('/speak', (Request request) async {
    try {
      final data = _decodeObject(await request.readAsString());
      final text = data['text'];
      final language = data['language'] ?? 'en';
      if (text is! String || text.trim().isEmpty) {
        return _json(400, {'error': 'Please enter text to speak.'});
      }
      if (language is! String ||
          !RegExp(r'^[a-zA-Z]{2,3}(-[a-zA-Z0-9]+)?$').hasMatch(language)) {
        return _json(400, {'error': 'Please select a valid language.'});
      }

      final uri = Uri.https('translate.google.com', '/translate_tts', {
        'ie': 'UTF-8',
        'q': text.trim(),
        'tl': language,
        'client': 'tw-ob',
      });
      final response = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      }).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        stderr.writeln('TTS provider returned HTTP ${response.statusCode}.');
        return _json(502, {'error': 'The speech service could not generate audio.'});
      }
      return _json(200, {
        'audio': 'data:audio/mp3;base64,${base64Encode(response.bodyBytes)}',
      });
    } catch (error, stackTrace) {
      stderr.writeln('Speech generation failed: $error\n$stackTrace');
      return _json(502, {'error': 'Speech service is temporarily unavailable.'});
    }
  });

  final handler = const Pipeline()
      .addMiddleware(corsHeaders())
      .addHandler(app);
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8000;
  await io.serve(handler, InternetAddress.anyIPv4, port);
  print('Dart Shelf backend listening on port $port');
}
