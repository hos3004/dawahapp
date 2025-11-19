import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../data/models/program_item.dart';

class ProgramCard extends StatelessWidget {
  final ProgramItem program;
  final VoidCallback? onTap;
  final double? width;
  final double aspectRatio; // هذا المتغير لم نعد نستخدمه داخلياً للصورة

  const ProgramCard({
    super.key,
    required this.program,
    this.onTap,
    this.width,
    this.aspectRatio = 3 / 4,
  });

  @override
  Widget build(BuildContext context) {
    final String imageUrl = program.image ?? '';

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // يمكن إبقاؤها أو حذفها
          children: [

            // --- بداية التعديل ---
            // استبدلنا AspectRatio بـ Expanded
            // هذا يخبر الصورة أن تأخذ كل المساحة المتاحة "بعد"
            // أن يأخذ النص مساحته في الأسفل
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover, // مهم جداً ليملأ المساحة
                  placeholder: (context, url) => Container(
                    color: Colors.black12,
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.black12,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.black45,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // --- نهاية التعديل ---

            // --- النص (يبقى كما هو) ---
            Padding(
              padding: const EdgeInsets.only(
                top: 6.0,
                bottom: 4.0,
                left: 4.0,
                right: 4.0,
              ),
              child: Text(
                program.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
                textDirection: TextDirection.rtl,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,

                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}