// Archivo: lib/models/autenticacion/views/registro_view.dart
// Recoge los datos de registro y envía la solicitud de creación de la cuenta.

import 'package:flutter/material.dart';
import 'package:unired/shared/widgets/avisos_aplicacion.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/autenticacion/views/estructura_autenticacion.dart';
import 'package:unired/models/autenticacion/widgets/widgets_autenticacion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';

class RegistroView extends StatefulWidget {
  const RegistroView({super.key});
  @override
  State<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends State<RegistroView> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => EstructuraAutenticacion(
    isRegister: true,
    form: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TituloAutenticacion(
            title: 'Crea tu cuenta',
            subtitle: 'Aprende, comparte y conecta en UniRed.',
          ),
          const SizedBox(height: 26),
          CampoAutenticacion(
            label: 'NOMBRE COMPLETO',
            hint: 'Tu nombre',
            controller: _name,
            validator: (v) =>
                (v?.trim().length ?? 0) >= 3 ? null : 'Escribe tu nombre.',
          ),
          const SizedBox(height: 16),
          CampoAutenticacion(
            label: 'CORREO ELECTRÓNICO',
            hint: 'nombre@ejemplo.com',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                v?.contains('@') == true ? null : 'Escribe un correo válido.',
          ),
          const SizedBox(height: 16),
          CampoAutenticacion(
            label: 'CONTRASEÑA',
            hint: 'Al menos 12 caracteres',
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
                (v?.length ?? 0) >= 12 ? null : 'Usa al menos 12 caracteres.',
          ),
          const SizedBox(height: 16),
          const Text(
            'El servidor indicará si tu cuenta necesita verificar el correo.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 18),
          BotonAccionApi(
            label: 'Crear cuenta',
            action: () async {
              if (!_form.currentState!.validate()) return;
              final result = await AplicacionController.instance.register(
                name: _name.text,
                email: _email.text,
                password: _password.text,
              );
              if (context.mounted) {
                await AvisosAplicacion.show(
                  context,
                  kind: TipoAviso.success,
                  title: 'Cuenta creada',
                  message: textValue(
                    result['mensaje'],
                    'Tu cuenta está lista.',
                  ),
                );
                if (!context.mounted) return;
                NavegadorAplicacion.go(
                  context,
                  result['verificacionEmailRequerida'] == false
                      ? RutasAplicacion.login
                      : RutasAplicacion.verifyEmail,
                );
              }
            },
          ),
          TextButton(
            onPressed: () =>
                NavegadorAplicacion.go(context, RutasAplicacion.login),
            child: const Text('Ya tengo una cuenta'),
          ),
        ],
      ),
    ),
  );
}
