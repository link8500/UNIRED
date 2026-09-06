import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/utils/app_navigator.dart';
import 'shared/themes/app_theme.dart';

void main() {
  runApp(const UniRedApp());
}

class UniRedApp extends StatelessWidget {
  const UniRedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppNavigator.onGenerateRoute,
    );
  }
}
