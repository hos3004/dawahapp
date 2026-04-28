import 'package:adhan/adhan.dart';

class SmartPrayerMapper {
  /// Returns the optimal CalculationParameters based on the ISO Country Code (e.g., 'TR', 'EG', 'SA').
  static CalculationParameters getParametersForCountry(String countryCode) {
    CalculationParameters params;

    switch (countryCode.toUpperCase()) {
      case 'TR': // Turkey
        params = CalculationMethod.turkey.getParameters();
        params.madhab = Madhab.hanafi;
        break;
      case 'EG': // Egypt
      case 'SD': // Sudan
        params = CalculationMethod.egyptian.getParameters();
        params.madhab = Madhab.shafi;
        break;
      case 'SA': // Saudi Arabia
      case 'AE': // UAE
      case 'KW': // Kuwait
      case 'BH': // Bahrain
      case 'OM': // Oman
      case 'YE': // Yemen
        params = CalculationMethod.umm_al_qura.getParameters();
        params.madhab = Madhab.shafi;
        break;
      case 'QA': // Qatar
        params = CalculationMethod.qatar.getParameters();
        params.madhab = Madhab.shafi;
        break;
      case 'PK': // Pakistan
      case 'IN': // India
      case 'BD': // Bangladesh
      case 'AF': // Afghanistan
        params = CalculationMethod.karachi.getParameters();
        params.madhab = Madhab.hanafi;
        break;
      case 'US': // USA
      case 'CA': // Canada
        params = CalculationMethod.north_america.getParameters();
        params.madhab = Madhab.shafi;
        break;
      case 'MA': // Morocco
      case 'DZ': // Algeria
      case 'TN': // Tunisia
        // Adjust for Maghreb region if specific method exists, otherwise MWL
        params = CalculationMethod.muslim_world_league.getParameters();
        params.madhab = Madhab.shafi;
        break;
      default:
        // Fallback for the rest of the world (Europe, etc.)
        params = CalculationMethod.muslim_world_league.getParameters();
        params.madhab = Madhab.shafi;
    }

    return params;
  }
}
