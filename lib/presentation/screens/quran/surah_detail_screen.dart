// [ ملف جديد: lib/presentation/screens/quran/surah_detail_screen.dart ]

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../bloc/quran/quran_bloc.dart';

class SurahDetailScreen extends StatelessWidget {
  final int surahId;
  final String surahName;

  const SurahDetailScreen({super.key, required this.surahId, required this.surahName});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuranBloc()..add(FetchSurahVerses(surahId)),
      child: Scaffold(
        appBar: AppBar(title: Text("سورة $surahName")),
        body: BlocBuilder<QuranBloc, QuranState>(
          builder: (context, state) {
            if (state is QuranLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is QuranError) {
              return Center(child: Text(state.message));
            } else if (state is VersesLoaded) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.verses.length + 1, // +1 للبسملة
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // عرض البسملة في البداية (إلا في سورة التوبة رقم 9)
                    if (surahId == 9) return const SizedBox.shrink();
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: Center(
                        child: Text(
                          "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }
                  final verse = state.verses[index - 1];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: verse.textUthmani,
                            // استخدام خط أميري أو أي خط قرآني متاح في Google Fonts
                            style: GoogleFonts.amiri(
                              fontSize: 24,
                              height: 2.0, // تباعد الأسطر
                              color: Colors.black87,
                            ),
                          ),
                          const TextSpan(text: " "),
                          // رقم الآية مزخرف
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.green, width: 1),
                              ),
                              child: Text(
                                "${verse.verseKey}",
                                style: const TextStyle(fontSize: 12, color: Colors.green),
                              ),
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.justify, // محاذاة النص
                      textDirection: TextDirection.rtl,
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}