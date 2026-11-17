// Archivo: lib/models/autenticacion/widgets/formulario_acceso.dart
// Valida la entrada y coordina el inicio de sesión desde un formulario reutilizable.

import 'package:flutter/material.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/autenticacion/widgets/widgets_autenticacion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/models/autenticacion/widgets/botones_acceso_social.dart';

/// Un único formulario autentica usuarios y personal autorizado.
class FormularioAcceso extends StatefulWidget {
  const FormularioAcceso({super.key, this.admin = false});
  final bool admin;
  @override
  State<FormularioAcceso> createState() => _FormularioAccesoState();
}

class _FormularioAccesoState extends State<FormularioAcceso> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloAutenticacion(
          title: widget.admin ? 'Acceso al panel' : 'Bienvenido de nuevo',
          subtitle: widget.admin
              ? 'Usa el correo de tu cuenta autorizada.'
              : 'Conecta con tu comunidad UniRed.',
        ),
        const SizedBox(height: 24),
        CampoAutenticacion(
          label: 'CORREO ELECTRÓNICO',
          hint: 'nombre@ejemplo.com',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (v) =>
              v?.contains('@') == true ? null : 'Escribe un correo válido.',
        ),
        const SizedBox(height: 16),
        CampoAutenticacion(
          label: 'CONTRASEÑA',
          hint: 'Tu contraseña',
          controller: _password,
          obscure: _obscure,
          suffixIcon: IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(
              _obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
          validator: (v) =>
              v?.isNotEmpty == true ? null : 'Escribe tu contraseña.',
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () =>
                NavegadorAplicacion.go(context, RutasAplicacion.recover),
            child: const Text('¿Olvidaste tu contraseña?'),
          ),
        ),
        BotonAccionApi(
          label: 'Iniciar sesión',
          icon: Icons.login_rounded,
          action: () async {
            if (!_form.currentState!.validate()) return;
            final store = AplicacionController.instance;
            if (widget.admin) {
              await store.signInAdmin(
                username: _email.text,
                password: _password.text,
              );
            } else {
              await store.signIn(email: _email.text, password: _password.text);
            }
            if (!context.mounted) return;
            NavegadorAplicacion.go(
              context,
              store.currentUser?.verified != true
                  ? RutasAplicacion.verifyEmail
                  : widget.admin
                  ? RutasAplicacion.dashboard
                  : RutasAplicacion.profile,
            );
          },
        ),
        BotonesAccesoSocial(admin: widget.admin),
        const SizedBox(height: 12),
        const Text(
          'Tu sesión se mantiene mientras la aplicación está abierta.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11),
        ),
        TextButton(
          onPressed: () => NavegadorAplicacion.go(
            context,
            widget.admin ? RutasAplicacion.login : RutasAplicacion.register,
          ),
          child: Text(
            widget.admin ? 'Volver al acceso de usuarios' : 'Crear una cuenta',
          ),
        ),
      ],
    ),
  );
}
