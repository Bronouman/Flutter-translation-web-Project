import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  void _showEnglishAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(
            "** PLEASE READ THE CAUTIONS VERY CAREFULLY **\n😊🍿All The Best🍟🥤\n😊🍿Now, Go and Enjoy The Website🍟🥤"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/english');
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void _showArabicAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(
            "** يرجى قراءة التحذيرات بعناية فائقة **\n🥤🍟أتمنى لك كل خير🍿😊\n🥤🍟الآن، يلاّ روح واستمتع بالموقع🍿😊"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/arabic');
            },
            child: const Text("حسنا"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to Lingo',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Please select your preferred interface language:',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 18),
              ),
              const SizedBox(height: 50),
              Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLangCard(
                        title: 'English',
                        subtitle: 'Access the English interface and tools.',
                        buttonText: 'Launch English',
                        onTap: () => _showEnglishAlert(context),
                        buttonColor: const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 30),
                      _buildLangCard(
                        title: 'العربية',
                        subtitle: 'الوصول إلى واجهة اللغة العربية.',
                        buttonText: 'ابدأ بالعربية',
                        onTap: () => _showArabicAlert(context),
                        buttonColor: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangCard({
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
    required Color buttonColor,
  }) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 25, offset: Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 15),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Color(0xFF64748B))),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: onTap,
            child: Text(buttonText,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
