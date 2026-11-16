// Archivo: lib/models/usuarios/views/usuarios_view.dart
// Presenta el directorio administrativo de usuarios y su selección para revisión.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/usuarios/widgets/panel_cuenta_usuario.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/componentes_administracion.dart';
import 'package:unired/shared/widgets/tabla_administracion.dart';
import 'package:unired/shared/widgets/estructura_administracion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/etiqueta_estado.dart';

/// Directorio paginado: tabla, filtros y ficha lateral son módulos independientes.
class UsuariosView extends StatefulWidget {
  const UsuariosView({super.key, this.accessView = false});
  final bool accessView;
  @override
  State<UsuariosView> createState() => _UsuariosViewState();
}

class _UsuariosViewState extends State<UsuariosView> {
  final _store = AplicacionController.instance;
  final _search = TextEditingController();
  Timer? _debounce;
  String? _id;
  String _role = '';
  String _state = '';
  String _sort = 'recientes';
  bool _loading = false;
  String? _error;
  int _version = 0;
  Future<void> _load([int page = 1]) async {
    final request = ++_version;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      await _store.loadAdminUsers(
        page: page,
        query: {
          if (_search.text.trim().isNotEmpty) 'q': _search.text.trim(),
          if (_role.isNotEmpty) 'rol': _role,
          if (_state.isNotEmpty) 'estado': _state,
          'sort': _sort,
        },
      );
    } catch (error) {
      if (mounted && request == _version) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted && request == _version) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    if (_store.adminUsersPage == null) {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Widget _filter(
    String label,
    String value,
    Map<String, String> choices,
    ValueChanged<String> change,
  ) => SizedBox(
    width: 155,
    child: DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final e in choices.entries)
          DropdownMenuItem(
            value: e.key,
            child: Text(e.value, style: const TextStyle(fontSize: 11)),
          ),
      ],
      onChanged: (next) {
        if (next == null) return;
        setState(() => change(next));
        unawaited(_load());
      },
    ),
  );

  Widget _table() => SuperficieAdmin(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: EncabezadoSeccionAdmin(
            'Directorio de usuarios',
            subtitle:
                '${_store.adminUsersPage?.total ?? 0} cuentas · selecciona una fila para abrir su ficha',
          ),
        ),
        if (_loading)
          const LinearProgressIndicator(
            minHeight: 2,
            color: ColoresAplicacion.coral,
          ),
        if (_error != null)
          AvisoErrorApi(message: _error!)
        else if (_store.users.isEmpty && !_loading)
          const EstadoVacioAdmin(
            'No hay resultados',
            message: 'Prueba otro nombre, correo, estado o rol.',
            icon: Icons.person_search_outlined,
          ),
        if (_store.users.isNotEmpty)
          TablaAdministracion(
            minWidth: 820,
            rowHeight: 62,
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Usuario')),
              DataColumn(label: Text('Rol')),
              DataColumn(label: Text('Estado')),
              DataColumn(label: Text('Tutorías'), numeric: true),
              DataColumn(label: Text('Ubicación')),
              DataColumn(label: Text('Artículos'), numeric: true),
              DataColumn(label: Text('Ficha')),
            ],
            rows: [
              for (final user in _store.users)
                DataRow(
                  selected: _id == user.id,
                  onSelectChanged: (_) =>
                      setState(() => _id = _id == user.id ? null : user.id),
                  cells: [
                    DataCell(
                      Text(
                        '#${user.id}',
                        style: const TextStyle(
                          color: ColoresAplicacion.muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 170,
                        child: Row(
                          children: [
                            AvatarAdmin(
                              name: user.name,
                              fileId: user.avatarId,
                              radius: 16,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    user.email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: ColoresAplicacion.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(Text(user.role)),
                    DataCell(EtiquetaEstado(user.status)),
                    DataCell(Text('${user.tutorialCount}')),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: Text(
                          user.location.isEmpty ? 'Sin indicar' : user.location,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text('${user.publicationCount}')),
                    DataCell(
                      IconButton(
                        tooltip: 'Ver ficha de ${user.name}',
                        onPressed: () => setState(
                          () => _id = _id == user.id ? null : user.id,
                        ),
                        icon: const Icon(Icons.chevron_right, size: 18),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        PaginacionApi(page: _store.adminUsersPage, load: _load),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _store,
    builder: (_, _) => EstructuraAdministracion(
      current: widget.accessView
          ? '${RutasAplicacion.user}?view=access'
          : RutasAplicacion.user,
      child: Column(
        children: [
          const BarraSuperiorAdmin(
            title: 'Usuarios',
            subtitle: 'Comunidad / Directorio, perfiles y permisos',
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(
                MediaQuery.sizeOf(context).width < 600 ? 14 : 22,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 280,
                        child: TextField(
                          controller: _search,
                          decoration: const InputDecoration(
                            hintText: 'Buscar nombre, correo o ID',
                            prefixIcon: Icon(Icons.search, size: 19),
                          ),
                          onChanged: (_) {
                            _debounce?.cancel();
                            _debounce = Timer(
                              const Duration(milliseconds: 350),
                              () {
                                if (mounted) unawaited(_load());
                              },
                            );
                          },
                        ),
                      ),
                      _filter('Rol', _role, const {
                        '': 'Todos los roles',
                        'usuario': 'Usuario',
                        'tutor': 'Tutor acreditado',
                        'administrador': 'Administrador',
                        'moderador': 'Moderador',
                        'revisor_tutores': 'Revisor',
                      }, (v) => _role = v),
                      _filter('Estado', _state, const {
                        '': 'Todos los estados',
                        'activo': 'Activo',
                        'pendiente_email': 'Por verificar',
                        'suspendido': 'Suspendido',
                      }, (v) => _state = v),
                      _filter('Ordenar', _sort, const {
                        'recientes': 'Más recientes',
                        'nombre': 'Nombre A–Z',
                        'publicaciones': 'Más publicaciones',
                      }, (v) => _sort = v),
                      IconButton(
                        tooltip: 'Actualizar directorio',
                        onPressed: () =>
                            _load(_store.adminUsersPage?.page ?? 1),
                        icon: const Icon(Icons.refresh, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (_, size) {
                        final panel = _id == null
                            ? null
                            : PanelCuentaUsuario(
                                key: ValueKey(_id),
                                id: _id!,
                                initialTab: widget.accessView
                                    ? 'manage'
                                    : 'content',
                                onClose: () => setState(() => _id = null),
                                onSaved: () =>
                                    _load(_store.adminUsersPage?.page ?? 1),
                              );
                        if (size.maxWidth >= 1000) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SingleChildScrollView(child: _table()),
                              ),
                              if (panel != null) ...[
                                const SizedBox(width: 18),
                                SizedBox(
                                  width: 320,
                                  child: SingleChildScrollView(child: panel),
                                ),
                              ],
                            ],
                          );
                        }
                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (panel != null) ...[
                                panel,
                                const SizedBox(height: 16),
                              ],
                              _table(),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
