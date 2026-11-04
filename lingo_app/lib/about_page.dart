import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  final String interfaceLang;

  const AboutPage({Key? key, required this.interfaceLang}) : super(key: key);

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
              const Text("من نحن",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Image.asset('assets/3riplets.jpeg',
                      width: double.infinity, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                "في قلب مساعينا الرقمية يقف نعمان، مهندس هذه المساحة الافتراضية. وتتكامل روحه الرؤيوية مع المساهمات الثاقبة لاخوته، اللذين تثري حكمتهما الجماعية رحلتنا",
                style: TextStyle(height: 1.8),
              ),
              const SizedBox(height: 15),
              const Text(
                "باهيتشارا، وهو مصطلح متجذر بعمق باللغة الهندية/الأردية ، يلف جوهر مساعينا - أخوة الإنسانية ، وتتجاوز الحدود والثقافات المشابهة لأخوةنا/أخوتنا.",
                style: TextStyle(height: 1.8),
              ),
              const SizedBox(height: 15),
              const Text(
                "يساعد موقعنا على الإنترنت على صياغة عالم عالمي باهيتشارا، وهو نسيج من النفوس المترابطة المرتبطة بخيوط التعاطف والوحدة. من خلال هذه المنصة ، نطمح إلى تفكيك الحواجز الجغرافية ، مما يعزز عالمًا حيث يمكن للأفراد من آفاق متنوعة التواصل بسلاسة وتمديد يد العون إلى المحتاجين",
                style: TextStyle(height: 1.8),
              ),
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
            const Text("About Us",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Image.asset('assets/3riplets.jpeg',
                    width: double.infinity, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "At the heart of our digital endeavour stands Nouman, the architect of this virtual space. His visionary spirit is complemented by the insightful contributions inspired by his brotherhood, whose collective wisdom enriches our journey.",
              style: TextStyle(height: 1.6),
            ),
            const SizedBox(height: 15),
            const Text(
              "'Bhaichara', a term deeply rooted in Hindi/Urdu, encapsulates the essence of our endeavour - the fraternity of humanity, transcending borders and cultures akin to our brotherhood/fraternity.",
              style: TextStyle(height: 1.6),
            ),
            const SizedBox(height: 15),
            const Text(
              "Our website helps to forge a global 'Bhaichara', a tapestry of interconnected souls bound by the threads of compassion and unity. Through this platform, we aspire to dismantle geographical barriers, fostering a world where individuals from diverse horizons can communicate seamlessly and extend a helping hand to those in need.",
              style: TextStyle(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
