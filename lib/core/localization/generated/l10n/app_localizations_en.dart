import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get helloWorld => 'Hello World!';

  @override
  String get loginPageTitle => 'Login';

  @override
  String get loginButton => 'Login';

  @override
  String get guestLoginButton => 'Login as Guest';

  @override
  String get groupsFrontPageTitle => 'Groups';
}
