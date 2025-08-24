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
  String get loginPage_guestPopTitle => 'Guest Username';

  @override
  String get loginPage_guestPopError_empty => 'Guest username cannot be empty';

  @override
  String get loginPage_guestPopError_invalid => 'invalid username format';

  @override
  String get groupsFrontPageTitle => 'Groups';
}
