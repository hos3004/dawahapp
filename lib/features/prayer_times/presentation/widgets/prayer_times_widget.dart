import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:adhan/adhan.dart';
import '../bloc/prayer_times_cubit.dart';
import '../bloc/prayer_times_state.dart';
import 'dome_clipper.dart';

class PrayerTimesWidget extends StatelessWidget {
  const PrayerTimesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PrayerTimesCubit()..checkSetup(),
      child: const _PrayerTimesView(),
    );
  }
}

class _PrayerTimesView extends StatefulWidget {
  const _PrayerTimesView({Key? key}) : super(key: key);

  @override
  State<_PrayerTimesView> createState() => _PrayerTimesViewState();
}

class _PrayerTimesViewState extends State<_PrayerTimesView> {
  Timer? _timer;
  Duration _timeUntilNext = Duration.zero;
  String _nextPrayerName = "";

  static const Color bgColor = Color(0xFFF5EEDB);
  static const Color accentColor = Color(0xFFB4905D);
  static const Color cardColor = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), _updateTimer);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimer(Timer timer) {
    final state = context.read<PrayerTimesCubit>().state;
    if (state is PrayerTimesLoaded) {
      final now = DateTime.now();
      final prayerTimes = state.prayerTimes;

      final next = prayerTimes.nextPrayer();
      DateTime? nextTime;
      String pName = "";

      switch (next) {
        case Prayer.fajr:
          nextTime = prayerTimes.fajr;
          pName = "الفجر";
          break;
        case Prayer.dhuhr:
          nextTime = prayerTimes.dhuhr;
          pName = "الظهر";
          break;
        case Prayer.asr:
          nextTime = prayerTimes.asr;
          pName = "العصر";
          break;
        case Prayer.maghrib:
          nextTime = prayerTimes.maghrib;
          pName = "المغرب";
          break;
        case Prayer.isha:
          nextTime = prayerTimes.isha;
          pName = "العشاء";
          break;
        case Prayer.sunrise:
          nextTime = prayerTimes
              .sunrise; // Not usually considered a prayer in UI, but adhan might return it
          pName = "الشروق";
          break;
        case Prayer.none:
          break;
      }

      if (next == Prayer.none || nextTime == null) {
        // Calculate tomorrow's Fajr
        final tomorrow = DateComponents.from(now.add(const Duration(days: 1)));
        final tomorrowTimes = PrayerTimes(prayerTimes.coordinates, tomorrow,
            prayerTimes.calculationParameters);
        nextTime = tomorrowTimes.fajr;
        pName = "الفجر";
      }

      _nextPrayerName = pName;
      _timeUntilNext = nextTime.difference(now);

      if (mounted) setState(() {});
    }
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return "00:00:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String h = twoDigits(d.inHours);
    String m = twoDigits(d.inMinutes.remainder(60));
    String s = twoDigits(d.inSeconds.remainder(60));
    return "$h:$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PrayerTimesCubit, PrayerTimesState>(
      listener: (context, state) {
        if (state is PrayerTimesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is PrayerTimesSetup) {
          _showSetupBottomSheet();
        }
      },
      builder: (context, state) {
        if (state is PrayerTimesLoading) {
          return const Center(
              child: CircularProgressIndicator(color: accentColor));
        } else if (state is PrayerTimesLoaded) {
          return _buildLoadedUi(state);
        } else {
          // Initial / Error state -> show placeholder
          return _buildPlaceholder();
        }
      },
    );
  }

  Widget _buildPlaceholder() {
    return GestureDetector(
      onTap: () => context.read<PrayerTimesCubit>().showSetup(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withOpacity(0.5)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mosque, color: accentColor, size: 40),
            SizedBox(height: 12),
            Text(
              "اضغط لمعرفة أوقات الصلاة",
              style: TextStyle(
                color: accentColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedUi(PrayerTimesLoaded state) {
    final times = state.prayerTimes;
    final timeFormat = DateFormat("h:mm");

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Top portion (Dome and small cards)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Right Section: Big Dome
                  Expanded(
                    flex: 3,
                    child: ClipPath(
                      clipper: DomeClipper(),
                      child: Container(
                        color: cardColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 10),
                            const Icon(Icons.dark_mode,
                                color: accentColor, size: 36), // Crescent
                            const SizedBox(height: 8),
                            Text(
                              state.cityNameArabic,
                              style: const TextStyle(
                                color: accentColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              state.cityNameEnglish,
                              style: TextStyle(
                                color: accentColor.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Middle Section: 5 Prayers
                  Expanded(
                    flex: 7,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSmallDome("الفجر",
                              timeFormat.format(times.fajr), Icons.nights_stay),
                          _buildSmallDome("الظهر",
                              timeFormat.format(times.dhuhr), Icons.wb_sunny),
                          _buildSmallDome("العصر", timeFormat.format(times.asr),
                              Icons.cloud),
                          _buildSmallDome(
                              "المغرب",
                              timeFormat.format(times.maghrib),
                              Icons.wb_twilight),
                          _buildSmallDome("العشاء",
                              timeFormat.format(times.isha), Icons.mode_night),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Section: Remaining time
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: const BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "الصلاة القادمة: $_nextPrayerName",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "باقي: ${_formatDuration(_timeUntilNext)}",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallDome(String name, String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ClipPath(
        clipper: DomeClipper(),
        child: Container(
          width: 55,
          color: cardColor,
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(height: 4),
              Text(
                name,
                style: const TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(
                    color: accentColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSetupBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "إعداد أوقات الصلاة",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accentColor),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                icon: const Icon(Icons.location_on),
                label: const Text("تحديد الموقع تلقائياً"),
                onPressed: () {
                  Navigator.pop(bottomSheetContext);
                  context.read<PrayerTimesCubit>().autoDetectLocation();
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: bgColor,
                  foregroundColor: accentColor,
                  side: const BorderSide(color: accentColor),
                  minimumSize: const Size(double.infinity, 50),
                ),
                icon: const Icon(Icons.map),
                label: const Text("اختيار المدينة يدوياً"),
                onPressed: () {
                  Navigator.pop(bottomSheetContext);
                  _showCitySelectionDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCitySelectionDialog() {
    // Predefined list of major cities
    final cities = [
      {'ar': 'مكة المكرمة', 'en': 'Mecca', 'lat': 21.3891, 'lng': 39.8579},
      {'ar': 'المدينة المنورة', 'en': 'Medina', 'lat': 24.5247, 'lng': 39.5692},
      {'ar': 'الرياض', 'en': 'Riyadh', 'lat': 24.7136, 'lng': 46.6753},
      {'ar': 'أبوظبي', 'en': 'Abu Dhabi', 'lat': 24.4539, 'lng': 54.3773},
      {'ar': 'دبي', 'en': 'Dubai', 'lat': 25.2048, 'lng': 55.2708},
      {'ar': 'القاهرة', 'en': 'Cairo', 'lat': 30.0444, 'lng': 31.2357},
      {'ar': 'عمان', 'en': 'Amman', 'lat': 31.9454, 'lng': 35.9284},
      {'ar': 'القدس', 'en': 'Jerusalem', 'lat': 31.7683, 'lng': 35.2137},
      {'ar': 'الكويت', 'en': 'Kuwait', 'lat': 29.3759, 'lng': 47.9774},
      {'ar': 'الدوحة', 'en': 'Doha', 'lat': 25.2854, 'lng': 51.5310},
      {'ar': 'المنامة', 'en': 'Manama', 'lat': 26.2235, 'lng': 50.5876},
      {'ar': 'مسقط', 'en': 'Muscat', 'lat': 23.5880, 'lng': 58.3829},
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("اختر المدينة",
              textAlign: TextAlign.center,
              style: TextStyle(color: accentColor)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: cities.length,
              itemBuilder: (context, index) {
                final city = cities[index];
                return ListTile(
                  title: Text(city['ar'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(city['en'] as String),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    this.context.read<PrayerTimesCubit>().setManualCity(
                          city['lat'] as double,
                          city['lng'] as double,
                          city['ar'] as String,
                          city['en'] as String,
                        );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
