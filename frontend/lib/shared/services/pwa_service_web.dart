import 'dart:js_interop';

@JS('gastosClarosPwa')
external JSAny? get _bridge;

@JS('gastosClarosPwa.getToken')
external JSString? _getToken();

@JS('gastosClarosPwa.setToken')
external void _setToken(JSString token);

@JS('gastosClarosPwa.clearToken')
external JSPromise<JSAny?> _clearToken();

@JS('gastosClarosPwa.notificationPermission')
external JSString _notificationPermission();

@JS('gastosClarosPwa.install')
external JSPromise<JSString> _install();

@JS('gastosClarosPwa.requestNotifications')
external JSPromise<JSString> _requestNotifications();

@JS('gastosClarosPwa.notifySaved')
external JSPromise<JSBoolean> _notifySaved(JSString type, JSNumber amount, JSString description);

class PwaService {
  static bool get isAvailable => _bridge != null;
  static String? get savedToken => isAvailable ? _getToken()?.toDart : null;
  static void setToken(String token) {
    if (isAvailable) _setToken(token.toJS);
  }
  static Future<void> clearToken() async {
    if (isAvailable) await _clearToken().toDart;
  }
  static String get notificationPermission =>
      isAvailable ? _notificationPermission().toDart : 'unsupported';
  static Future<String> install() async => isAvailable
      ? (await _install().toDart).toDart : 'La instalación no está disponible aquí.';
  static Future<String> requestNotifications() async => isAvailable
      ? (await _requestNotifications().toDart).toDart : 'unsupported';
  static Future<bool> notifySaved(String type, double amount, String description) async {
    if (!isAvailable) return false;
    try {
      return (await _notifySaved(type.toJS, amount.toJS, description.toJS).toDart).toDart;
    } catch (_) {
      return false;
    }
  }
}
