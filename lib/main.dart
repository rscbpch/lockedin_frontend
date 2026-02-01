import 'package:flutter/material.dart';
import 'ui/screens/auth/getting_started_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Getting Started App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GettingStartedScreen(), // first screen
      debugShowCheckedModeBanner: false,
    );
  }
}
