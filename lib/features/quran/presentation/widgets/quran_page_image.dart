import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/assets_manager.dart';

class QuranPageImage extends StatelessWidget {
  final int pageNumber;
  final String mushafType;

  const QuranPageImage({
    super.key,
    required this.pageNumber,
    required this.mushafType,
  });

  @override
  Widget build(BuildContext context) {
    // تحديد الرابط بناءً على نوع المصحف
    String baseUrl;
    switch (mushafType) {
      case 'warsh': baseUrl = AppConstants.warshBaseUrl; break;
      case 'kalon': baseUrl = AppConstants.kalonBaseUrl; break;
      case 'dory': baseUrl = AppConstants.doryBaseUrl; break;
      default: baseUrl = AppConstants.hafsBaseUrl;
    }

    final imageUrl = AssetsManager.getPageImageUrl(
      baseUrl: baseUrl,
      pageNumber: pageNumber,
    );

    return Container(
      // لون الورق الخلفي (بيج فاتح مريح للعين)
      color: const Color(0xFFFFF8E1),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        // ✅ التعديل هنا: استخدام contain بدلاً من fill لمنع التمطيط
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }
}