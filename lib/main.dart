import 'package:flutter/material.dart';
import 'dart:async';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/app_feedback.dart';

import 'core/constants/app_constants.dart';
import 'core/utils/app_navigator.dart';
import 'shared/themes/app_theme.dart';
import 'shared/widgets/navigation_progress_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UniRedApp());
  unawaited(AppService.instance.initialize());
}

class UniRedApp extends StatelessWidget {
  const UniRedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppFeedback.navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.home,
      navigatorObservers: [
        AppNavigator.observer,
        AppNavigator.visibilityObserver,
      ],
      onGenerateRoute: AppNavigator.onGenerateRoute,
      builder: (context, child) => Stack(
        children: [
          Column(
            children: [
              Expanded(child: child ?? const SizedBox.shrink()),
              const ApiStatusBanner(),
            ],
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: NavigationProgressBar(),
          ),
        ],
      ),
    );
  }
}
