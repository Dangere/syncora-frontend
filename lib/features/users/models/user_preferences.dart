import 'package:flutter/material.dart';

class UserPreferences {
  final bool darkMode;
  final Locale locale;

  UserPreferences({required this.darkMode, required this.locale});

  factory UserPreferences.defaults() =>
      UserPreferences(darkMode: false, locale: const Locale("en"));

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      UserPreferences(
          darkMode: json['darkMode'], locale: Locale(json['languageCode']));

  Map<String, dynamic> toJson() =>
      {"darkMode": darkMode, "languageCode": locale.languageCode};

  UserPreferences copyWith({bool? darkMode, String? languageCode}) {
    return UserPreferences(
        darkMode: darkMode ?? this.darkMode,
        locale: languageCode != null ? Locale(languageCode) : locale);
  }
}
