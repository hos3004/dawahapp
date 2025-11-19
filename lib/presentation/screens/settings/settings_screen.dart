// lib/presentation/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import '../../../services/url_launcher_service.dart';
import '../../../utils/app_links.dart';
import '../webview/webview_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: ListView(
        children: [
          const SizedBox(height: 20),

          // قسم المعلومات القانونية
          _buildSectionTitle(context, 'المعلومات القانونية'),
          _buildLinkTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'سياسة الخصوصية',
            subtitle: 'كيف نستخدم بياناتك',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WebViewScreen(
                    title: 'سياسة الخصوصية',
                    url: AppLinks.privacyPolicy,
                  ),
                ),
              );
            },
          ),
          _buildLinkTile(
            context,
            icon: Icons.gavel_outlined,
            title: 'شروط الاستخدام',
            subtitle: 'قواعد استخدام التطبيق',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WebViewScreen(
                    title: 'شروط الاستخدام',
                    url: AppLinks.termsOfService,
                  ),
                ),
              );
            },
          ),

          // قسم عن التطبيق
          _buildSectionTitle(context, 'عن التطبيق'),
          _buildLinkTile(
            context,
            icon: Icons.info_outline,
            title: 'عن التطبيق',
            subtitle: 'معلومات عن قناة دعوة',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WebViewScreen(
                    title: 'عن التطبيق',
                    url: AppLinks.aboutUs,
                  ),
                ),
              );
            },
          ),
          _buildLinkTile(
            context,
            icon: Icons.contact_support_outlined,
            title: 'اتصل بنا',
            subtitle: 'للدعم الفني أو الملاحظات',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WebViewScreen(
                    title: 'اتصل بنا',
                    url: AppLinks.contactUs,
                  ),
                ),
              );
            },
          ),

          // قسم السوشيال ميديا
          _buildSocialSection(context),

          const SizedBox(height: 40),
          _buildAppVersion(),
        ],
      ),
    );
  }

  // عنوان القسم
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // بلاطة رابط عادي (سياسة – شروط – عن التطبيق...)
  Widget _buildLinkTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[600]),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }

  // قسم السوشيال ميديا باستخدام GridView
  Widget _buildSocialSection(BuildContext context) {
    final socialItems = [
      {
        'name': 'يوتيوب',
        'icon': 'assets/icons/youtube.png',
        'url': AppLinks.youtube,
      },
      {
        'name': 'فيسبوك',
        'icon': 'assets/icons/fb.png',
        'url': AppLinks.facebook,
      },
      {
        'name': 'انستجرام',
        'icon': 'assets/icons/insta.png',
        'url': AppLinks.instagram,
      },
      {
        'name': 'تيك توك',
        'icon': 'assets/icons/tiktok.png',
        'url': AppLinks.tiktok,
      },
      {
        'name': 'تيليجرام',
        'icon': 'assets/icons/telegram.png',
        'url': AppLinks.telegram,
      },
      {
        'name': 'X (تويتر)',
        'icon': 'assets/icons/x.png',
        'url': AppLinks.x_twitter,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'تابعنا على'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: socialItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // عمودين (3 صفوف) – شكل أنيق على الموبايل
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final item = socialItems[index];
              return _buildSocialCard(
                context,
                imagePath: item['icon'] as String,
                name: item['name'] as String,
                url: item['url'] as String,
              );
            },
          ),
        ),
      ],
    );
  }

  // تصميم بطاقة السوشيال
  Widget _buildSocialCard(
      BuildContext context, {
        required String imagePath,
        required String name,
        required String url,
      }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.0),
      ),
      color: const Color(0xFFF7F8FC),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.0),
        onTap: () => UrlLauncherService.launchUrl(url),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  imagePath,
                  height: 28,
                  width: 28,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // رقم إصدار التطبيق
  Widget _buildAppVersion() {
    const String appVersion = "1.0.0";

    return Center(
      child: Text(
        'إصدار التطبيق: $appVersion',
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 12,
        ),
      ),
    );
  }
}
