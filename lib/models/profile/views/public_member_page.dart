import 'package:flutter/material.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/models/auth/models/app_user.dart';
import 'package:unired/models/profile/widgets/profile_identity_card.dart';
import 'package:unired/shared/widgets/api_collection.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/page_frame.dart';

class PublicMemberPage extends StatefulWidget {
  const PublicMemberPage({super.key, required this.id});
  final String id;

  @override
  State<PublicMemberPage> createState() => _PublicMemberPageState();
}

class _PublicMemberPageState extends State<PublicMemberPage> {
  late Future<Json> _profile = _load();
  bool _tutorials = false;

  Future<Json> _load() => AppService.instance.api.object(
    '/profiles/${Uri.encodeComponent(widget.id)}',
    authenticated: false,
  );

  @override
  Widget build(BuildContext context) => PublicPageFrame(
    route: AppRoutes.member,
    body: PageSection(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: FutureBuilder<Json>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ApiErrorNotice(
              message: snapshot.error.toString(),
              retry: () => setState(() => _profile = _load()),
            );
          }
          if (!snapshot.hasData) {
            return const ApiEmptyState(message: '', loading: true);
          }
          final data = snapshot.data!;
          final user = AppUser(
            id: widget.id,
            name: textValue(data['nombre']),
            email: '',
            university: '',
            avatarId: data['avatarArchivoId']?.toString(),
            bannerId: data['bannerArchivoId']?.toString(),
          );
          final details = [
            textValue(data['presentacion']),
            textValue(data['areaProfesional']),
            textValue(data['ciudad']),
            if (data['telefono'] != null) 'Teléfono: ${data['telefono']}',
          ].where((value) => value.trim().isNotEmpty);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileIdentityCard(user: user),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 16),
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final detail in details)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(detail),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Artículos'),
                    selected: !_tutorials,
                    onSelected: (_) => setState(() => _tutorials = false),
                  ),
                  ChoiceChip(
                    label: const Text('Tutorías'),
                    selected: _tutorials,
                    onSelected: (_) => setState(() => _tutorials = true),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SoftCard(
                child: ApiCollection(
                  key: ValueKey(_tutorials),
                  path: _tutorials ? '/courses' : '/listings',
                  query: {_tutorials ? 'tutorId' : 'vendedorId': widget.id},
                  empty: ApiEmptyState(
                    message: _tutorials
                        ? 'Este perfil no tiene tutorías públicas.'
                        : 'Este perfil no tiene artículos públicos.',
                  ),
                  builder: (rows) => Column(
                    children: [
                      for (final row in rows)
                        ListTile(
                          leading: Icon(
                            _tutorials
                                ? Icons.school_outlined
                                : Icons.storefront_outlined,
                          ),
                          title: Text(textValue(row['titulo'])),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => AppNavigator.go(
                            context,
                            Uri(
                              path: _tutorials
                                  ? AppRoutes.course
                                  : AppRoutes.listing,
                              queryParameters: {'id': textValue(row['id'])},
                            ).toString(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
