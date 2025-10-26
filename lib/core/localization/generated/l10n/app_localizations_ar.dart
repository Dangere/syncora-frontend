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

  @override
  String get loginPage_guestPopTitle => 'اسم الضيف';

  @override
  String get loginPage_guestPopError_empty => 'اسم الضيف لا يمكن ان يكون فارغ';

  @override
  String get loginPage_guestPopError_invalid => 'اسم الضيف غير معرف';

  @override
  String get registerPageTitle => 'التسجيل';

  @override
  String get groupsFrontPageTitle => 'المجموعات';
}
