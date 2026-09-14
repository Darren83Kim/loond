import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'ui/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LoondApp());
}

class LoondApp extends StatelessWidget {
  const LoondApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '로온드',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}