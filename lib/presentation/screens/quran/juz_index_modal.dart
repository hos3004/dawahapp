// [ ملف جديد: lib/presentation/screens/quran/juz_index_modal.dart ]

import 'package:flutter/material.dart';
import '../../../data/repositories/quran_repo.dart';
import '../../../data/models/quran_models.dart';

class JuzIndexModal extends StatelessWidget {
  final Function(int pageNumber) onJuzSelected;

  const JuzIndexModal({super.key, required this.onJuzSelected});

  @override
  Widget build(BuildContext context) {
    final quranRepo = QuranRepository();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text("فهرس الأجزاء", style: Theme.of(context).textTheme.headlineSmall),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<JuzIndex>>(
              future: quranRepo.getJuzIndex(), // جلب الفهرس
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("فشل تحميل الفهرس: ${snapshot.error}"));
                }

                final juzs = snapshot.data!;
                return ListView.builder(
                  itemCount: juzs.length,
                  itemBuilder: (context, index) {
                    final juz = juzs[index];
                    return ListTile(
                      title: Text("الجزء ${juz.id}"),
                      subtitle: Text("يبدأ من صفحة ${juz.pageNumber}"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => onJuzSelected(juz.pageNumber),
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