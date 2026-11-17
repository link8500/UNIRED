// Archivo: lib/models/perfil/views/perfil_view.dart
// Organiza la cuenta personal y sus apartados de datos, aprendizaje, publicaciones y seguridad.

import 'package:flutter/material.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/autenticacion/models/usuario_aplicacion.dart';
import 'package:unired/models/perfil/models/seccion_cuenta.dart';
import 'package:unired/models/perfil/widgets/aprendizaje_cuenta.dart';
import 'package:unired/models/perfil/widgets/resumen_cuenta.dart';
import 'package:unired/models/perfil/widgets/preferencias_cuenta.dart';
import 'package:unired/models/perfil/widgets/seguridad_cuenta.dart';
import 'package:unired/models/perfil/widgets/publicaciones_propias.dart';
import 'package:unired/models/perfil/widgets/editor_perfil.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/componentes_administracion.dart';
import 'package:unired/shared/widgets/estructura_administracion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/marco_pagina.dart';

class PerfilView extends StatelessWidget {
  const PerfilView({super.key, this.asAdmin = false, this.initialTab = 'data'});

  final bool asAdmin;
  final String initialTab;

  void _open(BuildContext context, SeccionCuenta section) =>
      NavegadorAplicacion.go(context, section.route(asAdmin: asAdmin));

  @override
  Widget build(BuildContext context) {
    final store = AplicacionController.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final user = store.currentUser;
        final section = user?.verified == true
            ? SeccionCuenta.fromTab(initialTab)
            : SeccionCuenta.profile;
        final content = user == null
            ? const EstadoVacioApi(message: 'Inicia sesión para ver tu cuenta.')
            : LayoutBuilder(
                builder: (context, size) {
                  final panel = _panel(context, user, section);
                  if (!user.verified) return panel;
                  if (size.maxWidth < 780) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final item in SeccionCuenta.values.where(
                                (item) =>
                                    item != SeccionCuenta.edit &&
                                    item != SeccionCuenta.security,
                              ))
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(item.label),
                                    selected: item == section,
                                    onSelected: (_) => _open(context, item),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        panel,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 218, child: _sidebar(context, section)),
                      const SizedBox(width: 26),
                      Expanded(child: panel),
                    ],
                  );
                },
              );
        final body = SeccionPagina(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: content,
        );
        if (asAdmin) {
          return EstructuraAdministracion(
            current: RutasAplicacion.adminProfile,
            child: Column(
              children: [
                BarraSuperiorAdmin(title: section.label, subtitle: 'Mi cuenta'),
                Expanded(child: SingleChildScrollView(child: body)),
              ],
            ),
          );
        }
        return MarcoPaginaPublica(
          route: section.route(),
          body: body,
          showFooter: false,
        );
      },
    );
  }

  Widget _sidebar(
    BuildContext context,
    SeccionCuenta section,
  ) => SuperficieAdmin(
    padding: const EdgeInsets.all(10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Text(
            'Mi cuenta',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
        for (final item in SeccionCuenta.values.where(
          (item) =>
              item != SeccionCuenta.edit && item != SeccionCuenta.security,
        ))
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            dense: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
            selected:
                item == section ||
                item == SeccionCuenta.profile &&
                    section == SeccionCuenta.edit ||
                item == SeccionCuenta.preferences &&
                    section == SeccionCuenta.security,
            selectedTileColor: ColoresAplicacion.surfaceBlue,
            selectedColor: ColoresAplicacion.blue,
            leading: Icon(item.icon, size: 19),
            title: Text(item.label),
            onTap: () => _open(context, item),
          ),
        const Divider(),
        ListTile(
          dense: true,
          leading: const Icon(Icons.handshake_outlined, size: 19),
          title: const Text('Mis ofertas'),
          onTap: () => NavegadorAplicacion.go(
            context,
            asAdmin ? RutasAplicacion.adminOffers : RutasAplicacion.offers,
          ),
        ),
        ListTile(
          dense: true,
          leading: const Icon(Icons.school_outlined, size: 19),
          title: const Text('Solicitudes de tutoría'),
          onTap: () => NavegadorAplicacion.go(
            context,
            asAdmin
                ? RutasAplicacion.adminTutoringRequests
                : RutasAplicacion.tutoringRequests,
          ),
        ),
        ...[
          ListTile(
            dense: true,
            leading: const Icon(Icons.business_outlined, size: 19),
            title: const Text('Mis empresas'),
            onTap: () => NavegadorAplicacion.go(
              context,
              asAdmin
                  ? RutasAplicacion.adminBusiness
                  : RutasAplicacion.business,
            ),
          ),
          ListTile(
            dense: true,
            leading: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 19,
            ),
            title: const Text('Mi cartera y compras'),
            onTap: () => NavegadorAplicacion.go(
              context,
              asAdmin ? RutasAplicacion.adminWallet : RutasAplicacion.wallet,
            ),
          ),
        ],
        ListTile(
          dense: true,
          leading: const Icon(Icons.forum_outlined, size: 19),
          title: const Text('Mis mensajes'),
          onTap: () => NavegadorAplicacion.go(
            context,
            asAdmin ? RutasAplicacion.adminMessages : RutasAplicacion.messages,
          ),
        ),
        ListTile(
          dense: true,
          leading: const Icon(Icons.folder_outlined, size: 19),
          title: const Text('Mis archivos'),
          onTap: () => NavegadorAplicacion.go(
            context,
            asAdmin ? RutasAplicacion.adminFiles : RutasAplicacion.files,
          ),
        ),
      ],
    ),
  );

  Widget _panel(
    BuildContext context,
    UsuarioAplicacion user,
    SeccionCuenta section,
  ) {
    if (section == SeccionCuenta.profile) {
      return ResumenCuenta(
        user: user,
        onEdit: () => _open(context, SeccionCuenta.edit),
        asAdmin: asAdmin,
      );
    }
    final body = switch (section) {
      SeccionCuenta.edit => EditorPerfil(
        key: ValueKey(user.id),
        user: user,
        onSaved: () => _open(context, SeccionCuenta.profile),
      ),
      SeccionCuenta.products => PublicacionesPropias(
        tutorials: false,
        asAdmin: asAdmin,
      ),
      SeccionCuenta.tutorials => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TarjetaSuave(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.verified_outlined,
                color: ColoresAplicacion.blue,
              ),
              title: const Text('Acreditación de tutor'),
              subtitle: const Text(
                'Consulta tu solicitud y las áreas que puedes impartir.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => NavegadorAplicacion.go(
                context,
                asAdmin
                    ? RutasAplicacion.adminOwnAccreditation
                    : RutasAplicacion.accreditation,
              ),
            ),
          ),
          const SizedBox(height: 16),
          PublicacionesPropias(tutorials: true, asAdmin: asAdmin),
        ],
      ),
      SeccionCuenta.learning => const AprendizajeCuenta(),
      SeccionCuenta.favorites => _favorites(context),
      SeccionCuenta.preferences => PreferenciasCuenta(
        user: user,
        onSecurity: () => _open(context, SeccionCuenta.security),
      ),
      SeccionCuenta.security => SeguridadCuenta(asAdmin: asAdmin),
      SeccionCuenta.profile => const SizedBox.shrink(),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _open(
              context,
              section == SeccionCuenta.security
                  ? SeccionCuenta.preferences
                  : SeccionCuenta.profile,
            ),
            icon: const Icon(Icons.arrow_back, size: 17),
            label: Text(
              section == SeccionCuenta.security
                  ? 'Volver a ajustes'
                  : 'Volver a mi perfil',
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...[
          Text(section.label, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
        ],
        body,
      ],
    );
  }

  Widget _favorites(BuildContext context) {
    final store = AplicacionController.instance;
    final items = store.favoriteProducts;
    return TarjetaSuave(
      child: items.isEmpty
          ? Column(
              children: [
                const EstadoVacioApi(
                  message: 'Todavía no has guardado artículos.',
                ),
                OutlinedButton(
                  onPressed: () =>
                      NavegadorAplicacion.go(context, RutasAplicacion.market),
                  child: const Text('Explorar el marketplace'),
                ),
              ],
            )
          : Column(
              children: [
                for (final item in items)
                  ListTile(
                    leading: const Icon(
                      Icons.bookmark_outline,
                      color: ColoresAplicacion.blue,
                    ),
                    title: Text(item.title),
                    subtitle: Text(item.displayPrice),
                    trailing: IconButton(
                      tooltip: 'Quitar de favoritos',
                      icon: const Icon(
                        Icons.favorite,
                        color: ColoresAplicacion.coral,
                      ),
                      onPressed: () => runApiAction(
                        context,
                        () => store.toggleFavorite(item),
                      ),
                    ),
                    onTap: () => NavegadorAplicacion.go(
                      context,
                      '${RutasAplicacion.listing}?id=${item.id}',
                    ),
                  ),
              ],
            ),
    );
  }
}
