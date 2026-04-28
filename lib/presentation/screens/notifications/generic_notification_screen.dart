import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class GenericNotificationScreen extends StatelessWidget {
  final String title;
  final String body;
  final String? imageUrl; // صورة اختيارية (مثلاً صورة هلال، فانوس، أو زهرة)

  const GenericNotificationScreen({
    super.key,
    required this.title,
    required this.body,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 1. الخلفية (نفس خلفية التطبيق لتوحيد الهوية)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/bbg.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // طبقة تعتيم خفيفة
          Container(color: Colors.black.withOpacity(0.3)),

          // 2. المحتوى
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // صورة التهنئة أو الأيقونة (إن وجدت)
                  if (imageUrl != null && imageUrl!.isNotEmpty)
                    Container(
                      height: 200,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: imageUrl!.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.white24),
                              )
                            : Image.asset(imageUrl!, fit: BoxFit.cover),
                      ),
                    )
                  else
                    // أيقونة افتراضية جميلة للأذكار
                    const Icon(Icons.nights_stay_rounded, size: 80, color: Colors.white70),

                  const SizedBox(height: 24),

                  // الكارت الزجاجي للنص
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // العنوان
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.tajawal(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff0B4DA1),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // فاصل مزخرف بسيط
                        const Divider(color: Colors.black12, thickness: 1, indent: 40, endIndent: 40),
                        const SizedBox(height: 16),
                        // النص (الذكر أو الرسالة)
                        Text(
                          body,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.tajawal(
                            fontSize: 18,
                            height: 1.6, // تباعد أسطر مريح للقراءة
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // زر دعاء أو إغلاق
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check),
                    label: const Text("تم القراءة"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0B4DA1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}