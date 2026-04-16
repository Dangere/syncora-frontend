import 'package:flutter/material.dart';

class InputField extends StatefulWidget {
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
  final String? Function(String? value)? validator;
  final VoidCallback? onSuffixIconPressed;
  final void Function(String text)? onChanged;

  final GlobalKey? fieldKey;

  final IconData? suffixIcon;
  final TextInputType keyboardType;
  final bool autoFocus;
  final bool multiline;

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  String? displayedErrorMessage = null;
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
              padding: EdgeInsets.only(left: 5, right: 5, bottom: 8),
              child: Text(widget.labelText,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                  minHeight: 43,
                  maxHeight: widget.multiline ? double.infinity : 43),
              child: TextFormField(
                errorBuilder: (context, errorText) {
                  return const Text("", style: TextStyle(fontSize: 0));
                },
                autofocus: widget.autoFocus,
                onChanged: widget.onChanged,
                maxLines: widget.multiline ? 4 : 1,
                key: widget.fieldKey,
                keyboardType: widget.keyboardType,
                obscureText: widget.obscureText,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  errorText: null,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 15, vertical: widget.multiline ? 15 : 0),
                  hintText: widget.hintText,
                  suffixIcon: widget.suffixIcon != null
                      ? GestureDetector(
                          onTap: widget.onSuffixIconPressed,
                          child: Icon(widget.suffixIcon))
                      : null,
                ),
                controller: widget.controller,
                validator: (value) {
                  if (widget.validator == null) return null;

                  String? errorMessage = widget.validator!(value);

                  setState(() {
                    displayedErrorMessage = errorMessage;
                  });

                  return errorMessage;
                },
              ),
            ),
            if (displayedErrorMessage != null)
              Padding(
                padding: EdgeInsets.only(left: 15, right: 15, top: 4),
                child: Text(displayedErrorMessage!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: Theme.of(context).colorScheme.error)),
              ),
          ],
        ),
      ],
    );
  }
}
