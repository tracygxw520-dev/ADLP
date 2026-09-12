import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'screens/main_shell.dart';

void main() {
  runApp(const PawBolehApp());
}

class PawBolehApp extends StatefulWidget {
  const PawBolehApp({super.key});

  @override
  State<PawBolehApp> createState() => _PawBolehAppState();
}

class _PawBolehAppState extends State<PawBolehApp> {
  bool _isSignedIn = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gema',
      debugShowCheckedModeBanner: false,
      theme: AppTextStyles.themeData,
      home: _isSignedIn
          ? MainShell(onSignOut: () => setState(() => _isSignedIn = false))
          : LoginView(onSignIn: () => setState(() => _isSignedIn = true)),
    );
  }
}
