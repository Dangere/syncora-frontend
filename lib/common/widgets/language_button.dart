import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(onPressed: () {}, icon: Row(children: [Text("EN|عربي")]));
  }
}
