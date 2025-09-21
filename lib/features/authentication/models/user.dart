import 'package:color_hash/color_hash.dart';
import 'package:flutter/material.dart';

class User {
  final int id;
  final String username;
  final String email;
  final String? pfpURL;

  User(
      {required this.id,
      required this.username,
      required this.email,
      this.pfpURL});

  factory User.fromJson(Map<String, dynamic> json) => User(
      id: json["id"],
      username: json["username"],
      email: json["email"],
      pfpURL: json["profilePictureURL"]);

  Map<String, dynamic> toJson() => {
        "id": id,
        "username": username,
        "email": email,
        "profilePictureURL": pfpURL
      };

  factory User.guest(String username) =>
      User(id: -1, username: username, email: "", pfpURL: "");

  Color userColor() {
    ColorHash colorHash = ColorHash(
      username,
      saturation: 0.5,
      lightness: 0.5,
      hue: (0, 360),
    );
    Color color = colorHash.toColor();

    return color;
  }
}
