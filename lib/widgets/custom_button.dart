import 'package:android_basic/constants.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    this.isTransparents = false,
    required this.text,
    this.isLarge = false,
    this.onPressed,
  });

  final bool isTransparents;
  final String text;
  final bool isLarge;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: isLarge ? double.infinity : 160,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isTransparents ? null : primary,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: h2.copyWith(
            color: isTransparents ? black : white,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}
