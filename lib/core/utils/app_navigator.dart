import 'package:flutter/material.dart';

import 'package:unired/models/about/views/about_page.dart';
import 'package:unired/models/admin/views/admin_login_page.dart';
import 'package:unired/models/admin/views/dashboard_page.dart';
import 'package:unired/models/auth/views/login_page.dart';
import 'package:unired/models/auth/views/register_page.dart';
import 'package:unired/models/home/views/home_page.dart';
import 'package:unired/models/market/views/market_page.dart';
import 'package:unired/models/tutorials/views/tutorials_page.dart';
import 'package:unired/models/user/views/user_page.dart';

/// Rutas declaradas en un solo sitio para evitar strings repetidos.
class AppRoutes {
  static const home = '/home';
  static const login = '/login';
  static const register = '/register';
  static const market = '/market';
  static const tutorials = '/tutorials';
  static const about = '/about';
  static const adminLogin = '/admin-login';
  static const dashboard = '/dashboard';
  static const user = '/user';
}

/// Crea las pantallas y aplica una transición consistente entre módulos.
class AppNavigator {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final page = switch (settings.name) {
      AppRoutes.login => const LoginPage(),
      AppRoutes.register => const RegisterPage(),
      AppRoutes.market => const MarketPage(),
      AppRoutes.tutorials => const TutorialsPage(),
      AppRoutes.about => const AboutPage(),
      AppRoutes.adminLogin => const AdminLoginPage(),
      AppRoutes.dashboard => const DashboardPage(),
      AppRoutes.user => const UserPage(),
      _ => const HomePage(),
    };

    return PageRouteBuilder<void>(
      settings: settings,
      pageBuilder: (_, animation, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(.02, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 260),
    );
  }

  static void go(BuildContext context, String route) {
    Navigator.of(context).pushReplacementNamed(route);
  }
}
