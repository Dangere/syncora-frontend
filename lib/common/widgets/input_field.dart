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
      this.onChanged,
      this.fieldKey,
      this.autoFocus = false,
      this.multiline = false});
  final String labelText;
  final String hintText;
  final bool obscureText;

  final TextEditingController controller;
  final String? Function(String?)? validator;
  final VoidCallback? onSuffixIconPressed;
  final void Function(String text)? onChanged;

  final GlobalKey? fieldKey;

  final IconData? suffixIcon;
  final TextInputType keyboardType;
  final bool autoFocus;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    final isLTR = Directionality.of(context) == TextDirection.ltr;

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
                autofocus: autoFocus,
                onChanged: onChanged,
                maxLines: multiline ? 4 : 1,
                key: fieldKey,
                keyboardType: keyboardType,
                obscureText: obscureText,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: hintText,
                  suffixIcon: suffixIcon != null
                      ? GestureDetector(
                          onTap: onSuffixIconPressed, child: Icon(suffixIcon))
                      : null,
                ),
                controller: controller,
                validator: validator,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
