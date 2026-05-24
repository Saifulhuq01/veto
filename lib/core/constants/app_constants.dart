/// App-wide constants for the Veto focus app.
class AppConstants {
  AppConstants._();

  // ── Timer ──
  static const int defaultTimerMinutes = 25;
  static const int defaultTimerSeconds = defaultTimerMinutes * 60;

  // ── Layout ──
  static const double containerPadding = 24.0;
  static const double gutterSpacing = 16.0;
  static const double navOffsetBottom = 24.0;
  static const double topBarHeight = 56.0;
  static const double timerCircleSize = 288.0;

  // ── Glass ──
  static const double blurSigmaHeavy = 48.0;
  static const double blurSigmaLight = 16.0;

  // ── MethodChannel ──
  static const String methodChannelName = 'com.veto.app/bridge';

  // ── SharedPreferences keys ──
  static const String prefsRulesKey = 'veto_deep_block_rules';
  static const String prefsTimerKey = 'veto_timer_duration';

  // ── Package names ──
  static const String youtubePackage = 'com.google.android.youtube';
  static const String instagramPackage = 'com.instagram.android';
}
