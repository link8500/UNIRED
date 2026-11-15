import 'package:flutter/material.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/network/api_client.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/models/profile/widgets/profile_data_form.dart';
import 'package:unired/shared/widgets/admin_components.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/status_pill.dart';

/// Una consulta por selección. El panel no vuelve a cargar por notificaciones
/// ni por reconstrucciones del shell; solo tras una modificación confirmada.
class UserAccountPanel extends StatefulWidget {
  const UserAccountPanel({
    super.key,
    required this.id,
    required this.onClose,
    required this.onSaved,
    this.initialTab = 'content',
  });
  final String id;
  final VoidCallback onClose;
  final Future<void> Function() onSaved;
  final String initialTab;
  @override
  State<UserAccountPanel> createState() => _UserAccountPanelState();
}

class _UserAccountPanelState extends State<UserAccountPanel> {
  final api = AppService.instance.api;
  late Future<Json> _details = api.object('/admin/users/${widget.id}');
  final _reason = TextEditingController();
  final _roles = <String>{};
  late String _tab = widget.initialTab;
  String? _state;
  bool _initialized = false;
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final next = api.object('/admin/users/${widget.id}');
    setState(() {
      _details = next;
      _initialized = false;
    });
    await next;
    await widget.onSaved();
  }

  @override
  Widget build(BuildContext context) => AdminSurface(
    child: FutureBuilder<Json>(
      future: _details,
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return Column(
            children: [
              ApiErrorNotice(message: snapshot.error.toString()),
              TextButton(onPressed: _refresh, child: const Text('Reintentar')),
            ],
          );
        }
        if (!snapshot.hasData) {
          return const ApiEmptyState(message: '', loading: true);
        }
        final user = snapshot.data!;
        final p = jsonObject(user['perfil']);
        if (!_initialized) {
          _roles.clear();
          _roles.addAll(
            (user['roles'] is List ? user['roles'] as List : []).map(
              (r) => r.toString(),
            ),
          );
          _state = textValue(user['estado']);
          _initialized = true;
        }
        final administrator =
            user['roles'] is List &&
            (user['roles'] as List).contains('administrador');
        final self = widget.id == AppService.instance.currentUser?.id;
        final summary = jsonObject(user['resumen']);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Datos del usuario',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar detalles',
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: AdminAvatar(
                name: textValue(user['nombre']),
                fileId: p['avatarArchivoId']?.toString(),
                radius: 34,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              textValue(user['nombre']),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            SelectableText(
              textValue(user['email']),
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                StatusPill(switch (user['estado']) {
                  'activo' => 'Activo',
                  'suspendido' => 'Suspendido',
                  _ => 'Pendiente',
                }),
                if (administrator) const StatusPill('Administrador'),
                if (jsonRows(
                  user['acreditaciones'],
                ).any((g) => g['estado'] == 'vigente'))
                  const StatusPill('Tutor acreditado'),
              ],
            ),
            const SizedBox(height: 12),
            AdminInfo('Ubicación', p['ciudad']),
            if (!administrator && textValue(p['universidad']).isNotEmpty)
              AdminInfo('Universidad', p['universidad']),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final s in [
                  ('publicaciones', 'Artículos'),
                  ('tutorias', 'Tutorías'),
                  ('inscripciones', 'Inscrito'),
                ])
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          textValue(summary[s.$1], '0'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(s.$2, style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
              ],
            ),
            const Divider(height: 32),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final tab in {
                  'info': 'Información',
                  'content': 'Contenido',
                  'manage': 'Gestionar',
                }.entries)
                  ChoiceChip(
                    label: Text(
                      tab.value,
                      style: const TextStyle(fontSize: 10),
                    ),
                    selected: _tab == tab.key,
                    onSelected: (_) => setState(() => _tab = tab.key),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (_tab == 'info') ...[
              const AdminSectionHeading('Contacto y residencia'),
              const SizedBox(height: 8),
              AdminInfo('Teléfono', p['telefono']),
              AdminInfo('País', p['pais']),
              AdminInfo('Departamento', p['departamento']),
              AdminInfo('Ciudad', p['ciudad']),
              if (!administrator) ...[
                const Divider(height: 24),
                const AdminSectionHeading('Estudios'),
                const SizedBox(height: 8),
                AdminInfo('Edad', user['edad']),
                AdminInfo('Universidad', p['universidad']),
                AdminInfo('Sede', p['sede']),
                AdminInfo('Carrera', p['carrera']),
                AdminInfo('Año', p['anioEstudio']),
              ],
              const Divider(height: 24),
              const AdminSectionHeading('Actividad profesional'),
              const SizedBox(height: 8),
              AdminInfo(
                'Trabaja',
                p['trabaja'] == true
                    ? 'Sí'
                    : p['trabaja'] == false
                    ? 'No'
                    : null,
              ),
              AdminInfo('Ocupación', p['ocupacion']),
              AdminInfo('Área', p['areaProfesional']),
              const Divider(height: 24),
              AdminInfo('Registrado', adminDate(user['creadoEn'])),
              AdminInfo(
                'Correo',
                user['emailVerificadoEn'] == null
                    ? 'Sin verificación de correo'
                    : 'Verificado',
              ),
              AdminInfo('Sesiones', summary['sesionesActivas']),
              if (textValue(p['presentacion']).isNotEmpty) ...[
                const Divider(height: 24),
                Text(
                  textValue(p['presentacion']),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
            if (_tab == 'content') ...[
              _publications(
                'Publicaciones',
                jsonRows(user['publicaciones']),
                false,
              ),
              const SizedBox(height: 18),
              _publications('Tutorías', jsonRows(user['tutorias']), true),
              const SizedBox(height: 18),
              const AdminSectionHeading('Acreditaciones'),
              if (jsonRows(user['acreditaciones']).isEmpty)
                const AdminEmpty(
                  'Sin acreditaciones',
                  message: 'El acceso como tutor requiere revisión documental.',
                ),
              for (final grant in jsonRows(user['acreditaciones']))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.verified_user_outlined),
                  title: Text(
                    textValue(grant['area']),
                    style: const TextStyle(fontSize: 11),
                  ),
                  subtitle: Text(
                    textValue(grant['estado']),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              const Divider(height: 24),
              const AdminSectionHeading('Últimos movimientos'),
              for (final event in jsonRows(user['actividad']))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    adminAction(event['accion']),
                    style: const TextStyle(fontSize: 11),
                  ),
                  subtitle: Text(
                    adminDate(event['creadoEn']),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
            ],
            if (_tab == 'manage') ...[
              if (self) ...[
                const Text(
                  'Para modificar tu cuenta utiliza tu perfil administrativo.',
                  style: TextStyle(fontSize: 12),
                ),
                TextButton(
                  onPressed: () =>
                      AppNavigator.go(context, AppRoutes.adminProfile),
                  child: const Text('Abrir mi perfil'),
                ),
              ] else ...[
                const AdminSectionHeading(
                  'Estado y permisos',
                  subtitle: 'Toda decisión requiere un motivo.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue:
                      ['activo', 'suspendido', 'desactivado'].contains(_state)
                      ? _state
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Estado de la cuenta',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'activo', child: Text('Activo')),
                    DropdownMenuItem(
                      value: 'suspendido',
                      child: Text('Suspendido'),
                    ),
                    DropdownMenuItem(
                      value: 'desactivado',
                      child: Text('Desactivado'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _state = value),
                ),
                const SizedBox(height: 12),
                for (final r in const {
                  'usuario': 'Usuario',
                  'revisor_tutores': 'Revisor de tutores',
                  'moderador': 'Moderador',
                  'administrador': 'Administrador',
                }.entries)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(r.value, style: const TextStyle(fontSize: 12)),
                    value: _roles.contains(r.key),
                    onChanged: r.key == 'usuario'
                        ? null
                        : (checked) => setState(() {
                            if (checked == true) {
                              _roles.add(r.key);
                            } else {
                              _roles.remove(r.key);
                            }
                          }),
                  ),
                const Text(
                  'La acreditación de tutor no se concede asignando un rol.',
                  style: TextStyle(fontSize: 10),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reason,
                  maxLines: 2,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Motivo de la decisión',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ApiActionButton(
                      label: 'Guardar estado',
                      enabled: _state != null && _state != 'pendiente_email',
                      action: () async {
                        if (_reason.text.trim().length < 5) {
                          throw const ApiError(
                            'Explica el motivo de la decisión.',
                          );
                        }
                        await api.object(
                          '/admin/users/${widget.id}/state',
                          method: 'PATCH',
                          data: {
                            'estado': _state,
                            'motivo': _reason.text.trim(),
                          },
                        );
                        widget.onClose();
                        await widget.onSaved();
                      },
                    ),
                    ApiActionButton(
                      label: 'Guardar permisos',
                      action: () async {
                        if (_reason.text.trim().length < 5) {
                          throw const ApiError(
                            'Explica el motivo de la decisión.',
                          );
                        }
                        await api.object(
                          '/admin/users/${widget.id}/roles',
                          method: 'PUT',
                          data: {
                            'roles': _roles.toList(),
                            'motivo': _reason.text.trim(),
                          },
                        );
                        await _refresh();
                      },
                    ),
                  ],
                ),
                const Divider(height: 36),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text(
                    'Corregir información del perfil',
                    style: TextStyle(fontSize: 12),
                  ),
                  children: [
                    ProfileDataForm(
                      key: ValueKey(user.toString()),
                      initial: {
                        ...p,
                        'nombre': user['nombre'],
                        'edad': user['edad'],
                      },
                      administrator:
                          jsonObject(snapshot.data)['tipoPerfil'] ==
                              'administrador' ||
                          (user['roles'] is List &&
                              (user['roles'] as List).contains(
                                'administrador',
                              )),
                      requireReason: true,
                      label: 'Guardar corrección',
                      onSave: (data) async {
                        await api.object(
                          '/admin/users/${widget.id}/profile',
                          method: 'PATCH',
                          data: data,
                        );
                        await _refresh();
                      },
                    ),
                  ],
                ),
              ],
            ],
          ],
        );
      },
    ),
  );

  Widget _publications(String title, List<Json> rows, bool tutorial) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AdminSectionHeading(
        title,
        action: TextButton(
          onPressed: () => _openPublications(tutorial),
          child: const Text('Ver todo', style: TextStyle(fontSize: 10)),
        ),
      ),
      if (rows.isEmpty)
        const AdminEmpty(
          'Sin publicaciones',
          message: 'Este usuario todavía no tiene contenido en este apartado.',
        ),
      if (rows.isNotEmpty)
        LayoutBuilder(
          builder: (_, size) {
            final columns = tutorial ? 1 : 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final row in rows.take(tutorial ? 3 : 4))
                  SizedBox(
                    width: (size.maxWidth - (columns - 1) * 10) / columns,
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFFE6E7E9)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _openPublications(tutorial),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: tutorial ? 112 : 78,
                              child: ApiImage(
                                fileId: row['portadaArchivoId']?.toString(),
                                fallback: ColoredBox(
                                  color: const Color(0xFFF0F6FB),
                                  child: Icon(
                                    tutorial
                                        ? Icons.menu_book_outlined
                                        : Icons.inventory_2_outlined,
                                    size: 30,
                                    color: const Color(0xFF0875C9),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(9),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    textValue(row['titulo']),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${textValue(row['precioBase'])} ${textValue(row['moneda'])}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    textValue(row['estado']),
                                    style: const TextStyle(fontSize: 9),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
    ],
  );

  void _openPublications(bool tutorial) => AppNavigator.go(
    context,
    '${tutorial ? AppRoutes.adminTutorials : AppRoutes.adminMarket}?owner=${widget.id}',
  );
}
