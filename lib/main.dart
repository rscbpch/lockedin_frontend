import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/productivity_hub/productivity_hub_screen.dart';
import 'ui/auth/getting_started_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Getting Started App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // home: const GettingStartedScreen(), // first screen
      home: const ProductivityHubScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
