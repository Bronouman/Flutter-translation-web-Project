import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'languages.dart';

class EnglishPage extends StatefulWidget {
  const EnglishPage({Key? key}) : super(key: key);

  @override
  _EnglishPageState createState() => _EnglishPageState();
}

class _EnglishPageState extends State<EnglishPage> {
  // In production call Vercel on the same origin; Vercel proxies /api/* to
  // Render. Calling Render directly from Flutter Web triggers browser CORS.
  String get backendUrl {
    final host = Uri.base.host;
    if (host.isEmpty || host == 'localhost' || host == '127.0.0.1') {
      return 'http://localhost:8000';
    }
    return Uri.base.resolve('/api').toString();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  String inputText = '';
  String selectedLanguage = '';
  String translatedText = '';

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, Object?> body,
  ) async {
    final response = await http
        .post(
          Uri.parse('$backendUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 90));

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw Exception(
        'API returned a non-JSON response (HTTP ${response.statusCode}). Check Vercel /api routing and Render service status.',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected API response (HTTP ${response.statusCode}).');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['error']?.toString() ?? 'Request failed (HTTP ${response.statusCode}).');
    }
    return decoded;
  }

  Future<void> handleTranslate() async {
    final text = inputText.trim();
    if (text.isEmpty) {
      _showAlert('Please Enter Some Text For Translation');
      return;
    }
    if (selectedLanguage.isEmpty) {
      _showAlert('Please Select a Language To Be Translated');
      return;
    }

    try {
      final data = await _postJson('/translate', {
        'text': text,
        'dest_lang_code': supportedLanguages[selectedLanguage],
      });
      final result = data['result'];
      if (result is! String || result.isEmpty) {
        throw Exception('The translation API returned no translated text.');
      }
      if (!mounted) return;
      setState(() => translatedText = result);
    } catch (error) {
      _showAlert(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> playAudio(String text, [String? targetLanguage]) async {
    if (text.trim().isEmpty) {
      _showAlert('Enter text or translate it before using the speech buttons.');
      return;
    }
    try {
      var language = targetLanguage ?? '';
      if (language.isEmpty) {
        final detection = await _postJson('/detect', {'text': text});
        language = detection['language']?.toString() ?? 'en';
      }
      final data = await _postJson('/speak', {
        'text': text,
        'language': language,
      });
      final audio = data['audio'];
      if (audio is! String || !audio.contains(',')) {
        throw Exception('The speech API returned invalid audio data.');
      }
      await _audioPlayer.play(BytesSource(base64Decode(audio.split(',').last)));
    } catch (error) {
      _showAlert(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showAlert(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'English Translator & Speech Synthesis',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFF8FAFC),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedLanguage.isEmpty ? null : selectedLanguage,
                    hint: const Text('-- Select Target Language --'),
                    items: supportedLanguages.keys
                        .map((lang) => DropdownMenuItem<String>(value: lang, child: Text(lang)))
                        .toList(),
                    onChanged: (value) => setState(() => selectedLanguage = value ?? ''),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                maxLines: 5,
                onChanged: (value) => inputText = value,
                decoration: InputDecoration(
                  hintText: 'Enter Text for Translation',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 2)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 2)),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 15,
                runSpacing: 10,
                children: [
                  _buildButton('Translate', handleTranslate),
                  _buildButton('Speak Input', () => playAudio(inputText)),
                  _buildButton('Speak Output', () => playAudio(translatedText, supportedLanguages[selectedLanguage])),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                constraints: const BoxConstraints(minHeight: 100),
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Result:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 15),
                    Text(translatedText, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      );
}
