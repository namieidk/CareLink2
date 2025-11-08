import 'package:flutter/material.dart';

class PatientHomeScreen extends StatelessWidget {
	const PatientHomeScreen({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Patient Home')),
			body: const Center(child: Text('Welcome Patient!', style: TextStyle(fontSize: 20))),
		);
	}
}
