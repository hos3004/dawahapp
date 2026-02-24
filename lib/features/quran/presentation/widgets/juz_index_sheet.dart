import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/navigation/quran_navigation_bloc.dart';
import '../bloc/navigation/quran_navigation_event.dart';

class JuzIndexSheet extends StatefulWidget {
  const JuzIndexSheet({super.key});

  @override
  State<JuzIndexSheet> createState() => _JuzIndexSheetState();
}

class _JuzIndexSheetState extends State<JuzIndexSheet> {
  late Future<List<_JuzInfo>> _futureJuzs;
  static const String _juzAssetPath = 'assets/json/quran_data/juzs_index.json';

  @override
  void initState() {
    super.initState();
    _futureJuzs = _loadJuzs();
  }

  Future<List<_JuzInfo>> _loadJuzs() async {
    final jsonStr = await rootBundle.loadString(_juzAssetPath);
    final List<dynamic> data = json.decode(jsonStr) as List<dynamic>;

    final list = data.map((dynamic e) {
      final j = e as Map<String, dynamic>;
      return _JuzInfo(
        id: j['id'] as int,
        firstPage: j['page_number'] as int,
      );
    }).toList();

    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final navBloc = context.read<QuranNavigationBloc>();
    const Color primaryColor = Color(0xff0B4DA1);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        height: 500,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'فهرس الأجزاء',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<_JuzInfo>>(
                future: _futureJuzs,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('خطأ في تحميل البيانات'));
                  }

                  final juzList = snapshot.data ?? [];

                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: juzList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 60),
                    itemBuilder: (context, index) {
                      final j = juzList[index];

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        onTap: () {
                          navBloc.add(ChangePageEvent(j.firstPage));
                          Navigator.pop(context);
                        },
                        leading: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${j.id}',
                            style: const TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        title: Text(
                          'الجزء ${j.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          'يبدأ من صفحة ${j.firstPage}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.grey),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JuzInfo {
  final int id;
  final int firstPage;
  _JuzInfo({required this.id, required this.firstPage});
}