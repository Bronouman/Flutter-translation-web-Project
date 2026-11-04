import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'languages.dart';

class ArabicPage extends StatefulWidget {
  const ArabicPage({Key? key}) : super(key: key);

  @override
  _ArabicPageState createState() => _ArabicPageState();
}

class _ArabicPageState extends State<ArabicPage> {
  String get backendUrl {
    final host = Uri.base.host;
    if (host.isEmpty || host == 'localhost' || host == '127.0.0.1') {
      return 'http://localhost:8000';
    }
    // Same-origin proxy avoids browser CORS failures against Render.
    return Uri.base.resolve('/api').toString();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  String inputText = "";
  String selectedLanguage = "";
  String translatedText = "";

  Future<Map<String, dynamic>> _postJson(String path, Map<String, Object?> body) async {
    final response = await http
        .post(Uri.parse('$backendUrl$path'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
        .timeout(const Duration(seconds: 90));
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw Exception('تعذرت قراءة استجابة الخادم (HTTP ${response.statusCode}). تحقق من نشر الخادم.');
    }
    if (decoded is! Map<String, dynamic>) throw Exception('وصلت استجابة غير متوقعة من الخادم (HTTP ${response.statusCode}).');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['error']?.toString() ?? 'فشل الطلب (HTTP ${response.statusCode}).');
    }
    return decoded;
  }

  Future<void> handleTranslate() async {
    final text = inputText.trim();
    if (text.isEmpty) {
      _showAlert("الرجاء إدخال بعض النص للترجمة");
      return;
    }
    if (selectedLanguage.isEmpty) {
      _showAlert("الرجاء اختيار اللغة المراد ترجمتها");
      return;
    }
    try {
      final data = await _postJson('/translate', {'text': text, 'dest_lang_code': supportedLanguages[selectedLanguage]});
      final result = data['result'];
      if (result is! String || result.isEmpty) throw Exception('لم يُرجع الخادم نصاً مترجماً.');
      if (!mounted) return;
      setState(() => translatedText = result);
    } catch (error) {
      _showAlert(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> playAudio(String textToSpeak, [String? targetLangCode]) async {
    if (textToSpeak.trim().isEmpty) {
      _showAlert('أدخل نصاً أو ترجم النص قبل استخدام أزرار الصوت.');
      return;
    }
    try {
      var language = targetLangCode ?? '';
      if (language.isEmpty) {
        final detected = await _postJson('/detect', {'text': textToSpeak});
        language = detected['language']?.toString() ?? 'ar';
      }
      final data = await _postJson('/speak', {'text': textToSpeak, 'language': language});
      final audio = data['audio'];
      if (audio is! String || !audio.contains(',')) throw Exception('وصلت بيانات صوت غير صحيحة.');
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
              const Text("المترجم ومركب النطق", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0), width: 2), borderRadius: BorderRadius.circular(8), color: const Color(0xFFF8FAFC)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedLanguage.isEmpty ? null : selectedLanguage,
                    hint: const Text("-- اختر اللغة الهدف --"),
                    items: supportedLanguages.keys.map((lang) => DropdownMenuItem<String>(value: lang, child: Text(lang))).toList(),
                    onChanged: (val) => setState(() => selectedLanguage = val ?? ""),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(maxLines: 5, onChanged: (val) => inputText = val, decoration: InputDecoration(hintText: "أدخل النص للترجمة...", filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 2)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 2)))),
              const SizedBox(height: 20),
              Wrap(spacing: 15, runSpacing: 10, children: [
                _buildButton("ترجمة", handleTranslate),
                _buildButton("استمع للأصل", () => playAudio(inputText)),
                _buildButton("استمع للترجمة", () => playAudio(translatedText, supportedLanguages[selectedLanguage])),
              ]),
              const SizedBox(height: 30),
              Container(
                constraints: const BoxConstraints(minHeight: 100),
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("النتيجة:", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
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
