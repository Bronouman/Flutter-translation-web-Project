import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:translator/translator.dart';
import 'package:http/http.dart' as http;

void main() async {
  final app = Router();
  final translator = GoogleTranslator();

  // Language mapping for detection fallback
  final Map<String, String> supportedLanguages = {
    "العربية": "ar",
    "русский": "ru",
    "हिंदी": "hi",
    "English": "en"
  };

  // 1. Translate Endpoint
  app.post('/translate', (Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);
      final text = data['text'];
      final destLangCode = data['dest_lang_code'];

      final translation = await translator.translate(text, to: destLangCode);

      return Response.ok(
        jsonEncode({'result': translation.text}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Translation failed'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  // 2. Language Detection Endpoint
  app.post('/detect', (Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);
      final text = data['text'] as String?;

      String detectedLang = supportedLanguages['English']!;

      if (text != null && text.isNotEmpty) {
        if (RegExp(r'[\u0600-\u06FF]').hasMatch(text)) {
          detectedLang = supportedLanguages['العربية']!;
        } else if (RegExp(r'[\u0400-\u04FF]').hasMatch(text)) {
          detectedLang = supportedLanguages['русский']!;
        } else if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) {
          detectedLang = supportedLanguages['हिंदी']!;
        }
      }

      return Response.ok(
        jsonEncode({'language': detectedLang}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Detection failed'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  // 3. Speech Synthesis (TTS) Base64 Audio Generator Endpoint
  app.post('/speak', (Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);
      final text = data['text'];
      final targetLang = data['language'] ?? supportedLanguages['English'];

      final encodedText = Uri.encodeComponent(text);
      final url = 'https://translate.google.com/translate_tts?ie=UTF-8&q=$encodedText&tl=$targetLang&client=tw-ob';

      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
      });

      if (response.statusCode != 200) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to fetch audio from TTS provider'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final base64Audio = base64Encode(response.bodyBytes);

      return Response.ok(
        jsonEncode({'audio': 'data:audio/mp3;base64,$base64Audio'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Audio generation failed'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  // Middleware pipeline with full CORS support
  final handler = const Pipeline()
      .addMiddleware(corsHeaders())
      .addHandler(app);

  final port = 8000;
  await io.serve(handler, InternetAddress.anyIPv4, port);
  print('Dart Shelf Backend server active on http://localhost:$port');
}
