import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// The guest login button
  ///
  /// In en, this message translates to:
  /// **'Login as Guest'**
  String get guestLoginButton;

  /// The guest pop up title
  ///
  /// In en, this message translates to:
  /// **'Guest Username'**
  String get loginPage_guestPopTitle;

  /// The guest pop up error when text is empty
  ///
  /// In en, this message translates to:
  /// **'Guest username cannot be empty'**
  String get loginPage_guestPopError_empty;

  /// The guest pop up error when text is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid username format'**
  String get loginPage_guestPopError_invalid;

  /// The title of the groups front page
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsList_Title;

  /// The title of the group page tasks
  ///
  /// In en, this message translates to:
  /// **'Group Tasks'**
  String get groupPage_TasksTitle;

  /// The add task button
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get groupPage_AddTaskButton;

  /// The title of the onboarding page
  ///
  /// In en, this message translates to:
  /// **'Welcome To CoTask'**
  String get onboardingPage_Title;

  /// The description of the onboarding page
  ///
  /// In en, this message translates to:
  /// **'Create personal or collaborative tasks with others in real-time'**
  String get onboardingPage_Description;

  /// No description provided for @onboardingPage_CreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Your Account'**
  String get onboardingPage_CreateAccount;

  /// No description provided for @onboardingPage_ContinueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue As Guest'**
  String get onboardingPage_ContinueAsGuest;

  /// No description provided for @onboardingPage_AlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get onboardingPage_AlreadyHaveAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Generic confirm action label
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Generic save action label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// Generic rename action label
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// Generic remove action label
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Generic add action label
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Generic create action label
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Generic more options label
  ///
  /// In en, this message translates to:
  /// **'More Options'**
  String get moreOptions;

  /// No description provided for @filter_Completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get filter_Completed;

  /// No description provided for @filter_InProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get filter_InProgress;

  /// No description provided for @filter_Owned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get filter_Owned;

  /// No description provided for @filter_Shared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get filter_Shared;

  /// No description provided for @filter_Newest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get filter_Newest;

  /// No description provided for @filter_Oldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get filter_Oldest;

  /// No description provided for @filter_Pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get filter_Pending;

  /// No description provided for @filter_Assigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get filter_Assigned;

  /// No description provided for @filter_All.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filter_All;

  /// No description provided for @signInPage_Title.
  ///
  /// In en, this message translates to:
  /// **'Sign In Your Account'**
  String get signInPage_Title;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @email_Field.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get email_Field;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @password_Field.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get password_Field;

  /// No description provided for @signInPage_ForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get signInPage_ForgotPassword;

  /// No description provided for @passwordRestPage_Title.
  ///
  /// In en, this message translates to:
  /// **'Reset Your Password'**
  String get passwordRestPage_Title;

  /// No description provided for @passwordRestPage_Description.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a link to reset your password'**
  String get passwordRestPage_Description;

  /// No description provided for @passwordRestPage_ResendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend email in'**
  String get passwordRestPage_ResendEmail;

  /// No description provided for @signInPage_NotAUser.
  ///
  /// In en, this message translates to:
  /// **'Not a user?'**
  String get signInPage_NotAUser;

  /// No description provided for @signInPage_GoogleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInPage_GoogleSignIn;

  /// No description provided for @signUpPage_Title.
  ///
  /// In en, this message translates to:
  /// **'Create Your Account'**
  String get signUpPage_Title;

  /// No description provided for @signUpPage_Username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get signUpPage_Username;

  /// No description provided for @signUpPage_Username_Field.
  ///
  /// In en, this message translates to:
  /// **'Enter username'**
  String get signUpPage_Username_Field;

  /// No description provided for @signUpPage_FirstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get signUpPage_FirstName;

  /// No description provided for @signUpPage_LastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get signUpPage_LastName;

  /// No description provided for @signUpPage_Name_Field.
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get signUpPage_Name_Field;

  /// No description provided for @signUpPage_ConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get signUpPage_ConfirmPassword;

  /// No description provided for @signUpPage_ConfirmPassword_Field.
  ///
  /// In en, this message translates to:
  /// **'Enter password again'**
  String get signUpPage_ConfirmPassword_Field;

  /// No description provided for @signUpPage_AlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get signUpPage_AlreadyHaveAccount;

  /// No description provided for @signUpPage_GoogleSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get signUpPage_GoogleSignUp;

  /// No description provided for @settingsPage_Title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsPage_Title;

  /// No description provided for @settingsPage_ChangeMyPassword.
  ///
  /// In en, this message translates to:
  /// **'Change My Password'**
  String get settingsPage_ChangeMyPassword;

  /// No description provided for @settingsPage_ConfirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get settingsPage_ConfirmLogout;

  /// No description provided for @settingsPage_ConfirmGuestLogout.
  ///
  /// In en, this message translates to:
  /// **'If you log out as a guest your data will be deleted'**
  String get settingsPage_ConfirmGuestLogout;

  /// No description provided for @dashboardPage_MyGroups.
  ///
  /// In en, this message translates to:
  /// **'My Groups'**
  String get dashboardPage_MyGroups;

  /// No description provided for @dashboardPage_CreateGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get dashboardPage_CreateGroup;

  /// No description provided for @dashboardPage_SearchGroups.
  ///
  /// In en, this message translates to:
  /// **'Search for a group'**
  String get dashboardPage_SearchGroups;

  /// No description provided for @cropImagePage_Title.
  ///
  /// In en, this message translates to:
  /// **'Crop Image'**
  String get cropImagePage_Title;

  /// No description provided for @cropImagePage_CropButton.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get cropImagePage_CropButton;

  /// No description provided for @profileViewPage_TitleMyProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileViewPage_TitleMyProfile;

  /// No description provided for @profileViewPage_TitleProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileViewPage_TitleProfile;

  /// No description provided for @profileViewPage_MyInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'My Information'**
  String get profileViewPage_MyInfoTitle;

  /// No description provided for @profileViewPage_InfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get profileViewPage_InfoTitle;

  /// No description provided for @profileViewPage_ProfileChange.
  ///
  /// In en, this message translates to:
  /// **'Your profile has been updated'**
  String get profileViewPage_ProfileChange;

  /// No description provided for @image_NoImagePicked.
  ///
  /// In en, this message translates to:
  /// **'No image picked'**
  String get image_NoImagePicked;

  /// Dialog title for editing a group's title
  ///
  /// In en, this message translates to:
  /// **'Edit Group Title'**
  String get groupPopup_EditTitle;

  /// Dialog title for editing a group's description
  ///
  /// In en, this message translates to:
  /// **'Edit Group Description'**
  String get groupPopup_EditDescription;

  /// Confirmation dialog title when removing a user from a group
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this user from the group?'**
  String get groupPopup_RemoveUser_Title;

  /// Dialog title for creating a new group
  ///
  /// In en, this message translates to:
  /// **'New Group'**
  String get groupPopup_CreateGroup_Title;

  /// Dialog title for adding a new member to a group
  ///
  /// In en, this message translates to:
  /// **'Add a New Member'**
  String get groupPopup_AddMember_Title;

  /// Label for the group title input field
  ///
  /// In en, this message translates to:
  /// **'Group Title'**
  String get groupPopup_GroupTitle_Label;

  /// Hint text for the group title input field
  ///
  /// In en, this message translates to:
  /// **'Enter the title'**
  String get groupPopup_GroupTitle_Hint;

  /// Label for the group description input field
  ///
  /// In en, this message translates to:
  /// **'Group Description'**
  String get groupPopup_GroupDescription_Label;

  /// Hint text for the group description input field
  ///
  /// In en, this message translates to:
  /// **'Enter the description'**
  String get groupPopup_GroupDescription_Hint;

  /// Button label to view more info about a group
  ///
  /// In en, this message translates to:
  /// **'More Info About This Group'**
  String get groupPopup_MoreInfo;

  /// Button label to rename a group
  ///
  /// In en, this message translates to:
  /// **'Rename Group'**
  String get groupPopup_RenameGroup;

  /// Button label to delete a group (shown to owners)
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get groupPopup_DeleteGroup;

  /// Button label to leave a group (shown to non-owners)
  ///
  /// In en, this message translates to:
  /// **'Leave Group'**
  String get groupPopup_LeaveGroup;

  /// Alert shown when confirming with no users selected
  ///
  /// In en, this message translates to:
  /// **'No users selected'**
  String get groupPopup_Alert_NoUsersSelected;

  /// Alert shown when the user tries to add themselves
  ///
  /// In en, this message translates to:
  /// **'You can\'t add yourself'**
  String get groupPopup_Alert_CantAddSelf;

  /// Alert shown when a user is already in the selection or group
  ///
  /// In en, this message translates to:
  /// **'User already added'**
  String get groupPopup_Alert_UserAlreadyAdded;

  /// Error shown when a searched user does not exist
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get groupPopup_Error_UserNotFound;

  /// Validation error when the group title field is empty
  ///
  /// In en, this message translates to:
  /// **'Empty title'**
  String get validation_GroupTitle_Empty;

  /// Validation error when the new group title matches the old one
  ///
  /// In en, this message translates to:
  /// **'Title is not changed'**
  String get validation_GroupTitle_Unchanged;

  /// Validation error when the group title format is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid title'**
  String get validation_GroupTitle_Invalid;

  /// Validation error when the group title is empty during creation
  ///
  /// In en, this message translates to:
  /// **'Empty group title'**
  String get validation_GroupTitle_Create_Empty;

  /// Validation error when the group title format is invalid during creation
  ///
  /// In en, this message translates to:
  /// **'Invalid group title'**
  String get validation_GroupTitle_Create_Invalid;

  /// Validation error when the group description field is empty
  ///
  /// In en, this message translates to:
  /// **'Empty description'**
  String get validation_GroupDescription_Empty;

  /// Validation error when the new description matches the old one
  ///
  /// In en, this message translates to:
  /// **'Description is not changed'**
  String get validation_GroupDescription_Unchanged;

  /// Validation error when the group description format is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid description'**
  String get validation_GroupDescription_Invalid;

  /// Validation error when the group description is empty during creation
  ///
  /// In en, this message translates to:
  /// **'Empty group description'**
  String get validation_GroupDescription_Create_Empty;

  /// Validation error when the group description format is invalid during creation
  ///
  /// In en, this message translates to:
  /// **'Invalid group description'**
  String get validation_GroupDescription_Create_Invalid;

  /// Validation error when the username field is empty
  ///
  /// In en, this message translates to:
  /// **'Empty username'**
  String get validation_Username_Empty;

  /// Validation error when the username format is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid username'**
  String get validation_Username_Invalid;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
