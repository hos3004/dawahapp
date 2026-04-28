import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Reads Android device capabilities needed by the TV shell.
class TvPlatform {
  TvPlatform._();

  static const MethodChannel _channel =
      MethodChannel('com.daawahtv.app/device');

  static Future<bool> isAndroidTv() async {
    const bool forceTv =
        bool.fromEnvironment('FORCE_TV', defaultValue: false);

    if (forceTv) return true;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      return await _channel.invokeMethod<bool>('isAndroidTv') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
