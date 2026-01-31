import 'package:flutter/material.dart';

class LoginForm extends StatefulWidget {
  final void Function(String email, String password)? onSubmit;
  const LoginForm({super.key, this.onSubmit});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

      ],
    );
  }
}