import 'app_localizations.dart';

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get helloWorld => 'هلا';

  @override
  String get loginPageTitle => 'تسجيل الدخول';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get guestLoginButton => 'تسجيل الدخول كضيف';
}
