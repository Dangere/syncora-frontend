import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  const InputField(
      {super.key,
      required this.controller,
      required this.validator,
      required this.labelText,
      required this.hintText,
      required this.keyboardType,
      this.obscureText = false,
      this.suffixIcon,
      this.onSuffixIconPressed,
      this.fieldKey});
  final String labelText;
  final String hintText;
  final bool obscureText;

  final TextEditingController controller;
  final String? Function(String?)? validator;
  final VoidCallback? onSuffixIconPressed;
  final GlobalKey? fieldKey;

  final IconData? suffixIcon;

  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return Stack(
      // alignment: Alignment.bottomLeft,

      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 5, bottom: 8),
              child: Text(labelText,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 45),
              child: TextFormField(
                key: fieldKey,
                keyboardType: keyboardType,
                obscureText: obscureText,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: hintText,
                  suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
                ),
                controller: controller,
                validator: validator,
              ),
            ),
          ],
        ),
        Positioned(
            top: 30,
            right: 0,
            child: GestureDetector(
              onTap: () {
                if (suffixIcon != null && onSuffixIconPressed != null) {
                  onSuffixIconPressed!();
                }
              },
              child: Container(
                // color: Colors.red.withOpacity(0.2),
                child: SizedBox(
                  height: 45,
                  width: 45,
                  child: Center(
                      child: Icon(suffixIcon, color: Colors.transparent)),
                ),
              ),
            )),
      ],
    );
  }
}
