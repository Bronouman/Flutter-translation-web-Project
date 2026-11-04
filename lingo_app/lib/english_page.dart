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
    final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
    return 'http://$host:8000';
  }

  final AudioPlayer _audioPlayer = AudioPlayer();

  String inputText = "";
  String selectedLanguage = "";
  String translatedText = "";

  Future<void> handleTranslate() async {
    if (inputText.isEmpty) {
      _showAlert("Please Enter Some Text For Translation");
      return;
    }
    if (selectedLanguage.isEmpty) {
      _showAlert("Please Select a Language To Be Translated");
      return;
    }

    final destCode = supportedLanguages[selectedLanguage];

    try {
      final res = await http.post(
        Uri.parse('$backendUrl/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': inputText, 'dest_lang_code': destCode}),
      );

      final data = jsonDecode(res.body);
      if (data['result'] != null) {
        setState(() {
          translatedText = data['result'];
        });
      }
    } catch (error) {
      _showAlert("Error translating. Please try again.");
    }
  }

  Future<void> playAudio(String textToSpeak, [String? targetLangCode]) async {
    if (textToSpeak.isEmpty) return;

    try {
      String finalLang = targetLangCode ?? '';

      if (finalLang.isEmpty) {
        final detRes = await http.post(
          Uri.parse('$backendUrl/detect'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': textToSpeak}),
        );
        final detData = jsonDecode(detRes.body);
        finalLang = detData['language'] ?? 'en';
      }

      final audRes = await http.post(
        Uri.parse('$backendUrl/speak'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': textToSpeak, 'language': finalLang}),
      );

      final audData = jsonDecode(audRes.body);
      if (audData['audio'] != null) {
        String base64String = audData['audio'].split(',').last;
        await _audioPlayer.play(BytesSource(base64Decode(base64String)));
      }
    } catch (error) {
      _showAlert("Error playing audio.");
    }
  }

  void _showAlert(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
                "English Translator & Speech Synthesis",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
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
                    hint: const Text("-- Select Target Language --"),
                    items: supportedLanguages.keys.map((String lang) {
                      return DropdownMenuItem<String>(
                        value: lang,
                        child: Text(lang),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedLanguage = val ?? "";
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                maxLines: 5,
                onChanged: (val) => inputText = val,
                decoration: InputDecoration(
                  hintText: "Enter Text for Translation",
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 15,
                runSpacing: 10,
                children: [
                  _buildButton("Translate", handleTranslate),
                  _buildButton("Speak Input", () => playAudio(inputText)),
                  _buildButton(
                    "Speak Output",
                    () => playAudio(
                      translatedText,
                      supportedLanguages[selectedLanguage],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                constraints: const BoxConstraints(minHeight: 100),
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Result:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
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

  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
