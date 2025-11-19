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
                  SliverAppBar(
                    expandedHeight: 250.0,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        post.title,
                        style: const TextStyle(
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 8)
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      background: post.imageUrl != null
                          ? CachedNetworkImage(
                        imageUrl: post.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.error, color: Colors.grey),
                        ),
                      )
                          : Container(color: Colors.grey[300]),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.date,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 16),
                              // عرض المحتوى الكامل باستخدام flutter_html
                              Html(
                                data: post.content,
                                style: {
                                  "body": Style(
                                    margin: Margins.zero,
                                    padding: HtmlPaddings.zero,
                                    fontSize: FontSize.large,
                                  ),
                                  "p": Style(
                                    lineHeight: const LineHeight(1.5),
                                  ),
                                  "img": Style(
                                    width: Width.auto(),
                                    height: Height.auto(),
                                  ),
                                  "a": Style(
                                    color: Theme.of(context).primaryColor,
                                    textDecoration: TextDecoration.none,
                                  ),
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
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