import 'package:flutter/material.dart';
import 'layout.dart';
import 'landing_page.dart';
import 'english_page.dart';
import 'arabic_page.dart';
import 'about_page.dart';
import 'contact_page.dart';
import 'languages_page.dart';

void main() {
  runApp(const LingoApp());
}

class LingoApp extends StatelessWidget {
  const LingoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = ThemeData.light().textTheme;

    return MaterialApp(
      title: 'Lingo',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        // Use a standard sans-serif available in browsers instead of the
        // previous serif face, which made the interface look thin and dated.
        fontFamily: 'Arial',
        textTheme: baseTextTheme.copyWith(
          bodySmall: baseTextTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: const Color(0xFF334155),
          ),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
          titleMedium: baseTextTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        Widget page;
        bool hideSidebar = false;
        bool isArabic = settings.name?.startsWith('/arabic') ?? false;

        switch (settings.name) {
          case '/':
            page = const LandingPage();
            hideSidebar = true;
            break;
          case '/english':
            page = const EnglishPage();
            break;
          case '/english/about':
            page = const AboutPage(interfaceLang: 'english');
            break;
          case '/english/contact':
            page = const ContactPage(interfaceLang: 'english');
            break;
          case '/english/langs':
            page = const LanguagesPage(interfaceLang: 'english');
            break;
          case '/arabic':
            page = const ArabicPage();
            break;
          case '/arabic/about':
            page = const AboutPage(interfaceLang: 'arabic');
            break;
          case '/arabic/contact':
            page = const ContactPage(interfaceLang: 'arabic');
            break;
          case '/arabic/langs':
            page = const LanguagesPage(interfaceLang: 'arabic');
            break;
          default:
            page = const LandingPage();
            hideSidebar = true;
        }

        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => AppLayout(
            hideSidebar: hideSidebar,
            isArabic: isArabic,
            child: page,
          ),
          transitionDuration: Duration.zero,
        );
      },
    );
  }
}
