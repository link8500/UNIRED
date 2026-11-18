// Archivo: lib/shared/widgets/pestanas_administracion.dart
// Muestra la navegación entre apartados del módulo administrativo seleccionado.

import 'package:flutter/material.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/administracion/models/modulos_administracion.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';

/// Navegación secundaria desplazable: no multiplica los enlaces del lateral.
class PestanasAdministracion extends StatelessWidget {
  const PestanasAdministracion({super.key, required this.current});
  final String current;
  @override
  Widget build(BuildContext context) {
    final tabs = ModulosAdministracion.tabs(current)
        .where(
          (tab) =>
              AplicacionController.instance.isAdministrator ||
              ![
                RutasAplicacion.adminCatalogs,
                RutasAplicacion.adminAudit,
                RutasAplicacion.adminTrainingAreas,
                RutasAplicacion.adminMarketCategories,
                RutasAplicacion.adminCourseConversations,
                RutasAplicacion.adminMarketConversations,
              ].contains(tab.route),
        )
        .toList();
    if (tabs.isEmpty) return const SizedBox.shrink();
    final selected = tabs.any((t) => t.route == current)
        ? current
        : Uri.tryParse(current)?.path == RutasAplicacion.adminAccreditation
        ? RutasAplicacion.adminApplications
        : Uri.tryParse(current)?.path;
    return Material(
      color: Colors.white,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: ColoresAplicacion.line)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 18),
              for (final tab in tabs)
                InkWell(
                  onTap: () => NavegadorAplicacion.go(context, tab.route),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 15, 14, 13),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selected == tab.route
                              ? ColoresAplicacion.coral
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected == tab.route
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: selected == tab.route
                            ? ColoresAplicacion.coral
                            : ColoresAplicacion.muted,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 18),
            ],
          ),
        ),
      ),
    );
  }
}
