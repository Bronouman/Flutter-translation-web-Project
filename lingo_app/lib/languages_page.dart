import 'package:flutter/material.dart';

class LanguagesPage extends StatelessWidget {
  final String interfaceLang;

  const LanguagesPage({Key? key, required this.interfaceLang})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isArabic = interfaceLang == 'arabic';

    if (isArabic) {
      return Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("اللغات",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 20),
              const Text("تبديل واجهة التطبيق كاملة إلى اللغة الأخرى:",
                  style: TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/english/langs'),
                child: const Text("English",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              )
            ],
          ),
        ),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("English Languages",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 20),
            const Text(
                "Toggle the application interface layout language completely:",
                style: TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF10B981), // Green color mapping from react
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/arabic/langs'),
              child: const Text("Arabic",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
