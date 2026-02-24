import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/reciter_model.dart';
import '../bloc/audio/quran_audio_bloc.dart';
import '../bloc/audio/quran_audio_event.dart';
import '../bloc/audio/quran_audio_state.dart';

class MemorizationSheet extends StatefulWidget {
  final int currentSurah;
  final int currentPage;

  const MemorizationSheet({
    super.key,
    required this.currentSurah,
    required this.currentPage,
  });

  @override
  State<MemorizationSheet> createState() => _MemorizationSheetState();
}

class _MemorizationSheetState extends State<MemorizationSheet> {
  // --- بيانات السور والمنطق ---
  final List<_SurahInfo> _surahs = [];
  bool _isLoadingSurahs = true;

  int? _startSurahId;
  int? _endSurahId;
  int? _startAyah;
  int? _endAyah;

  int _ayahRepeatCount = 0;
  int _rangeRepeatCount = 0;

  final List<int> _repeatOptions = [0, 1, 3, 5, 10];
  static const String _surahsAssetPath = 'assets/json/quran_data/surahs_index.json';

  // --- الألوان ---
  final Color kPrimaryColor = const Color(0xFF1565C0);
  final Color kBackgroundColor = const Color(0xFFFFFFFF);
  final Color kSurfaceColor = const Color(0xFFF3F4F6);
  final Color kTextColor = const Color(0xFF1F2937);
  final Color kSubTextColor = const Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    try {
      final jsonStr = await rootBundle.loadString(_surahsAssetPath);
      final Map<String, dynamic> data = json.decode(jsonStr) as Map<String, dynamic>;
      final List<dynamic> chapters = data['chapters'] as List<dynamic>;

      _surahs.clear();
      for (final dynamic e in chapters) {
        final ch = e as Map<String, dynamic>;
        _surahInfoFromJson(ch);
      }

      _surahs.sort((a, b) => a.id.compareTo(b.id));

      final int defaultSurahId = widget.currentSurah;
      final _SurahInfo defaultSurah = _surahs.firstWhere(
            (s) => s.id == defaultSurahId,
        orElse: () => _surahs.isNotEmpty ? _surahs.first : _SurahInfo.empty(),
      );

      setState(() {
        _isLoadingSurahs = false;
        _startSurahId ??= defaultSurah.id;
        _endSurahId ??= defaultSurah.id;
        _startAyah ??= 1;
        _endAyah ??= defaultSurah.versesCount;
      });
    } catch (e) {
      setState(() => _isLoadingSurahs = false);
      debugPrint("Error loading surahs: $e");
    }
  }

  void _surahInfoFromJson(Map<String, dynamic> ch) {
    _surahs.add(_SurahInfo(
      id: ch['id'] as int,
      nameArabic: ch['name_arabic'] as String,
      versesCount: ch['verses_count'] as int,
    ));
  }

  _SurahInfo? _findSurah(int? id) {
    if (id == null) return null;
    try {
      return _surahs.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  int _maxAyahForSurah(int? surahId) {
    final info = _findSurah(surahId);
    return info?.versesCount ?? 1;
  }

  String _repeatLabelFor(int value) {
    return value == 0
        ? 'بدون تكرار'
        : value == 1
        ? 'مرة واحدة'
        : '$value مرات';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: kBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                "إعدادات الحفظ والتكرار",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
            ),
            Expanded(
              child: _isLoadingSurahs
                  ? Center(child: CircularProgressIndicator(color: kPrimaryColor))
                  : BlocBuilder<QuranAudioBloc, QuranAudioState>(
                builder: (context, audioState) {
                  final reciters = audioState.reciters;
                  final selectedReciter = audioState.selectedReciter;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- القارئ ---
                        _buildSectionLabel("القارئ", Icons.mic_none_rounded),
                        Container(
                          decoration: BoxDecoration(
                            color: kSurfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: _buildModernDropdown<ReciterModel>(
                            value: selectedReciter,
                            hint: "اختر القارئ",
                            fillColor: Colors.transparent,
                            items: reciters.map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.nameArabic, style: textTheme.bodyMedium),
                            )).toList(),
                            onChanged: (reciter) {
                              if (reciter != null) {
                                context.read<QuranAudioBloc>().add(ChangeReciterEvent(reciter));
                              }
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // --- نطاق الآيات ---
                        _buildSectionLabel("نطاق الآيات", Icons.menu_book_rounded),
                        Container(
                          decoration: BoxDecoration(
                            color: kSurfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          child: Column(
                            children: [
                              _buildRangeRow(
                                label: "من:",
                                surahVal: _startSurahId,
                                ayahVal: _startAyah,
                                onSurahChanged: (val) => setState(() { _startSurahId = val; _startAyah = 1; }),
                                onAyahChanged: (val) => setState(() => _startAyah = val),
                                textTheme: textTheme,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Icon(Icons.arrow_downward_rounded, size: 16, color: kSubTextColor),
                                    ),
                                    Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
                                  ],
                                ),
                              ),
                              _buildRangeRow(
                                label: "إلى:",
                                surahVal: _endSurahId,
                                ayahVal: _endAyah,
                                onSurahChanged: (val) => setState(() {
                                  _endSurahId = val;
                                  _endAyah = _maxAyahForSurah(_endSurahId);
                                }),
                                onAyahChanged: (val) => setState(() => _endAyah = val),
                                textTheme: textTheme,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // --- التكرار ---
                        _buildSectionLabel("التكرار", Icons.repeat_rounded),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRepeatCard(
                                title: "تكرار الآية",
                                value: _ayahRepeatCount,
                                textTheme: textTheme,
                                onChanged: (val) => setState(() => _ayahRepeatCount = val ?? 0),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildRepeatCard(
                                title: "تكرار الفقرة",
                                value: _rangeRepeatCount,
                                textTheme: textTheme,
                                onChanged: (val) => setState(() => _rangeRepeatCount = val ?? 0),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // --- زر البدء ---
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _onStartPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.play_arrow_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "بــدء التلاوة",
                                  style: textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kPrimaryColor),
          const SizedBox(width: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: kSubTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeRow({
    required String label,
    required int? surahVal,
    required int? ayahVal,
    required ValueChanged<int?> onSurahChanged,
    required ValueChanged<int?> onAyahChanged,
    required TextTheme textTheme,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: kTextColor
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: _buildModernDropdown<int>(
            value: surahVal,
            hint: "السورة",
            isCompact: true,
            items: _surahs.map((s) => DropdownMenuItem<int>(
              value: s.id,
              child: Text('${s.id}. ${s.nameArabic}',
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium,
              ),
            )).toList(),
            onChanged: onSurahChanged,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: _buildModernDropdown<int>(
            value: ayahVal,
            hint: "آية",
            isCompact: true,
            items: List<int>.generate(_maxAyahForSurah(surahVal), (i) => i + 1)
                .map((v) => DropdownMenuItem<int>(
              value: v,
              child: Text('$v', style: textTheme.bodyMedium),
            )).toList(),
            onChanged: onAyahChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildRepeatCard({
    required String title,
    required int value,
    required ValueChanged<int?> onChanged,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.bodySmall?.copyWith(color: kSubTextColor),
          ),
          const SizedBox(height: 0),
          DropdownButtonHideUnderline(
            child: SizedBox(
              height: 35,
              child: DropdownButton<int>(
                value: value,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: kPrimaryColor, size: 20),
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: kTextColor),
                items: _repeatOptions.map((v) => DropdownMenuItem<int>(
                  value: v,
                  child: Text(_repeatLabelFor(v)),
                )).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required String hint,
    bool isCompact = false,
    Color fillColor = Colors.white,
  }) {
    return Container(
      height: isCompact ? 42 : 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12),
        border: isCompact ? Border.all(color: Colors.grey.shade300) : null,
      ),
      alignment: Alignment.center,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: kSubTextColor)),
          isExpanded: true,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: kSubTextColor, size: 20),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _onStartPressed() {
    final audioBloc = context.read<QuranAudioBloc>();

    if (_startSurahId == null || _endSurahId == null || _startAyah == null || _endAyah == null) {
      return;
    }

    int surahNumber = _startSurahId!;
    if (_endSurahId != _startSurahId) {
      _endSurahId = _startSurahId;
    }

    int startAyah = _startAyah!;
    int endAyah = _endAyah!;

    if (endAyah < startAyah) {
      final tmp = startAyah;
      startAyah = endAyah;
      endAyah = tmp;
    }

    final int ayahRep = _ayahRepeatCount <= 0 ? 1 : _ayahRepeatCount;
    final int rangeRep = _rangeRepeatCount <= 0 ? 1 : _rangeRepeatCount;

    audioBloc.add(
      PlayAudioRangeEvent(
        surahNumber: surahNumber,
        startAyah: startAyah,
        endAyah: endAyah,
        ayahRepeat: ayahRep,
        rangeRepeat: rangeRep,
      ),
    );

    Navigator.pop(context);
  }
}

// ✅ هذا الكلاس الآن خارج الـ Widget State تماماً
class _SurahInfo {
  final int id;
  final String nameArabic;
  final int versesCount;

  _SurahInfo({required this.id, required this.nameArabic, required this.versesCount});

  factory _SurahInfo.empty() => _SurahInfo(id: 1, nameArabic: 'الفاتحة', versesCount: 7);
}