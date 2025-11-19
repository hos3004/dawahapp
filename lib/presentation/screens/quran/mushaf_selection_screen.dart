import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/quran_repo.dart';
import '../../../data/models/quran_models.dart';
import '../../bloc/quran/quran_reader_cubit.dart'; // Cubit الذي أنشأناه
import 'quran_reader_screen.dart';

// 🟢 تحويلها إلى StatefulWidget للتحكم في دورة حياة الـ Cubit
class MushafSelectionScreen extends StatefulWidget {
  const MushafSelectionScreen({super.key});

  @override
  State<MushafSelectionScreen> createState() => _MushafSelectionScreenState();
}

class _MushafSelectionScreenState extends State<MushafSelectionScreen> {
  // 🟢 إنشاء الـ Cubit مرة واحدة ليعيش مع هذه الشاشة
  late final QuranReaderCubit _cubit;
  final QuranRepository _quranRepo = QuranRepository();

  @override
  void initState() {
    super.initState();
    _cubit = QuranReaderCubit();
  }

  @override
  void dispose() {
    _cubit.close(); // 🟢 إغلاق الـ Cubit عند مغادرة الشاشة
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("اختر المصحف"),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Mushaf>>(
        future: _quranRepo.getMushafsList(), // جلب المصاحف من سيرفرك
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("فشل التحميل: ${snapshot.error}", textAlign: TextAlign.center));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("لا توجد مصاحف متاحة"));
          }

          final mushafs = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: mushafs.length,
            itemBuilder: (context, index) {
              final mushaf = mushafs[index];
              return InkWell(
                onTap: () {
                  // 1. تهيئة الـ Cubit وبدء التحميل الجزئي (10 صفحات)
                  _cubit.initializeMushaf(mushaf);

                  // 2. الانتقال إلى شاشة القراءة (Reader Screen)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider<QuranReaderCubit>.value(
                        value: _cubit, // تمرير الـ Cubit المهيأ
                        child: const QuranReaderScreen(),
                      ),
                    ),
                  );
                },
                child: MushafCard(mushaf: mushaf),
              );
            },
          );
        },
      ),
    );
  }
}

// ويدجت مساعد لبطاقة المصحف
class MushafCard extends StatelessWidget {
  final Mushaf mushaf;
  const MushafCard({super.key, required this.mushaf});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: mushaf.image,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                errorWidget: (context, url, error) => const Icon(Icons.book, size: 50, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(mushaf.name, textAlign: TextAlign.center, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(mushaf.description,  maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}