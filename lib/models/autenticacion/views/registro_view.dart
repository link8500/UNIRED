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
import 'package:unired/models/autenticacion/widgets/botones_acceso_social.dart';

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
  final _university = TextEditingController();
  final _career = TextEditingController();
  final _phone = TextEditingController();
  int _step = 0;
  bool _obscure = true;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _university.dispose();
    _career.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => EstructuraAutenticacion(
    isRegister: true,
    form: Form(
      key: _form,
      child: Column(
        key: ValueKey(_step),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TituloAutenticacion(
            title: 'Crea tu cuenta',
            subtitle: 'Aprende, comparte y conecta en UniRed.',
          ),
          const SizedBox(height: 26),
          Text(
            'Paso ${_step + 1} de 2 · ${_step == 0 ? 'Tu cuenta' : 'Tu perfil universitario'}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 16),
          if (_step == 0) ...[
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
          ] else ...[
            CampoAutenticacion(
              label: 'UNIVERSIDAD',
              hint: '¿Dónde estudias?',
              controller: _university,
              validator: (value) => (value?.trim().length ?? 0) >= 2
                  ? null
                  : 'Escribe tu universidad.',
            ),
            const SizedBox(height: 16),
            CampoAutenticacion(
              label: 'CARRERA',
              hint: '¿Qué estudias?',
              controller: _career,
              validator: (value) => (value?.trim().length ?? 0) >= 2
                  ? null
                  : 'Escribe tu carrera.',
            ),
            const SizedBox(height: 16),
            CampoAutenticacion(
              label: 'TELÉFONO (OPCIONAL)',
              hint: 'Tu número de contacto',
              controller: _phone,
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  value == null ||
                      value.trim().isEmpty ||
                      RegExp(
                        r'^\d{7,15}$',
                      ).hasMatch(value.replaceAll(RegExp(r'\D'), ''))
                  ? null
                  : 'Escribe un teléfono de 7 a 15 dígitos.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Podrás completar tu edad, año de estudio, trabajo y residencia desde Mi perfil. Tu teléfono se guarda de forma privada.',
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'El servidor indicará si tu cuenta necesita verificar el correo.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 18),
          BotonAccionApi(
            label: _step == 0 ? 'Continuar' : 'Crear cuenta',
            action: () async {
              if (!_form.currentState!.validate()) return;
              if (_step == 0) {
                setState(() => _step = 1);
                return;
              }
              final result = await AplicacionController.instance.register(
                name: _name.text,
                email: _email.text,
                password: _password.text,
                profile: {
                  'universidad': _university.text.trim(),
                  'carrera': _career.text.trim(),
                  if (_phone.text.trim().isNotEmpty)
                    'telefono': _phone.text.trim(),
                  'telefonoPublico': false,
                },
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
          if (_step == 1)
            TextButton(
              onPressed: () => setState(() => _step = 0),
              child: const Text('Volver a los datos de acceso'),
            ),
          if (_step == 0) const BotonesAccesoSocial(),
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
