import 'package:flutter/material.dart';
import 'package:unired/shared/widgets/admin_shell.dart';
import 'package:unired/shared/widgets/public_header.dart';

/// Área de trabajo acotada a la ventana; solo sus paneles se desplazan.
class WorkspaceFrame extends StatelessWidget {
  const WorkspaceFrame({
    super.key,
    required this.route,
    required this.child,
    this.asAdmin = false,
    this.title = '',
    this.subtitle = '',
  });
  final String route, title, subtitle;
  final bool asAdmin;
  final Widget child;
  @override
  Widget build(BuildContext context) => asAdmin
      ? AdminShell(
          current: route,
          child: Column(
            children: [
              AdminTopBar(title: title, subtitle: subtitle),
              Expanded(child: child),
            ],
          ),
        )
      : Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                PublicHeader(currentRoute: route),
                Expanded(child: child),
              ],
            ),
          ),
        );
}
