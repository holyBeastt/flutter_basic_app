import 'package:android_basic/constants.dart';
import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  final String text;
  final Color? buttonColor;
  final Color? textColor;
  final Function()? onTap;
  Button({this.text = '', this.onTap, this.buttonColor, this.textColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        child: Text(text, style: TextStyle(color: textColor)),
        style: ButtonStyle(
          shape: MaterialStateProperty.all(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0)),
            ),
          ),
          backgroundColor: MaterialStateProperty.all(buttonColor),
        ),
      ),
    );
  }
}

class EntryField extends StatelessWidget {
  final String hintText;
  EntryField({this.hintText = ''});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 35,
      child: TextField(
        textAlignVertical: TextAlignVertical.bottom,
        decoration: InputDecoration(
          constraints: const BoxConstraints(),
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.greenAccent[700],
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
          filled: true,
          fillColor: const Color(0xffD9E2DF),
          border: const OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
        ),
      ),
    );
  }
}

class SocialButton extends StatelessWidget {
  const SocialButton({super.key, required this.iconPath});

  final String iconPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 60,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Image.asset(iconPath),
    );
  }
}

class CustomTextfield extends StatelessWidget {
  const CustomTextfield({
    super.key,
    required this.hint,
    required this.controller,
    this.obscureText = false,
  });

  final String hint;
  final TextEditingController controller;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        fillColor: lightBlue,
        filled: true,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
