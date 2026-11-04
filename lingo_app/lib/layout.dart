import 'package:flutter/material.dart';

class AppLayout extends StatelessWidget {
  final Widget child;
  final bool hideSidebar;
  final bool isArabic;

  const AppLayout({
    Key? key,
    required this.child,
    this.hideSidebar = false,
    this.isArabic = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (hideSidebar) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: child,
      );
    }

    final sidebar = Container(
      width: 260,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(4, 0),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  isArabic ? 'قائمة لينجو' : 'Lingo Menu',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF38BDF8),
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _buildNavItem(context, isArabic ? 'الصفحة الرئيسية' : 'Home Page',
                  isArabic ? '/arabic' : '/english'),
              _buildNavItem(context, isArabic ? 'من نحن' : 'About Us',
                  isArabic ? '/arabic/about' : '/english/about'),
              _buildNavItem(context, isArabic ? 'اتصل بنا' : 'Contact Us',
                  isArabic ? '/arabic/contact' : '/english/contact'),
              _buildNavItem(context, isArabic ? 'اللغات' : 'Languages',
                  isArabic ? '/arabic/langs' : '/english/langs'),
            ],
          ),
        ),
      ),
    );

    final mainContent = Expanded(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 30, offset: Offset(0, 10))
          ],
        ),
        child: Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child:
              child, // The child itself is now wrapped in a Scrollbar inside its respective file
        ),
      ),
    );

    return Scaffold(
      body: Row(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        children: [
          sidebar,
          mainContent,
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String title, String route) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => Navigator.pushReplacementNamed(context, route),
        borderRadius: BorderRadius.circular(8),
        hoverColor: const Color(0xFF2563EB),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Text(
            title,
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 15,
                fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
