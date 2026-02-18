// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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

  @override
  String get onboardingPage_Title => 'Welcome To CoTask';

  @override
  String get onboardingPage_Description =>
      'Create personal or collaborative tasks with others in real-time ';

  @override
  String get onboardingPage_CreateAccount => 'Create Your Account';

  @override
  String get onboardingPage_ContinueAsGuest => 'Continue As Guest';

  @override
  String get onboardingPage_AlreadyHaveAccount => 'Already have an account?';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get confirm => 'Confirm';

  @override
  String get tasks => 'Tasks';

  @override
  String get language => 'Language';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get logout => 'Logout';

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
  String get signInPage_Title => 'Sign In Your Account';

  @override
  String get email => 'Email';

  @override
  String get email_Field => 'Enter email';

  @override
  String get password => 'Password';

  @override
  String get password_Field => 'Enter password';

  @override
  String get signInPage_ForgotPassword => 'Forgot Password?';

  @override
  String get passwordRestPage_Title => 'Reset Your Password';

  @override
  String get passwordRestPage_Description =>
      'Enter your email to receive a link to reset your password';

  @override
  String get passwordRestPage_ResendEmail => 'Resend email in';

  @override
  String get signInPage_NotAUser => 'Not a user?';

  @override
  String get signInPage_GoogleSignIn => 'Sign in with Google';

  @override
  String get signUpPage_Title => 'Create Your Account';

  @override
  String get signUpPage_Username => 'Username';

  @override
  String get signUpPage_Username_Field => 'Enter username';

  @override
  String get signUpPage_FirstName => 'First Name';

  @override
  String get signUpPage_LastName => 'Last Name';

  @override
  String get signUpPage_Name_Field => 'Enter name';

  @override
  String get signUpPage_ConfirmPassword => 'Confirm Password';

  @override
  String get signUpPage_ConfirmPassword_Field => 'Enter password again';

  @override
  String get signUpPage_AlreadyHaveAccount => 'Already have an account?';

  @override
  String get signUpPage_GoogleSignUp => 'Sign up with Google';

  @override
  String get settingsPage_Title => 'Settings';

  @override
  String get settingsPage_ChangeMyPassword => 'Change My Password';

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
