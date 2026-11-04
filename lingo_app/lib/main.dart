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
    return MaterialApp(
      title: 'Lingo',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Poppins',
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
