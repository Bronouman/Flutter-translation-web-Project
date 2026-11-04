import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:translator/translator.dart';

const int _maxTranslateLength = 5000;
const int _translateChunkLength = 1000;
const int _maxSpeakLength = 1000;
const int _speakChunkLength = 180;

final RegExp _languageCode = RegExp(r'^[a-zA-Z]{2,3}(-[a-zA-Z0-9]+)?$');

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

Future<Map<String, dynamic>?> _readBody(Request request) async {
  try {
    return _decodeObject(await request.readAsString());
  } on FormatException {
    return null;
  }
}

Response _badBody() =>
    _json(400, {'error': 'Request body must be a valid JSON object.'});

Middleware _jsonErrors() => (Handler inner) => (Request request) async {
      try {
        return await inner(request);
      } catch (error, stackTrace) {
        stderr.writeln('Unhandled request error: $error\n$stackTrace');
        return _json(500, {'error': 'Internal server error. Please try again.'});
      }
    };

List<String> _codeCandidates(String code) {
  final lower = code.toLowerCase();
  final candidates = <String>[lower];
  if (code != lower) candidates.add(code);
  if (lower == 'iw') candidates.add('he');
  if (lower == 'he') candidates.add('iw');
  return candidates;
}

List<String> _splitText(String text, int maxLength) {
  final chunks = <String>[];
  var current = StringBuffer();

  void flush() {
    if (current.isNotEmpty) {
      chunks.add(current.toString());
      current = StringBuffer();
    }
  }

  void add(String piece) {
    if (current.length + piece.length > maxLength) flush();
    current.write(piece);
  }

  final sentences = RegExp(r'[^.!?\n。！？۔]*[.!?\n。！？۔]+|[^.!?\n。！？۔]+')
      .allMatches(text)
      .map((m) => m.group(0)!);
  for (final sentence in sentences) {
    if (sentence.length <= maxLength) {
      add(sentence);
      continue;
    }
    final words = RegExp(r'\S+\s*').allMatches(sentence).map((m) => m.group(0)!);
    for (final word in words) {
      if (word.length <= maxLength) {
        add(word);
        continue;
      }
      flush();
      final runes = word.runes.toList();
      for (var i = 0; i < runes.length; i += maxLength) {
        final end = i + maxLength < runes.length ? i + maxLength : runes.length;
        chunks.add(String.fromCharCodes(runes.sublist(i, end)));
      }
    }
  }
  flush();
  return chunks;
}

Future<String> _translateChunk(
  GoogleTranslator translator,
  String text,
  List<String> codes,
) async {
  Object? lastError;
  for (final code in List<String>.of(codes)) {
    try {
      final translation = await translator.translate(text, to: code);
      codes.remove(code);
      codes.insert(0, code);
      return translation.text;
    } catch (error) {
      lastError = error;
    }
  }
  throw lastError ?? StateError('No supported language code.');
}

Future<String> _translateText(
  GoogleTranslator translator,
  String text,
  List<String> codes,
) async {
  final output = StringBuffer();
  for (final chunk in _splitText(text, _translateChunkLength)) {
    if (chunk.trim().isEmpty) {
      output.write(chunk);
      continue;
    }
    final lead = RegExp(r'^\s*').stringMatch(chunk) ?? '';
    final trail = RegExp(r'\s*$').stringMatch(chunk) ?? '';
    final translated = await _translateChunk(translator, chunk.trim(), codes);
    output.write(lead);
    output.write(translated);
    output.write(trail);
  }
  return output.toString();
}

Future<void> _start() async {
  final app = Router(
    notFoundHandler: (Request request) =>
        _json(404, {'error': 'Route not found.'}),
  );
  final translator = GoogleTranslator();

  const supportedLanguages = <String, String>{
    'العربية': 'ar',
    'русский': 'ru',
    'हिंदी': 'hi',
    'English': 'en',
  };

  app.get('/health', (Request request) => Response.ok('ok'));

  app.post('/translate', (Request request) async {
    final data = await _readBody(request);
    if (data == null) return _badBody();
    final text = data['text'];
    final destination = data['dest_lang_code'];
    if (text is! String || text.trim().isEmpty) {
      return _json(400, {'error': 'Please enter text to translate.'});
    }
    if (text.trim().length > _maxTranslateLength) {
      return _json(400, {
        'error':
            'Text is too long. Please keep it under $_maxTranslateLength characters.'
      });
    }
    if (destination is! String || !_languageCode.hasMatch(destination)) {
      return _json(400, {'error': 'Please select a valid target language.'});
    }

    try {
      final result = await _translateText(
        translator,
        text.trim(),
        _codeCandidates(destination),
      ).timeout(const Duration(seconds: 60));
      return _json(200, {'result': result});
    } catch (error, stackTrace) {
      stderr.writeln('Translation failed: $error\n$stackTrace');
      return _json(502, {
        'error': 'Translation service is temporarily unavailable. Please try again shortly.'
      });
    }
  });

  app.post('/detect', (Request request) async {
    final data = await _readBody(request);
    if (data == null) return _badBody();
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
  });

  app.post('/speak', (Request request) async {
    final data = await _readBody(request);
    if (data == null) return _badBody();
    final text = data['text'];
    final language = data['language'] ?? 'en';
    if (text is! String || text.trim().isEmpty) {
      return _json(400, {'error': 'Please enter text to speak.'});
    }
    if (text.trim().length > _maxSpeakLength) {
      return _json(400, {
        'error':
            'Text is too long to speak. Please keep it under $_maxSpeakLength characters.'
      });
    }
    if (language is! String || !_languageCode.hasMatch(language)) {
      return _json(400, {'error': 'Please select a valid language.'});
    }

    try {
      final chunks = _splitText(text.trim(), _speakChunkLength)
          .map((chunk) => chunk.trim())
          .where((chunk) => chunk.isNotEmpty)
          .toList();
      final audio = <int>[];
      for (final chunk in chunks) {
        final uri = Uri.https('translate.google.com', '/translate_tts', {
          'ie': 'UTF-8',
          'q': chunk,
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
        audio.addAll(response.bodyBytes);
      }
      return _json(200, {
        'audio': 'data:audio/mp3;base64,${base64Encode(audio)}',
      });
    } catch (error, stackTrace) {
      stderr.writeln('Speech generation failed: $error\n$stackTrace');
      return _json(502, {'error': 'Speech service is temporarily unavailable.'});
    }
  });

  final handler = const Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(_jsonErrors())
      .addHandler(app.call);
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8000;
  await io.serve(handler, InternetAddress.anyIPv4, port);
  print('Dart Shelf backend listening on port $port');
}

void main() {
  runZonedGuarded(_start, (Object error, StackTrace stackTrace) {
    stderr.writeln('Unhandled error: $error\n$stackTrace');
  });
}
