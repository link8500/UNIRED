// Archivo: lib/shared/widgets/selector_municipio.dart
// Permite elegir departamento y municipio utilizando el catálogo común de ubicaciones.

import 'package:flutter/material.dart';
import 'package:unired/core/constantes/municipios_nicaragua.dart';

Future<String?> pickMunicipality(BuildContext context) => showDialog<String>(
  context: context,
  builder: (_) => const _SelectorMunicipio(),
);

class _SelectorMunicipio extends StatefulWidget {
  const _SelectorMunicipio();

  @override
  State<_SelectorMunicipio> createState() => _SelectorMunicipioState();
}

class _SelectorMunicipioState extends State<_SelectorMunicipio> {
  String _query = '';

  static String _searchable(String value) => value
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u');

  @override
  Widget build(BuildContext context) {
    final matches = nicaraguaMunicipalities
        .where((name) => _searchable(name).contains(_query))
        .toList(growable: false);
    return AlertDialog(
      title: const Text('Seleccionar municipio'),
      content: SizedBox(
        width: 410,
        height: 360,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Buscar en Nicaragua',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  setState(() => _query = _searchable(value.trim())),
              onSubmitted: (_) {
                if (matches.length == 1) Navigator.pop(context, matches.single);
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: matches.isEmpty
                  ? const Center(child: Text('Sin coincidencias'))
                  : ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.place_outlined, size: 18),
                        title: Text(matches[index]),
                        onTap: () => Navigator.pop(context, matches[index]),
                      ),
                    ),
            ),
            const Text(
              'geoBoundaries · OpenStreetMap · ODbL 1.0',
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
