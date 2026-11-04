class AppConstants {
  static const String appName = 'BELANJAKU';
  static const String appVersion = '1.0.0';
  static const int buildNumber = 15;
  static const String appTagline = 'Belanja, foto struk, beres — semua tercatat rapi';

  // GitHub Repository for OTA Updates
  static const String githubOwner = 'bengkelgadget-code';
  static const String githubRepo = 'BELANJAKU';

  static const String defaultUserName = 'boy';
  static const String defaultCurrency = 'IDR';
  static const String defaultTimezone = 'Asia/Makassar';

  // Nominal limits
  static const int maxAmount = 999999999999; // Rp 999.999.999.999
  static const int minAmount = 1;

  // Budget thresholds
  static const double budgetWarningThreshold = 0.8; // 80%
  static const double budgetDangerThreshold = 1.0; // 100%
}
