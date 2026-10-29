import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Juan Delivery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      home: const LoginScreen(),
    );
  }
}
