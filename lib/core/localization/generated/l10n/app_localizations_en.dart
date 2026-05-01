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
  String get loginPage_guestPopError_invalid => 'Invalid username format';

  @override
  String get groupsList_Title => 'Groups';

  @override
  String get groupPage_TasksTitle => 'Group Tasks';

  @override
  String get groupPage_AddTaskButton => 'Add Task';

  @override
  String get groupInfoPage_Title => 'Group Info';

  @override
  String get groupInfoPage_NoDescription => 'No description';

  @override
  String get groupInfoPage_CreatedIn => 'Created in';

  @override
  String get groupInfoPopup_Alert_NoMembers => 'Group has no members';

  @override
  String get onboardingPage_Title => 'Welcome To CoTask';

  @override
  String get onboardingPage_Description =>
      'Create personal or collaborative tasks with others in real-time';

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
  String get save => 'Save';

  @override
  String get owner => 'Owner';

  @override
  String get rename => 'Rename';

  @override
  String get remove => 'Remove';

  @override
  String get add => 'Add';

  @override
  String get create => 'Create';

  @override
  String get edit => 'Edit';

  @override
  String get general => 'General';

  @override
  String get name => 'Name';

  @override
  String get description => 'Description';

  @override
  String get members => 'Members';

  @override
  String get moreOptions => 'More Options';

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
  String get filter_Pending => 'Pending';

  @override
  String get filter_Assigned => 'Assigned';

  @override
  String get filter_All => 'All';

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
  String get settingsPage_ConfirmLogout => 'Are you sure you want to logout?';

  @override
  String get settingsPage_ConfirmGuestLogout =>
      'If you log out as a guest your data will be deleted';

  @override
  String get dashboardPage_MyGroups => 'My Groups';

  @override
  String get dashboardPage_CreateGroup => 'Create Group';

  @override
  String get dashboardPage_SearchGroups => 'Search for a group';

  @override
  String get dashboardPage_Monthly_Progress => 'Your Monthly Progress';

  @override
  String get cropImagePage_Title => 'Crop Image';

  @override
  String get cropImagePage_CropButton => 'Crop';

  @override
  String get profileViewPage_TitleMyProfile => 'My Profile';

  @override
  String get profileViewPage_TitleProfile => 'Profile';

  @override
  String get profileViewPage_MyInfoTitle => 'My Information';

  @override
  String get profileViewPage_InfoTitle => 'Information';

  @override
  String get profileViewPage_ProfileChange => 'Your profile has been updated';

  @override
  String get image_NoImagePicked => 'No image picked';

  @override
  String get groupPopup_EditTitle => 'Edit Group Title';

  @override
  String get groupPopup_EditDescription => 'Edit Group Description';

  @override
  String get groupPopup_RemoveUser_Title =>
      'Are you sure you want to remove this user from the group?';

  @override
  String get groupPopup_CreateGroup_Title => 'New Group';

  @override
  String get groupPopup_AddMember_Title => 'Add a New Member';

  @override
  String get groupPopup_GroupTitle_Label => 'Group Title';

  @override
  String get groupPopup_GroupTitle_Hint => 'Enter the title';

  @override
  String get groupPopup_GroupDescription_Label => 'Group Description';

  @override
  String get groupPopup_GroupDescription_Hint => 'Enter the description';

  @override
  String get groupPopup_MoreInfo => 'More Info About This Group';

  @override
  String get groupPopup_RenameGroup => 'Rename Group';

  @override
  String get groupPopup_DeleteGroup_Confirm =>
      'Are you sure you want to delete this group?';

  @override
  String get groupPopup_DeleteGroup => 'Delete Group';

  @override
  String get groupPopup_LeaveGroup => 'Leave Group';

  @override
  String get groupPopup_LeaveGroup_Confirm =>
      'Are you sure you want to leave this group?';

  @override
  String get groupPopup_Alert_NoUsersSelected => 'No users selected';

  @override
  String get groupPopup_Alert_CantAddSelf => 'You can\'t add yourself';

  @override
  String get groupPopup_Alert_UserAlreadyAdded => 'User already added';

  @override
  String get groupPopup_Error_UserNotFound => 'User not found';

  @override
  String get settingsPopup_Password_Reset_title => 'Password Reset Link';

  @override
  String get settingsPopup_Password_Reset =>
      'A link has been sent to your email to change your password';

  @override
  String get settingsPopup_Password_NotSent => 'Didn’t receive a link?';

  @override
  String get settingsPopup_Password_Resend => 'Resend Email';

  @override
  String get settingsPopup_Password_Alert => 'Password reset email sent';

  @override
  String get notification_Backend_Connected => 'Connected to server';

  @override
  String get validation_GroupTitle_Empty => 'Empty title';

  @override
  String get validation_GroupTitle_Unchanged => 'Title is not changed';

  @override
  String get validation_GroupTitle_Invalid => 'Invalid title';

  @override
  String get validation_GroupTitle_Create_Empty => 'Empty group title';

  @override
  String get validation_GroupTitle_Create_Invalid => 'Invalid group title';

  @override
  String get validation_GroupDescription_Empty => 'Empty description';

  @override
  String get validation_GroupDescription_Unchanged =>
      'Description is not changed';

  @override
  String get validation_GroupDescription_Invalid => 'Invalid description';

  @override
  String get validation_GroupDescription_Create_Empty =>
      'Empty group description';

  @override
  String get validation_GroupDescription_Create_Invalid =>
      'Invalid group description';

  @override
  String get validation_Username_Empty => 'Empty username';

  @override
  String get validation_Username_Invalid => 'Invalid username';

  @override
  String get validation_Name_Empty => 'Empty Name';

  @override
  String get validation_Name_Invalid => 'Invalid Name';

  @override
  String get validation_Email_Empty => 'Empty Email';

  @override
  String get validation_Email_Invalid => 'Invalid Email';

  @override
  String get validation_Password_Empty => 'Empty Password';

  @override
  String get validation_Password_Invalid =>
      'Invalid Password, Password must be between 6 and 16 characters';

  @override
  String get validation_Password_Not_Matching => 'Password is not matching';

  @override
  String get appError_GroupNotFound => 'Group not found';

  @override
  String get appError_GroupDetailsUnchanged => 'Group details are unchanged';

  @override
  String get appError_TaskNotFound => 'Task not found';

  @override
  String get appError_AccessDenied =>
      'You don\'t have permission to perform this action';

  @override
  String get appError_OwnerCannotPerformAction =>
      'The group owner cannot perform this action';

  @override
  String get appError_SharedUserCannotPerformAction =>
      'You don\'t have permission to perform this action';

  @override
  String get appError_UserNotFound => 'User not found';

  @override
  String get appError_UserAlreadyVerified => 'This account is already verified';

  @override
  String get appError_UserNotAssignedToTask =>
      'This user is not assigned to the task';

  @override
  String get appError_InvalidUrl => 'The provided URL is invalid';

  @override
  String get appError_InvalidCredentials => 'Incorrect email or password';

  @override
  String get appError_EmailAlreadyInUse =>
      'This email address is already in use';

  @override
  String get appError_UsernameAlreadyInUse => 'This username is already taken';

  @override
  String get appError_CredentialsAlreadyInUse =>
      'These credentials are already associated with an account';

  @override
  String get appError_InvalidToken =>
      'This link has expired or is no longer valid';

  @override
  String get appError_InvalidGoogleToken =>
      'Google sign-in failed. Please try again';

  @override
  String get appError_UserAlreadyGranted =>
      'This user is already a member of the group';

  @override
  String get appError_UserAlreadyRevoked =>
      'This user is not a member of the group';

  @override
  String get appError_NoUsernamesProvided => 'No usernames were provided';

  @override
  String get appError_InternalError =>
      'Something went wrong. Please try again later';

  @override
  String get appError_EmailSendFailed =>
      'We couldn\'t send the email. Please try again later';

  @override
  String get appError_NoFilePicked => 'No file was selected';

  @override
  String get appError_SessionExpired =>
      'Your session has ended. Please log in again';

  @override
  String get appError_OfflineAccessDenied =>
      'You must be online to perform this action';

  @override
  String get appError_Unknown =>
      'An unexpected error occurred. Please try again';

  @override
  String get appError_Dio_ConnectionTimeout =>
      'Connection timed out. Please check your internet and try again';

  @override
  String get appError_Dio_SendTimeout =>
      'Failed to send your request. Please try again';

  @override
  String get appError_Dio_ReceiveTimeout =>
      'The server is taking too long to respond. Please try again later';

  @override
  String get appError_Dio_BadCertificate =>
      'Unable to verify the server. Please try again on a secure network';

  @override
  String get appError_Dio_RequestCancelled =>
      'Request was cancelled. Please try again';

  @override
  String get appError_Dio_ConnectionError =>
      'Unable to reach the server. Please check your connection';

  @override
  String get appError_HTTP_BadRequest =>
      'Your request could not be processed. Please try again';

  @override
  String get appError_HTTP_ResourceNotFound =>
      'The requested resource could not be found';

  @override
  String get appError_HTTP_RequestTimeout =>
      'The request timed out. Please try again';

  @override
  String get appError_HTTP_UnprocessableData =>
      'The submitted data is invalid. Please check your input and try again';

  @override
  String get appError_HTTP_TooManyRequests =>
      'Too many requests. Please wait a moment and try again';
}
