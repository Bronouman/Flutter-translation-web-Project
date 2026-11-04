import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'languages.dart';

class EnglishPage extends StatefulWidget {
  const EnglishPage({Key? key}) : super(key: key);

  @override
  _EnglishPageState createState() => _EnglishPageState();
}

class _EnglishPageState extends State<EnglishPage> {
  String get backendUrl {
    final host = Uri.base.host;
    if (host.isEmpty || host == 'localhost' || host == '127.0.0.1') {
      return 'http://localhost:8000';
    }
    return Uri.base.resolve('/api').toString();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  String inputText = "";
  String selectedLanguage = "";
  String translatedText = "";

  Future<void> handleTranslate() async {
    final text = inputText.trim();
    if (text.isEmpty) {
      _showAlert("Please Enter Some Text For Translation");
      return;
    }
    if (selectedLanguage.isEmpty) {
      _showAlert("Please Select a Language To Be Translated");
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse('$backendUrl/translate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'text': text,
              'dest_lang_code': supportedLanguages[selectedLanguage],
            }),
          )
          .timeout(const Duration(seconds: 90));
      final dynamic data;
      try {
        data = jsonDecode(response.body);
      } on FormatException {
        throw Exception('Translation API returned an invalid response (HTTP ${response.statusCode}). Verify the Vercel /api rewrite and Render service.');
      }
      if (data is! Map) throw Exception('Translation API returned an unexpected response.');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(data['error']?.toString() ?? 'Translation failed (HTTP ${response.statusCode}).');
      }
      if (data['result'] is! String || (data['result'] as String).isEmpty) {
        throw Exception('Translation API returned no translated text.');
      }
      if (!mounted) return;
      setState(() => translatedText = data['result'] as String);
    } catch (error) {
      _showAlert(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> playAudio(String textToSpeak, [String? targetLangCode]) async {
    if (textToSpeak.trim().isEmpty) {
      _showAlert('Enter text or translate it before using the speech buttons.');
      return;
    }
    try {
      var language = targetLangCode ?? '';
      if (language.isEmpty) {
        final detectResponse = await http
            .post(Uri.parse('$backendUrl/detect'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'text': textToSpeak}))
            .timeout(const Duration(seconds: 45));
        final detected = jsonDecode(detectResponse.body);
        if (detectResponse.statusCode < 200 || detectResponse.statusCode >= 300) {
          throw Exception(detected['error'] ?? 'Language detection failed.');
        }
        language = detected['language'] ?? 'en';
      }
      final response = await http
          .post(Uri.parse('$backendUrl/speak'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'text': textToSpeak, 'language': language}))
          .timeout(const Duration(seconds: 45));
      final data = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(data['error'] ?? 'Speech generation failed.');
      }
      final audio = data['audio'];
      if (audio is! String || !audio.contains(',')) throw Exception('Speech API returned invalid audio.');
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
              const Text("English Translator & Speech Synthesis", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0), width: 2), borderRadius: BorderRadius.circular(8), color: const Color(0xFFF8FAFC)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedLanguage.isEmpty ? null : selectedLanguage,
                    hint: const Text("-- Select Target Language --"),
                    items: supportedLanguages.keys.map((lang) => DropdownMenuItem<String>(value: lang, child: Text(lang))).toList(),
                    onChanged: (val) => setState(() => selectedLanguage = val ?? ""),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                maxLines: 5,
                onChanged: (val) => inputText = val,
                decoration: InputDecoration(hintText: "Enter Text for Translation", filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 2)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 2))),
              ),
              const SizedBox(height: 20),
              Wrap(spacing: 15, runSpacing: 10, children: [
                _buildButton("Translate", handleTranslate),
                _buildButton("Speak Input", () => playAudio(inputText)),
                _buildButton("Speak Output", () => playAudio(translatedText, supportedLanguages[selectedLanguage])),
              ]),
              const SizedBox(height: 30),
              Container(
                constraints: const BoxConstraints(minHeight: 100),
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Result:", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 15),
                  Text(translatedText, style: const TextStyle(fontSize: 16)),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) => ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      );
}
