import 'package:flutter/material.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/api_widgets.dart';

/// Superficie compacta del área administrativa, independiente del sitio público.
class AdminSurface extends StatelessWidget {
  const AdminSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x07000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

class AdminSectionHeading extends StatelessWidget {
  const AdminSectionHeading(
    this.title, {
    super.key,
    this.subtitle,
    this.action,
  });
  final String title;
  final String? subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ],
        ),
      ),
      ?action,
    ],
  );
}

/// Los campos cambian de columnas según su espacio real, no el ancho del monitor.
class AdminFieldGrid extends StatelessWidget {
  const AdminFieldGrid({
    super.key,
    required this.children,
    this.minFieldWidth = 240,
  });
  final List<Widget> children;
  final double minFieldWidth;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, size) {
      final columns = size.maxWidth >= minFieldWidth * 2 + 16 ? 2 : 1;
      final width = (size.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class AdminAvatar extends StatelessWidget {
  const AdminAvatar({
    super.key,
    required this.name,
    this.fileId,
    this.radius = 18,
  });
  final String name;
  final String? fileId;
  final double radius;
  @override
  Widget build(BuildContext context) => ClipOval(
    child: SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: ApiImage(
        fileId: fileId,
        fallback: ColoredBox(
          color: AppColors.surfaceBlue,
          child: Center(
            child: Text(
              name.trim().isEmpty
                  ? 'U'
                  : name.trim().characters.first.toUpperCase(),
              style: TextStyle(
                color: AppColors.blue,
                fontWeight: FontWeight.w700,
                fontSize: radius * .75,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class AdminEmpty extends StatelessWidget {
  const AdminEmpty(
    this.title, {
    super.key,
    this.message = 'Los registros aparecerán aquí cuando haya actividad.',
    this.icon = Icons.inbox_outlined,
  });
  final String title;
  final String message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.muted, size: 30),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}

/// Detalle de lectura: un valor faltante nunca se reemplaza con información ficticia.
class AdminInfo extends StatelessWidget {
  const AdminInfo(this.label, this.value, {super.key});
  final String label;
  final Object? value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ),
        Expanded(
          child: SelectableText(
            textValue(value).trim().isEmpty ? 'Sin indicar' : textValue(value),
            style: const TextStyle(fontSize: 12, color: AppColors.ink),
          ),
        ),
      ],
    ),
  );
}

String adminDate(Object? value) {
  final date = DateTime.tryParse(textValue(value))?.toLocal();
  return date == null
      ? '—'
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String adminAction(Object? value) {
  const labels = {
    'cuenta.registrada': 'Cuenta registrada',
    'perfil.actualizado': 'Perfil actualizado',
    'usuario.perfil_actualizado': 'Datos corregidos',
    'usuario.roles_actualizados': 'Permisos actualizados',
    'sesion.iniciada': 'Inicio de sesión',
    'anuncio.creado': 'Artículo creado',
    'tutoria.creada': 'Tutoría creada',
    'moderacion.bloqueada': 'Publicación bloqueada',
    'catalogo.actualizado': 'Catálogo actualizado',
  };
  return labels[value] ??
      textValue(value).replaceAll('.', ' · ').replaceAll('_', ' ');
}
