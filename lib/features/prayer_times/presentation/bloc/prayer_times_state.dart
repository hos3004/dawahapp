import 'package:equatable/equatable.dart';
import 'package:adhan/adhan.dart';

abstract class PrayerTimesState extends Equatable {
  const PrayerTimesState();

  @override
  List<Object?> get props => [];
}

class PrayerTimesInitial extends PrayerTimesState {}

class PrayerTimesSetup extends PrayerTimesState {}

class PrayerTimesLoading extends PrayerTimesState {}

class PrayerTimesLoaded extends PrayerTimesState {
  final String cityNameArabic;
  final String cityNameEnglish;
  final PrayerTimes prayerTimes;

  const PrayerTimesLoaded({
    required this.cityNameArabic,
    required this.cityNameEnglish,
    required this.prayerTimes,
  });

  @override
  List<Object?> get props => [cityNameArabic, cityNameEnglish, prayerTimes];
}

class PrayerTimesError extends PrayerTimesState {
  final String message;

  const PrayerTimesError(this.message);

  @override
  List<Object?> get props => [message];
}
