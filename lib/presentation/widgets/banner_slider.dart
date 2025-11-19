import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../data/models/program_item.dart';
import '../screens/program_detail/program_detail_screen.dart';

class BannerSlider extends StatefulWidget {
  final List<ProgramItem> items;
  const BannerSlider({super.key, required this.items});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleTap(ProgramItem item) {
    // التعامل مع النقر، مثل المشروع القديم
    // الانتقال إلى شاشة التفاصيل إذا كان 'tv_show'
    if (item.postType == "tv_show") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProgramDetailScreen(programId: item.id),
        ),
      );
    } else {
      // يمكنك إضافة تعامل مع أنواع أخرى هنا (مثل 'movie' أو 'video')
      print("Tapped on banner item: ${item.title}, Type: ${item.postType}");
    }
  }


  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink(); // لا تعرض شيئاً إذا كان البانر فارغاً
    }

    // تحديد ارتفاع البانر
    final double bannerHeight = MediaQuery.of(context).size.height * 0.3; // 30% من ارتفاع الشاشة

    return Container(
      height: bannerHeight,
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 1. الـ PageView
          PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return _buildBannerItem(item);
            },
          ),

          // 2. مؤشر النقاط
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: SmoothPageIndicator(
              controller: _pageController,
              count: widget.items.length,
              effect: ExpandingDotsEffect(
                dotHeight: 8,
                dotWidth: 8,
                activeDotColor: Theme.of(context).colorScheme.primary,
                dotColor: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerItem(ProgramItem item) {
    return InkWell(
      onTap: () => _handleTap(item),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ]
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // الصورة
              CachedNetworkImage(
                imageUrl: item.image ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.black12),
                errorWidget: (context, url, error) => Container(
                  color: Colors.black12,
                  child: const Icon(Icons.image_not_supported, color: Colors.black26),
                ),
              ),
              // فلتر غامق في الأسفل
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // العنوان
              Positioned(
                bottom: 25, // اترك مساحة للنقاط
                left: 16,
                right: 16,
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    shadows: [
                      Shadow(color: Colors.black87, blurRadius: 4)
                    ]
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}