// Archivo: lib/models/perfil/views/perfil_publico_view.dart
// Consulta el perfil público de otro miembro respetando los datos que publica el backend.

import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/autenticacion/models/usuario_aplicacion.dart';
import 'package:unired/models/perfil/widgets/tarjeta_identidad_perfil.dart';
import 'package:unired/shared/widgets/coleccion_api.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/marco_pagina.dart';

class PerfilPublicoView extends StatefulWidget {
  const PerfilPublicoView({super.key, required this.id});
  final String id;

  @override
  State<PerfilPublicoView> createState() => _PerfilPublicoViewState();
}

class _PerfilPublicoViewState extends State<PerfilPublicoView> {
  late Future<Json> _profile = _load();
  bool _tutorials = false;

  Future<Json> _load() => AplicacionController.instance.api.object(
    '/profiles/${Uri.encodeComponent(widget.id)}',
    authenticated: false,
  );

  @override
  Widget build(BuildContext context) => MarcoPaginaPublica(
    route: RutasAplicacion.member,
    body: SeccionPagina(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: FutureBuilder<Json>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AvisoErrorApi(
              message: snapshot.error.toString(),
              retry: () => setState(() => _profile = _load()),
            );
          }
          if (!snapshot.hasData) {
            return const EstadoVacioApi(message: '', loading: true);
          }
          final data = snapshot.data!;
          final user = UsuarioAplicacion(
            id: widget.id,
            name: textValue(data['nombre']),
            email: '',
            university: '',
            avatarId: data['avatarArchivoId']?.toString(),
            bannerId: data['bannerArchivoId']?.toString(),
          );
          final details = [
            textValue(data['presentacion']),
            textValue(data['areaProfesional']),
            textValue(data['ciudad']),
            if (data['telefono'] != null) 'Teléfono: ${data['telefono']}',
          ].where((value) => value.trim().isNotEmpty);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TarjetaIdentidadPerfil(user: user),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 16),
                TarjetaSuave(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final detail in details)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(detail),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Artículos'),
                    selected: !_tutorials,
                    onSelected: (_) => setState(() => _tutorials = false),
                  ),
                  ChoiceChip(
                    label: const Text('Tutorías'),
                    selected: _tutorials,
                    onSelected: (_) => setState(() => _tutorials = true),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TarjetaSuave(
                child: ColeccionApi(
                  key: ValueKey(_tutorials),
                  path: _tutorials ? '/courses' : '/listings',
                  query: {_tutorials ? 'tutorId' : 'vendedorId': widget.id},
                  empty: EstadoVacioApi(
                    message: _tutorials
                        ? 'Este perfil no tiene tutorías públicas.'
                        : 'Este perfil no tiene artículos públicos.',
                  ),
                  builder: (rows) => Column(
                    children: [
                      for (final row in rows)
                        ListTile(
                          leading: Icon(
                            _tutorials
                                ? Icons.school_outlined
                                : Icons.storefront_outlined,
                          ),
                          title: Text(textValue(row['titulo'])),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => NavegadorAplicacion.go(
                            context,
                            Uri(
                              path: _tutorials
                                  ? RutasAplicacion.course
                                  : RutasAplicacion.listing,
                              queryParameters: {'id': textValue(row['id'])},
                            ).toString(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
