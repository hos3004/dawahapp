import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'prayer_times_state.dart';
import '../../../islamic_utilities/utils/smart_prayer_mapper.dart';

class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  PrayerTimesCubit() : super(PrayerTimesInitial());

  static const String _prefKeyIsSetupDone = 'is_prayer_setup_done';
  static const String _prefKeyLat = 'prayer_lat';
  static const String _prefKeyLng = 'prayer_lng';
  static const String _prefKeyCityAr = 'prayer_city_ar';
  static const String _prefKeyCityEn = 'prayer_city_en';
  static const String _prefKeyIsoCountry = 'prayer_iso_country';

  Future<void> checkSetup() async {
    final prefs = await SharedPreferences.getInstance();
    final isSetupDone = prefs.getBool(_prefKeyIsSetupDone) ?? false;

    if (isSetupDone) {
      final lat = prefs.getDouble(_prefKeyLat) ?? 0.0;
      final lng = prefs.getDouble(_prefKeyLng) ?? 0.0;
      final cityAr = prefs.getString(_prefKeyCityAr) ?? '';
      final cityEn = prefs.getString(_prefKeyCityEn) ?? '';
      final isoCountry = prefs.getString(_prefKeyIsoCountry) ?? '';

      _calculateTimes(lat, lng, cityAr, cityEn, isoCountry);
    }
  }

  void showSetup() {
    emit(PrayerTimesSetup());
  }

  Future<void> autoDetectLocation() async {
    emit(PrayerTimesLoading());
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(const PrayerTimesError("خدمات الموقع غير مفعلة."));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          emit(const PrayerTimesError("تم رفض صلاحية الموقع."));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        emit(const PrayerTimesError("صلاحيات الموقع مرفوضة دائمًا."));
        return;
      }

      Position position = await Geolocator.getCurrentPosition();

      await _saveAndCalculate(
        position.latitude,
        position.longitude,
        "موقعي الحالي",
        "My Location",
      );
    } catch (e) {
      emit(PrayerTimesError(e.toString()));
    }
  }

  Future<void> setManualCity(
      double lat, double lng, String cityAr, String cityEn) async {
    emit(PrayerTimesLoading());
    await _saveAndCalculate(lat, lng, cityAr, cityEn);
  }

  Future<void> _saveAndCalculate(
      double lat, double lng, String cityAr, String cityEn) async {
    final prefs = await SharedPreferences.getInstance();

    String isoCountry = prefs.getString(_prefKeyIsoCountry) ?? '';

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        isoCountry = placemarks.first.isoCountryCode ?? '';
      }
    } catch (e) {
      isoCountry = '';
    }

    await prefs.setBool(_prefKeyIsSetupDone, true);
    await prefs.setDouble(_prefKeyLat, lat);
    await prefs.setDouble(_prefKeyLng, lng);
    await prefs.setString(_prefKeyCityAr, cityAr);
    await prefs.setString(_prefKeyCityEn, cityEn);
    await prefs.setString(_prefKeyIsoCountry, isoCountry);

    _calculateTimes(lat, lng, cityAr, cityEn, isoCountry);
  }

  void _calculateTimes(double lat, double lng, String cityAr, String cityEn,
      String isoCountryCode) {
    final coordinates = Coordinates(lat, lng);

    CalculationParameters params;
    if (isoCountryCode.isNotEmpty) {
      params = SmartPrayerMapper.getParametersForCountry(isoCountryCode);
    } else {
      params = CalculationMethod.muslim_world_league.getParameters();
      params.madhab = Madhab.shafi;
    }

    final date = DateComponents.from(DateTime.now());
    final prayerTimes = PrayerTimes(coordinates, date, params);

    emit(PrayerTimesLoaded(
      cityNameArabic: cityAr,
      cityNameEnglish: cityEn,
      prayerTimes: prayerTimes,
    ));
  }
}
