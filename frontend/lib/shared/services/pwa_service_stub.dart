class PwaService {
  static bool get isAvailable => false;
  static String get notificationPermission => 'unsupported';

  static Future<String> install() async =>
      'Para instalar la PWA, abre GastosClaros en un navegador compatible.';

  static Future<String> requestNotifications() async => 'unsupported';

  static Future<bool> notifySaved(String type, double amount, String description) async => false;
  static String? get savedToken => null;
  static void setToken(String token) {}
  static Future<void> clearToken() async {}
}
