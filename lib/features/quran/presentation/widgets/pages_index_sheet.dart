import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/navigation/quran_navigation_bloc.dart';
import '../bloc/navigation/quran_navigation_event.dart';
import '../bloc/navigation/quran_navigation_state.dart';

/// شيت فهرس الصفحات
/// يعرض قائمة من صفحة 1 إلى 604
/// وعند الضغط على أي صفحة ينتقل مباشرة إليها.
class PagesIndexSheet extends StatelessWidget {
  const PagesIndexSheet({super.key});

  static const int _totalPages = 604;

  @override
  Widget build(BuildContext context) {
    final navBloc = context.read<QuranNavigationBloc>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        height: 500,
        child: Container(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // عنوان الشيت
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'فهرس الصفحات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const Divider(height: 1),

              // قائمة الصفحات
              Expanded(
                child: BlocBuilder<QuranNavigationBloc, QuranNavigationState>(
                  builder: (context, state) {
                    final int currentPage = state.currentPage;

                    return ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _totalPages,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final pageNumber = index + 1;
                        final bool isCurrent = pageNumber == currentPage;

                        return ListTile(
                          onTap: () {
                            navBloc.add(ChangePageEvent(pageNumber));
                            Navigator.pop(context);
                          },
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: isCurrent
                                ? const Color(0xff0B4DA1)
                                : Colors.grey.shade300,
                            child: Text(
                              '$pageNumber',
                              style: TextStyle(
                                fontSize: 12,
                                color: isCurrent
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          title: Text(
                            'صفحة $pageNumber',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isCurrent
                                  ? const Color(0xff0B4DA1)
                                  : Colors.black87,
                            ),
                          ),
                          trailing: isCurrent
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xff0B4DA1),
                                )
                              : const Icon(
                                  Icons.chevron_left,
                                  color: Colors.grey,
                                ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
