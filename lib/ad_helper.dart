import 'dart:io';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-4067749124990821~8624124965';
    } else {
      throw UnsupportedError('Unsupported');
    }
  }

    static String get bannerInterstatialUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-4067749124990821/5616131320';
    } else {
      throw UnsupportedError('Unsupported');
    }
  }
}
