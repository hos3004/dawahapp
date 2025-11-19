// [ ملف جديد: lib/presentation/screens/quran/surah_index_modal.dart ]

import 'package:flutter/material.dart';
import '../../../data/repositories/quran_repo.dart';
import '../../../data/models/quran_models.dart';

class SurahIndexModal extends StatelessWidget {
  final Function(int pageNumber) onSurahSelected;

  const SurahIndexModal({super.key, required this.onSurahSelected});

  @override
  Widget build(BuildContext context) {
    final quranRepo = QuranRepository();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text("فهرس السور", style: Theme.of(context).textTheme.headlineSmall),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<SurahIndex>>(
              future: quranRepo.getSurahIndex(), // جلب الفهرس من سيرفرك
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("فشل تحميل الفهرس."));
                }

                final surahs = snapshot.data!;
                return ListView.builder(
                  itemCount: surahs.length,
                  itemBuilder: (context, index) {
                    final surah = surahs[index];
                    return ListTile(
                      title: Text("${index + 1}. سورة ${surah.nameArabic}"),
                      subtitle: Text("تبدأ من صفحة ${surah.pageNumber}"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => onSurahSelected(surah.pageNumber),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}