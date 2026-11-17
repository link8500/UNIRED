// La API decide qué proveedores están activos; las claves permanecen en NestJS.
import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/shared/widgets/widgets_api.dart';

class IconoProveedorSocial extends StatelessWidget {
  const IconoProveedorSocial(this.proveedor, {super.key});
  final String proveedor;
  @override
  Widget build(BuildContext context) => proveedor == 'google'
      ? Image.asset(
          'assets/branding/google-g.png',
          width: 20,
          height: 20,
          fit: BoxFit.contain,
        )
      : const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 24);
}

class BotonesAccesoSocial extends StatefulWidget {
  const BotonesAccesoSocial({super.key, this.admin = false});
  final bool admin;
  @override
  State<BotonesAccesoSocial> createState() => _BotonesAccesoSocialState();
}

class _BotonesAccesoSocialState extends State<BotonesAccesoSocial> {
  final _store = AplicacionController.instance;
  late Future<Json> _providers = _load();
  String? _opening;
  Future<Json> _load() => _store.api.object(
    '/auth/social/providers',
    authenticated: false,
    foreground: false,
  );
  @override
  Widget build(BuildContext context) {
    if (!_store.navegadorSocial.disponible) return const SizedBox.shrink();
    return FutureBuilder<Json>(
      future: _providers,
      builder: (context, snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 22),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('O continúa con', style: TextStyle(fontSize: 12)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            for (final provider in ['google', 'facebook'])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1F1F1F),
                    side: const BorderSide(color: Color(0xFF747775)),
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed:
                      snapshot.data?[provider] != true || _opening != null
                      ? null
                      : () async {
                          setState(() => _opening = provider);
                          await runApiAction(
                            context,
                            () => _store.iniciarAccesoSocial(
                              provider,
                              admin: widget.admin,
                            ),
                          );
                          if (mounted) setState(() => _opening = null);
                        },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_opening == provider)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        IconoProveedorSocial(provider),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Continuar con ${provider == 'google' ? 'Google' : 'Facebook'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (snapshot.hasError)
              TextButton.icon(
                onPressed: () => setState(() {
                  _providers = _load();
                }),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reintentar las opciones de acceso'),
              )
            else if (snapshot.hasData &&
                snapshot.data!['google'] != true &&
                snapshot.data!['facebook'] != true)
              const Text(
                'El acceso social todavía no está habilitado. Puedes continuar con tu correo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
          ],
        );
      },
    );
  }
}
