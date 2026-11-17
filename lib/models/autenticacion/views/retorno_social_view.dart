// Recibe el código efímero y lo canjea por la sesión UniRed dentro de su pestaña original.
import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/autenticacion/views/estructura_autenticacion.dart';
import 'package:unired/models/autenticacion/widgets/widgets_autenticacion.dart';
import 'package:unired/shared/widgets/formulario_api.dart';

class RetornoSocialView extends StatefulWidget {
  const RetornoSocialView({super.key, this.code = '', this.error = ''});
  final String code, error;
  @override
  State<RetornoSocialView> createState() => _RetornoSocialViewState();
}

class _RetornoSocialViewState extends State<RetornoSocialView> {
  final _store = AplicacionController.instance;
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = true, _confirm = false, _previous = false, _profile = false;
  String? _error;
  Json _result = {};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _store.navegadorSocial.limpiarRetorno();
      if (widget.error.isNotEmpty || widget.code.isEmpty) {
        _store.navegadorSocial.limpiar();
        setState(() {
          _busy = false;
          _error = switch (widget.error) {
            'SOCIAL_CANCELLED' =>
              'Cancelaste el acceso. Puedes intentarlo otra vez o entrar con tu correo.',
            'SOCIAL_INVALID_STATE' =>
              'El intento caducó o ya se utilizó. Inicia uno nuevo.',
            _ =>
              'No pudimos completar el acceso. Vuelve a elegir Google o Facebook.',
          };
        });
      } else {
        _complete();
      }
    });
  }

  @override
  void dispose() {
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  Future<void> _complete({String? password}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _store.completarAccesoSocial(
        widget.code,
        password: password,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _confirm = result['requierePassword'] == true;
        _previous = result['requiereAccesoPrevio'] == true;
        _busy = false;
      });
      if (_confirm || _previous) return;
      final user = _store.currentUser!;
      if (user.verified &&
          !user.isStaff &&
          (user.university.isEmpty || user.major.isEmpty)) {
        setState(() => _profile = true);
        return;
      }
      _finish();
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error.toString();
        });
      }
    }
  }

  void _finish() {
    final admin = _result['volverAdmin'] == true,
        link = _result['vincular'] == true;
    final destination = _store.currentUser?.verified != true
        ? RutasAplicacion.verifyEmail
        : admin
        ? (link
              ? '${RutasAplicacion.adminProfile}?tab=security'
              : RutasAplicacion.dashboard)
        : link
        ? '${RutasAplicacion.profile}?tab=security'
        : RutasAplicacion.profile;
    NavegadorAplicacion.go(context, destination);
  }

  @override
  Widget build(BuildContext context) => EstructuraAutenticacion(
    isRegister: false,
    form: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloAutenticacion(
          title: _profile
              ? 'Completa tu perfil'
              : _confirm
              ? 'Conecta tu cuenta UniRed'
              : 'Acceso con tu cuenta',
          subtitle: _profile
              ? 'Solo faltan tus datos académicos para continuar.'
              : _confirm
              ? 'Ya tienes una cuenta con el correo compartido. Confirma tu contraseña de UniRed para conservar tus datos.'
              : 'Terminaremos la conexión de forma segura.',
        ),
        const SizedBox(height: 24),
        if (_busy)
          const Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Comprobando tu acceso…'),
            ],
          )
        else if (_profile)
          FormularioApi(
            title: 'Tu perfil universitario',
            label: 'Guardar y continuar',
            initial: _store.currentUser?.profileData ?? {},
            fields: const [
              CampoApi('universidad', 'Universidad'),
              CampoApi('carrera', 'Carrera'),
              CampoApi('telefono', 'Teléfono (opcional)', required: false),
            ],
            submit: (data) async {
              await _store.saveProfileData({...data, 'telefonoPublico': false});
              if (mounted) _finish();
            },
          )
        else if (_confirm)
          Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(
                    labelText: 'Contraseña de UniRed',
                  ),
                  validator: (value) => value?.isNotEmpty == true
                      ? null
                      : 'Escribe tu contraseña de UniRed.',
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    if (!_form.currentState!.validate()) return;
                    final value = _password.text;
                    _password.clear();
                    await _complete(password: value);
                  },
                  child: const Text('Confirmar y continuar'),
                ),
              ],
            ),
          )
        else if (_previous)
          const Text(
            'Esta cuenta ya utiliza otro método de acceso. Entra con tu método habitual y vincula el nuevo desde Mi cuenta → Seguridad.',
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (!_busy && !_profile)
          TextButton(
            onPressed: () {
              _store.navegadorSocial.limpiar();
              NavegadorAplicacion.go(context, RutasAplicacion.login);
            },
            child: const Text('Volver al acceso'),
          ),
      ],
    ),
  );
}
