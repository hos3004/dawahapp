// [ ملف جديد: lib/presentation/screens/quran/quran_list_screen.dart ]

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/quran/quran_bloc.dart';
import 'surah_detail_screen.dart';

class QuranListScreen extends StatelessWidget {
  const QuranListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuranBloc()..add(FetchSurahs()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("المصحف الشريف"),
          centerTitle: true,
        ),
        body: BlocBuilder<QuranBloc, QuranState>(
          builder: (context, state) {
            if (state is QuranLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is QuranError) {
              return Center(child: Text(state.message));
            } else if (state is SurahsLoaded) {
              return ListView.separated(
                itemCount: state.surahs.length,
                separatorBuilder: (c, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final surah = state.surahs[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Text("${surah.id}", style: TextStyle(color: Theme.of(context).primaryColor)),
                    ),
                    title: Text(surah.nameArabic, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text("${surah.revelationPlace} - ${surah.versesCount} آية"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SurahDetailScreen(surahId: surah.id, surahName: surah.nameArabic),
                        ),
                      );
                    },
                  );
                },
              );
            }
            return const Center(child: Text("لا توجد بيانات"));
          },
        ),
      ),
    );
  }
}