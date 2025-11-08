import 'package:flutter/material.dart';
import 'package:finalcarelink/Signin/up/welcome.dart'; 


Future<void> main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF8383)),
        fontFamily: 'Rubik',
      ),
      home: const WelcomeScreen(),
    );
  }
}
