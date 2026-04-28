import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'athkar_detail_screen.dart';
import 'hisn_accordion_screen.dart';
import '../../prayer_times/presentation/widgets/prayer_times_widget.dart';

class AthkarLandingScreen extends StatelessWidget {
  const AthkarLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ✅ الخلفية تملأ الشاشة كلها دائمًا
          Positioned.fill(
            child: Image.asset(
              "assets/images/bbg.jpg",
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // ✅ المحتوى فوق الخلفية
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Image.asset("assets/images/alogo.png", height: 250),
                          const SizedBox(height: 5),
                          _buildMenuButton(
                            context,
                            "أذكار الصباح",
                            "https://daawah.tv/app/athkar/json/morning.json",
                            Icons.wb_sunny_outlined,
                            Colors.amber,
                          ),
                          _buildMenuButton(
                            context,
                            "أذكار المساء",
                            "https://daawah.tv/app/athkar/json/evening.json",
                            Icons.nights_stay_outlined,
                            Colors.indigo,
                          ),
                          Container(
                            width: double.infinity,
                            height: 80,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.9),
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                elevation: 5,
                              ),
                              onPressed: () {
                                // ✅ هنا التوجيه للصفحة الجديدة (الأكورديون)
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const HisnAccordionScreen(),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.brown.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    // يمكنك تغيير الأيقونة هنا إذا رغبت، حالياً هي الدرع
                                    child: const Icon(Icons.security,
                                        color: Colors.brown, size: 30),
                                  ),
                                  const SizedBox(width: 20),
                                  Text(
                                    "حصن المسلم",
                                    style: GoogleFonts.tajawal(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.arrow_forward_ios,
                                      color: Colors.grey[400], size: 18),
                                ],
                              ),
                            ),
                          ),
                          const PrayerTimesWidget(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, String jsonPath,
      IconData icon, Color color) {
    return Container(
      width: double.infinity,
      height: 80,
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.9),
          foregroundColor: Colors.black87,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 5,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AthkarDetailScreen(jsonPath: jsonPath),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Text(
              title,
              style: GoogleFonts.tajawal(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }
}
