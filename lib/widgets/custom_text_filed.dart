import 'package:flutter/material.dart';
import 'package:infinity_messenger/core/constants.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    this.suffixIcon,
    this.prefixIcon,
    required this.hint,
    this.onChanged,
    this.obscureText = false,
    this.maxLines,
    this.maxLength, this.onTap, this.focusNode, this.fillColor,
  });

  final TextEditingController controller;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String hint;
  final int? maxLines;
  final int? maxLength;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final Color? fillColor;


  @override
  Widget build(BuildContext context) {
    return TextFormField(
      maxLines: maxLines !=1 ? maxLines: 1,
      maxLength: maxLength,
      controller: controller,
      onChanged: onChanged,
      focusNode: focusNode,
      obscureText: obscureText,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none
        ),
        filled: true,
        fillColor: fillColor != null ? fillColor : Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        hintText: hint,
        hintStyle: myTextStyle(context,12,'normal',0.5,),
      ),
    );
  }
}
