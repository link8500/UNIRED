import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'formato_anuncio_inicio.dart';

@JS('uniredRegisterDisplayAd')
external void _registerDisplayAd(web.HTMLElement unit);

class AnuncioInicio extends StatefulWidget {
  const AnuncioInicio({super.key, required this.format});
  final FormatoAnuncioInicio format;

  @override
  State<AnuncioInicio> createState() => _AnuncioInicioState();
}

class _AnuncioInicioState extends State<AnuncioInicio> {
  static const _slots = {
    FormatoAnuncioInicio.cuadrado: String.fromEnvironment(
      'ADSENSE_SQUARE_SLOT',
      defaultValue: '7849872648',
    ),
    FormatoAnuncioInicio.horizontal: String.fromEnvironment(
      'ADSENSE_HORIZONTAL_SLOT',
      defaultValue: '1064972445',
    ),
    FormatoAnuncioInicio.vertical: String.fromEnvironment(
      'ADSENSE_HOME_SLOT',
      defaultValue: '7759915295',
    ),
  };
  static final _validSlot = RegExp(r'^[0-9]+$');
  static final _publisher = RegExp(r'^ca-pub-[0-9]+$');
  late final String _client;
  web.MutationObserver? _statusObserver;
  bool _unavailable = false;

  void _hide() {
    if (!mounted || _unavailable) return;
    _statusObserver?.disconnect();
    setState(() => _unavailable = true);
  }

  @override
  void initState() {
    super.initState();
    _client =
        web.document
            .querySelector('meta[name="google-adsense-account"]')
            ?.getAttribute('content') ??
        '';
  }

  @override
  void dispose() {
    _statusObserver?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slot = _slots[widget.format]!;
    final location = web.window.location;
    if (_unavailable ||
        location.protocol != 'https:' ||
        location.hostname == 'localhost' ||
        (location.hostname.endsWith('.netlify.app') &&
            location.hostname.contains('--')) ||
        !_validSlot.hasMatch(slot) ||
        !_publisher.hasMatch(_client)) {
      return const SizedBox.shrink();
    }
    final format = widget.format;
    return Padding(
      padding: format == FormatoAnuncioInicio.vertical
          ? const EdgeInsets.only(left: 28)
          : const EdgeInsets.symmetric(vertical: 24),
      child: SizedBox(
        width: format.width,
        height: format.height,
        child: HtmlElementView.fromTagName(
          tagName: 'ins',
          onElementCreated: (element) {
            final unit = element as web.HTMLElement;
            unit.className = 'adsbygoogle';
            // El tamaño explícito coincide con el espacio reservado por Flutter.
            unit.style
              ..display = 'block'
              ..width = '${format.width.round()}px'
              ..height = '${format.height.round()}px';
            unit.setAttribute('data-ad-client', _client);
            unit.setAttribute('data-ad-slot', slot);
            _statusObserver?.disconnect();
            _statusObserver =
                web.MutationObserver(
                  (JSArray<web.MutationRecord> _, web.MutationObserver _) {
                    if (unit.getAttribute('data-ad-status') == 'unfilled' ||
                        unit.hasAttribute('data-unired-ad-error')) {
                      _hide();
                    }
                  }.toJS,
                )..observe(
                  unit,
                  web.MutationObserverInit(
                    attributes: true,
                    attributeFilter: [
                      'data-ad-status'.toJS,
                      'data-unired-ad-error'.toJS,
                    ].toJS,
                  ),
                );
            _registerDisplayAd(unit);
          },
        ),
      ),
    );
  }
}
