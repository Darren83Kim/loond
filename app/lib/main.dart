import 'package:flutter/material.dart';

import 'ads/ads_init.dart';
import 'ads/interstitial_ad_manager.dart';
import 'theme/app_theme.dart';
import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeMobileAds();
  InterstitialAdManager.instance.preload();
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
