import 'package:flutter/material.dart';
import 'package:unired/models/auth/views/auth_layout.dart';
import 'package:unired/models/auth/widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const AuthLayout(isRegister: false, form: LoginForm());
}
