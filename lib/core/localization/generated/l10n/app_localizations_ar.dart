// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get guestLoginButton => 'الدخول كضيف';

  @override
  String get loginPage_guestPopTitle => 'اسم مستخدم الضيف';

  @override
  String get loginPage_guestPopError_empty =>
      'لا يمكن ترك اسم مستخدم الضيف فارغًا';

  @override
  String get loginPage_guestPopError_invalid => 'تنسيق اسم المستخدم غير صالح';

  @override
  String get groupsFrontPageTitle => 'المجموعات';

  @override
  String get onboardingPage_Title => 'مرحبًا بك في CoTask';

  @override
  String get onboardingPage_Description =>
      'أنشئ مهام شخصية أو تعاونية مع الآخرين في الوقت الحقيقي';

  @override
  String get onboardingPage_CreateAccount => 'إنشاء حساب';

  @override
  String get onboardingPage_ContinueAsGuest => 'المتابعة كضيف';

  @override
  String get onboardingPage_AlreadyHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get confirm => 'تأكيد';

  @override
  String get tasks => 'المهام';

  @override
  String get language => 'اللغة';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get filter_Completed => 'Completed';

  @override
  String get filter_InProgress => 'In Progress';

  @override
  String get filter_Owned => 'Owned';

  @override
  String get filter_Shared => 'Shared';

  @override
  String get filter_Newest => 'Newest';

  @override
  String get filter_Oldest => 'Oldest';

  @override
  String get signInPage_Title => 'تسجيل الدخول إلى حسابك';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get email_Field => 'أدخل البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get password_Field => 'أدخل كلمة المرور';

  @override
  String get signInPage_ForgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get passwordRestPage_Title => 'إعادة تعيين كلمة المرور';

  @override
  String get passwordRestPage_Description =>
      'أدخل بريدك الإلكتروني لتلقي رابط إعادة تعيين كلمة المرور';

  @override
  String get passwordRestPage_ResendEmail => 'إعادة إرسال البريد خلال';

  @override
  String get signInPage_NotAUser => 'لست مستخدمًا بعد؟';

  @override
  String get signInPage_GoogleSignIn => 'تسجيل الدخول باستخدام Google';

  @override
  String get signUpPage_Title => 'إنشاء حسابك';

  @override
  String get signUpPage_Username => 'اسم المستخدم';

  @override
  String get signUpPage_Username_Field => 'أدخل اسم المستخدم';

  @override
  String get signUpPage_FirstName => 'الاسم الأول';

  @override
  String get signUpPage_LastName => 'اسم العائلة';

  @override
  String get signUpPage_Name_Field => 'أدخل الاسم';

  @override
  String get signUpPage_ConfirmPassword => 'تأكيد كلمة المرور';

  @override
  String get signUpPage_ConfirmPassword_Field => 'أعد إدخال كلمة المرور';

  @override
  String get signUpPage_AlreadyHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get signUpPage_GoogleSignUp => 'إنشاء حساب باستخدام Google';

  @override
  String get settingsPage_Title => 'الإعدادات';

  @override
  String get settingsPage_ChangeMyPassword => 'تغيير كلمة المرور';

  @override
  String get dashboardPage_MyGroups => 'My Groups';

  @override
  String get dashboardPage_CreateGroup => 'Create Group';

  @override
  String get dashboardPage_SearchGroups => 'Search for a group';

  @override
  String get cropImagePage_Title => 'Crop Image';

  @override
  String get cropImagePage_CropButton => 'Crop';

  @override
  String get profileViewPage_Title => 'My Profile';

  @override
  String get profileViewPage_ProfileChange => 'Your profile has been updated';

  @override
  String get image_NoImagePicked => 'No image picked';
}
