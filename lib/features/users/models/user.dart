import 'package:flutter_riverpod/flutter_riverpod.dart';

class User {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String? pfpURL;

  User(
      {required this.id,
      required this.username,
      required this.firstName,
      required this.lastName,
      required this.email,
      this.pfpURL});

  factory User.fromJson(Map<String, dynamic> json) => User(
      id: json["id"],
      username: json["username"],
      firstName: json["firstName"],
      lastName: json["lastName"],
      email: json["email"],
      pfpURL: json["profilePictureURL"]);

  Map<String, dynamic> toJson() => {
        "id": id,
        "username": username,
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "profilePictureURL": pfpURL
      };

  factory User.guest(String username) => User(
      id: -1,
      username: username,
      firstName: "john",
      lastName: "doe",
      email: "",
      pfpURL: null);

  User copyWith(
          {String? username,
          String? firstName,
          String? lastName,
          String? email,
          String? pfpURL}) =>
      User(
          id: id,
          username: username ?? this.username,
          firstName: firstName ?? this.firstName,
          lastName: lastName ?? this.lastName,
          email: email ?? this.email,
          pfpURL: pfpURL ?? this.pfpURL);

  @override
  String toString() {
    return "User{id: $id, username: $username, firstName: $firstName, lastName: $lastName, email: $email, pfpURL: $pfpURL}";
  }
}
