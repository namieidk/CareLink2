import 'package:flutter/material.dart';

class CaregiverHomeScreen extends StatelessWidget {
  const CaregiverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Caregiver Home')),
      body: const Center(child: Text('Welcome Caregiver!', style: TextStyle(fontSize: 20))),
    );
  }
}
