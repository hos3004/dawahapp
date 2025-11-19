/* ==== BEGIN FILE: C:\daawah_app\lib\presentation\widgets\horizontal_program_row.dart ==== */

import 'package:flutter/material.dart';
import '../../data/models/program_item.dart';
import '../screens/program_detail/program_detail_screen.dart';
import 'program_card.dart';

/// Widget يعرض صفًا أفقيًا من البرامج مع عنوان.
class HorizontalProgramRow extends StatelessWidget {
  final String title;
  final List<ProgramItem> programs;
  final double rowHeight;
  final double cardAspectRatio;
  final double cardWidth;

  /// عند الضغط على كارت؛ إن تم تزويد هذا الكول باك فسيُستبدل الملاحة الافتراضية.
  final void Function(ProgramItem tappedItem)? onItemTap;

  const HorizontalProgramRow({
    super.key,
    required this.title,
    required this.programs,
    this.rowHeight = 180.0,
    this.cardAspectRatio = 16 / 9,
    this.cardWidth = 150.0,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    // لا نعرض شيئًا إذا لم توجد برامج.
    if (programs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // العنوان
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black45,
              shadows: [
                Shadow(
                  color: Colors.black.withAlpha(178), // أفضل أداء من withOpacity
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),

        // القائمة الأفقية للكروت
        SizedBox(
          height: rowHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: programs.length,
            itemBuilder: (context, index) {
              final program = programs[index];

              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 16.0 : 8.0,
                  right: index == programs.length - 1 ? 16.0 : 0.0,
                ),
                child: ProgramCard(
                  program: program,
                  width: cardWidth,
                  aspectRatio: cardAspectRatio,
                  onTap: () {
                    // إن وُجدت معالجة مخصّصة للضغط، استخدمها.
                    if (onItemTap != null) {
                      onItemTap!(program);
                      return;
                    }

                    // السلوك الافتراضي: الملاحة لصفحة التفاصيل للأنواع القابلة للنقر.
                    if (program.postType == 'tv_show' ||
                        program.postType == 'movie' ||
                        program.postType == 'video') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProgramDetailScreen(
                            programId: program.id,
                            postType: program.postType,
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/* ==== END FILE: C:\daawah_app\lib\presentation\widgets\horizontal_program_row.dart ==== */
