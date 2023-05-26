import 'package:flutter/material.dart';
import 'package:otp_autofill_example/code_screen/code_confirm_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OTP autofill example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CodeConfirmScreen(),
    );
  }
}
