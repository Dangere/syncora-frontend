/// Info returned from Google when registering to be displayed to the user when they fill the [GoogleRegisterFilledInfo]
class GoogleUserInfo {
  final String token;
  final String email;
  final String firstName;
  final String lastName;

  GoogleUserInfo(
      {required this.token,
      required this.email,
      required this.firstName,
      required this.lastName});
}
