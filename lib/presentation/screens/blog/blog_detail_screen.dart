import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../../data/repositories/program_repository.dart';
// --- 🔥 تصحيح المسارات هنا ---
import '../../bloc/blog_detail_bloc.dart';
import '../../bloc/blog_detail_event.dart';
import '../../bloc/blog_detail_state.dart';
// --- نهاية التصحيح ---

class BlogDetailScreen extends StatelessWidget {
  final int postId;

  const BlogDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BlogDetailBloc(
        RepositoryProvider.of<ProgramRepository>(context),
      )..add(FetchBlogDetail(postId)),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: BlocBuilder<BlogDetailBloc, BlogDetailState>(
          builder: (context, state) {
            if (state is BlogDetailLoading || state is BlogDetailInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is BlogDetailLoadFailure) {
              return Center(
                child: Text('فشل تحميل المقال: ${state.error}'),
              );
            }
            if (state is BlogDetailLoadSuccess) {
              final post = state.post;
              return CustomScrollView(
                slivers: [
                  // --- 1. رأس الصفحة (الصورة + أزرار التحكم) ---
                  SliverAppBar(
                    expandedHeight: MediaQuery.of(context).size.height *
                        0.35, // 35% من الشاشة للصورة
                    pinned: true,
                    elevation: 0,
                    // جعل لون الأزرار وتأثير العودة واضحاً
                    iconTheme: const IconThemeData(
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // أ. الصورة كخلفية
                          post.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: post.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image,
                                        color: Colors.grey, size: 50),
                                  ),
                                )
                              : Container(color: Colors.grey[200]),

                          // ب. التدرج اللوني (Gradient) السلس من الأسفل للأعلى
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black
                                        .withAlpha(200), // أسود شفاف بالأسفل
                                    Colors.transparent,
                                  ],
                                  stops: const [
                                    0.0,
                                    0.4
                                  ], // يغطي فقط الجزء السفلي من الصورة
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- 2. محتوى المقال مع حواف دائرية أنيقة ---
                  SliverToBoxAdapter(
                    child: Container(
                      transform: Matrix4.translationValues(
                          0.0, -20.0, 0.0), // صعود المحتوى فوق الصورة قليلاً
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24.0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // شريط سحب وهمي لزيادة الجمالية
                          Center(
                            child: Container(
                              margin:
                                  const EdgeInsets.only(top: 12, bottom: 20),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),

                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // أ. عنوان المقال بكامل حريته
                                Text(
                                  post.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        height: 1.4,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                      ),
                                ),
                                const SizedBox(height: 12),

                                // ب. تاريخ النشر وتفاصيل إضافية (الكاتب، إلخ)
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_outlined,
                                        size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 6),
                                    Text(
                                      post.date,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),

                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.0),
                                  child: Divider(height: 1),
                                ),

                                // ج. عرض المحتوى الكامل (HTML) بتنسيق رائع للعين
                                Html(
                                  data: post.content,
                                  style: {
                                    "body": Style(
                                      margin: Margins.zero,
                                      padding: HtmlPaddings.zero,
                                      fontSize:
                                          FontSize(18.0), // خط أكبر ومقروء
                                      lineHeight: const LineHeight(
                                          1.8), // تباعد سطور مريح
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey[300]
                                          : Colors.black87,
                                    ),
                                    "p": Style(
                                      margin: Margins.only(bottom: 20),
                                    ),
                                    "h1": Style(
                                        fontWeight: FontWeight.bold,
                                        fontSize: FontSize(24.0),
                                        margin:
                                            Margins.only(top: 24, bottom: 12)),
                                    "h2": Style(
                                        fontWeight: FontWeight.bold,
                                        fontSize: FontSize(22.0),
                                        margin:
                                            Margins.only(top: 24, bottom: 12)),
                                    "h3": Style(
                                        fontWeight: FontWeight.bold,
                                        fontSize: FontSize(20.0),
                                        margin:
                                            Margins.only(top: 20, bottom: 10)),
                                    "img": Style(
                                      width: Width.auto(),
                                      height: Height.auto(),
                                      margin: Margins.symmetric(
                                          vertical: 20, horizontal: 0),
                                    ),
                                    "a": Style(
                                      color: Colors.blue[700],
                                      textDecoration: TextDecoration.none,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    "blockquote": Style(
                                      margin: Margins.only(
                                          left: 0,
                                          right: 16,
                                          top: 20,
                                          bottom: 20),
                                      padding: HtmlPaddings.only(
                                          right: 16, top: 8, bottom: 8),
                                      border: const Border(
                                          right: BorderSide(
                                              color: Colors.blue,
                                              width: 4)), // خط جانبي للاقتباس
                                      backgroundColor:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey[800]
                                              : Colors.grey[100],
                                      fontStyle: FontStyle.italic,
                                    ),
                                    "li": Style(
                                      lineHeight: const LineHeight(1.6),
                                      margin: Margins.only(bottom: 10),
                                    ),
                                  },
                                ),

                                const SizedBox(
                                    height: 40), // مساحة بيضاء أسفل المقال
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return Container();
          },
        ),
      ),
    );
  }
}
