class User {
  User(
      {required this.id,
      required this.username,
      required this.email,
      this.pfpURL});
  int id;
  String username;
  String email;
  String? pfpURL;

  factory User.fromJson(Map<String, dynamic> json) => User(
      id: json["id"],
      username: json["username"],
      email: json["email"],
      pfpURL: json["profilePictureURL"]);
}
