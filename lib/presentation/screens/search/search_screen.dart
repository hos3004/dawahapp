/* ==== BEGIN FILE: lib/presentation/screens/search/search_screen.dart ==== */

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/program_repository.dart';
import '../../bloc/search/search_bloc.dart';
import '../../bloc/search/search_event.dart';
import '../../bloc/search/search_state.dart';
import '../../widgets/program_card.dart';
import '../program_detail/program_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final SearchBloc _searchBloc;

  @override
  void initState() {
    super.initState();
    _searchBloc = SearchBloc(RepositoryProvider.of<ProgramRepository>(context));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchBloc.close();
    super.dispose();
  }

  // pagination listener
  void _onScroll() {
    if (_isBottom) {
      _searchBloc.add(LoadMoreSearchResults());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ❗️خلفية فاتحة متوافقة مع الثيم العام
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // شفاف فوق الخلفية
        elevation: 0,
        titleSpacing: 12,
        title: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9), // حقل بحث فاتح
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(color: Colors.black87),
            cursorColor: Colors.black54,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
              prefixIcon: const Icon(Icons.search, color: Colors.black54),
              hintText: 'ابحث عن البرامج والأفلام.',
              hintStyle: const TextStyle(color: Colors.black45),
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: Colors.black54),
                onPressed: () {
                  _searchController.clear();
                  _searchBloc.add(ClearSearch());
                },
              ),
            ),
            onChanged: (query) {
              _searchBloc.add(SearchQueryChanged(query));
            },
          ),
        ),
      ),
      body: Stack(
        children: [
          // نفس خلفية الرئيسية (bbg.jpg)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/bbg.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // المحتوى
          BlocProvider.value(
            value: _searchBloc,
            child: BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) {
                if (state is SearchInitial) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: kToolbarHeight + 24),
                      child: Text('ابدأ الكتابة للبحث', style: TextStyle(color: Colors.black54)),
                    ),
                  );
                }

                if (state is SearchLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is SearchFailure) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: kToolbarHeight + 24),
                      child: Text(
                        'حدث خطأ: ${state.error}',
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (state is SearchSuccess) {
                  if (state.programs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: kToolbarHeight + 24),
                        child: Text('لا توجد نتائج', style: TextStyle(color: Colors.black54)),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: kToolbarHeight + 12),
                    child: GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3 / 4,
                        crossAxisSpacing: 12.0,
                        mainAxisSpacing: 12.0,
                      ),
                      // عنصر تحميل إضافي للنهاية عند الـ pagination
                      itemCount: state.hasReachedMax
                          ? state.programs.length
                          : state.programs.length + 1,
                      itemBuilder: (context, index) {
                        if (index >= state.programs.length) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final program = state.programs[index];
                        return ProgramCard(
                          program: program,
                          aspectRatio: 3 / 4,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProgramDetailScreen(programId: program.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                }

                // fallback
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* ==== END FILE: lib/presentation/screens/search/search_screen.dart ==== */
