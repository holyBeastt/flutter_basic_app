import 'package:android_basic/constants.dart';
import 'package:android_basic/screens/login_screen.dart';
import 'package:android_basic/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -330,
            right: -330,
            child: Container(
              height: 600,
              width: 600,
              decoration: BoxDecoration(
                color: lightBlue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -((1 / 4) * 500),
            right: -((1 / 4) * 500),
            child: Container(
              height: 450,
              width: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: lightBlue, width: 2),
              ),
            ),
          ),
          Positioned(
            left: -264,
            bottom: -120,
            child: Container(
              height: 372,
              width: 372,
              decoration: BoxDecoration(
                border: Border.all(color: lightBlue, width: 2),
              ),
            ),
          ),
          Positioned(
            left: -260,
            bottom: -120,
            child: Transform.rotate(
              angle: -0.99999,
              child: Container(
                height: 372,
                width: 372,
                decoration: BoxDecoration(
                  border: Border.all(color: lightBlue, width: 2),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              children: [
                SizedBox(height: 60),
                Image.asset(
                  "assets/illu",
                  fit: BoxFit.cover,
                  height: 350,
                  width: 350,
                ),
                SizedBox(height: 40),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    "Discover your dream here",
                    style: h1,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 20),
                Text("Explore your dream", textAlign: TextAlign.center),
                SizedBox(height: 50),
                Row(
                  children: [
                    CustomButton(
                      text: "Login",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 20),
                    CustomButton(text: "Signup", isTransparents: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
