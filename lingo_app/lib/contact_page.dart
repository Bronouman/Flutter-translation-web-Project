import 'package:flutter/material.dart';

class ContactPage extends StatelessWidget {
  final String interfaceLang;

  const ContactPage({Key? key, required this.interfaceLang}) : super(key: key);

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
              const Text("اتصل بنا",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("الاتصال : ٦٠١١٥٧٨١٣٩٧٨+ | ٩١٩٠٥٢٨٤٣٣٤٣+",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text("البريد الإلكتروني : mohammadgmalr@gmail.com",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text("المواعيد: ٥:٠٠ مساءً - ٧:٠٠ مساءً",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "نوصيك بإرسال بريد إلكتروني إلينا بدلاً من الاتصال بنا لأننا لن نرد على المكالمات لأننا سنكون مشغولين للغاية. ولكن إذا كان ذلك ضروريًا حقًا، فيرجى الاتصال بنا باستخدام الرقم أعلاه",
                style: TextStyle(color: Color(0xFF334155), height: 1.8),
              ),
              const SizedBox(height: 20),
              const Text("أرسل مقطع فيديو إلى بريدنا الإلكتروني",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(4),
                  border: const Border(
                      right: BorderSide(color: Color(0xFFEF4444), width: 4)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "اتصل فقط في حالة حدوث خطأ أو أي مشكلات أخرى أثناء استخدام الموقع",
                        style: TextStyle(
                            color: Color(0xFF991B1B),
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text("😡لن نستقبل المكالمات غير الضرورية😡"),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const Text("😉لا أقصد الإساءة بصراحة😜",
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Color(0xFF64748B))),
              const SizedBox(height: 10),
              const Text("😊شكرًا لك على تفهمك ودعمك😊",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
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
            const Text("Contact Us",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Call : +91 90528 43343 | +60 1157813978",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("Email : mohammadgmalr@gmail.com",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("Timings : 5:00 PM - 7:00 PM",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "We would recommend to email us rather than calling us since we would not pick up the calls since we would be really busy. But, if it's really necessary, please call us using the above number.",
              style: TextStyle(color: Color(0xFF334155), height: 1.6),
            ),
            const SizedBox(height: 20),
            const Text("Send a Video to our Email",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(4),
                border: const Border(
                    left: BorderSide(color: Color(0xFFEF4444), width: 4)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "Call only for Error or Any Other Issues faced while using the Website",
                      style: TextStyle(
                          color: Color(0xFF991B1B),
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text("😡Unnecessary Calls will not be entertained by us😡"),
                ],
              ),
            ),
            const SizedBox(height: 15),
            const Text("😉No Offence to be Honest😜",
                style: TextStyle(
                    fontStyle: FontStyle.italic, color: Color(0xFF64748B))),
            const SizedBox(height: 10),
            const Text("😊Thank You for your Understanding and your Support😊",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
          ],
        ),
      ),
    );
  }
}
