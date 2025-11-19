import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/blog_bloc.dart';
import '../../bloc/blog_event.dart';
import '../../bloc/blog_state.dart';
import '../../../data/repositories/program_repository.dart';
import '../../widgets/blog_card.dart';
import 'blog_detail_screen.dart';

class BlogListScreen extends StatelessWidget {
  const BlogListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BlogBloc(
        RepositoryProvider.of<ProgramRepository>(context),
      )..add(FetchBlogs()),
      child: const BlogView(),
    );
  }
}

class BlogView extends StatefulWidget {
  const BlogView({super.key});

  @override
  State<BlogView> createState() => _BlogViewState();
}

class _BlogViewState extends State<BlogView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<BlogBloc>().add(LoadMoreBlogs());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll - 300);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlogBloc, BlogState>(
      builder: (context, state) {

        // --- 🔥 تصحيح: هذا هو الشرط الصحيح للتحميل الأولي ---
        // إظهار التحميل فقط إذا كانت الحالة Initial أو Loading
        if (state is BlogInitial || state is BlogLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        // --- نهاية التصحيح ---

        if (state is BlogLoadFailure) {
          return Center(
            child: Text(
              'فشل تحميل المقالات: ${state.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        if (state is BlogLoadSuccess) {
          if (state.posts.isEmpty) {
            return const Center(child: Text('لا توجد مقالات لعرضها حالياً.'));
          }

          return ListView.builder(
            controller: _scrollController,
            itemCount: state.hasReachedMax
                ? state.posts.length
                : state.posts.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index >= state.posts.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final post = state.posts[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlogDetailScreen(postId: post.id),
                    ),
                  );
                },
                child: BlogCard(post: post),
              );
            },
          );
        }

        return const Center(child: Text('حالة غير معروفة'));
      },
    );
  }
}