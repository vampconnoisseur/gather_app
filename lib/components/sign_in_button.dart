import 'package:flutter/material.dart';

class SignInButton extends StatelessWidget {
  final Function()? ontap;
  final bool isLogin;

  const SignInButton({super.key, required this.ontap, required this.isLogin});

  @override
  Widget build(context) {
    return ElevatedButton(
      onPressed: ontap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/google_logo.jpg',
            height: 40.0,
          ),
          const SizedBox(width: 10.0),
          Text(
            isLogin ? 'Continue With Google' : 'Sign Up With Google',
            style: const TextStyle(
              fontSize: 17.0,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
