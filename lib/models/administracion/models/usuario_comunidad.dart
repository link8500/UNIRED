// Archivo: lib/models/administracion/models/usuario_comunidad.dart
// Modelo administrativo de un usuario, sus roles y sus métricas autorizadas.

import 'package:flutter/material.dart';

/// Usuario recibido del directorio administrativo autorizado.
class UsuarioComunidad {
  const UsuarioComunidad({
    required this.id,
    required this.name,
    required this.major,
    required this.status,
    required this.accent,
    required this.email,
    required this.year,
    this.roles = const [],
    this.location = '',
    this.university = '',
    this.avatarId,
    this.publicationCount = 0,
    this.tutorialCount = 0,
    this.accredited = false,
  });

  final String id;
  final String name;
  final String major;
  final String status;
  final Color accent;
  final String email;
  final String year;
  final List<String> roles;
  final String location;
  final String university;
  final String? avatarId;
  final int publicationCount;
  final int tutorialCount;
  final bool accredited;

  String get role => roles.contains('administrador')
      ? 'Admin'
      : roles.contains('moderador')
      ? 'Moderador'
      : roles.contains('revisor_tutores')
      ? 'Revisor'
      : accredited
      ? 'Tutor'
      : 'Usuario';

  UsuarioComunidad copyWith({
    String? status,
    String? name,
    String? major,
    String? year,
    String? location,
  }) => UsuarioComunidad(
    id: id,
    name: name ?? this.name,
    major: major ?? this.major,
    status: status ?? this.status,
    accent: accent,
    email: email,
    year: year ?? this.year,
    roles: roles,
    location: location ?? this.location,
    university: university,
    avatarId: avatarId,
    publicationCount: publicationCount,
    tutorialCount: tutorialCount,
    accredited: accredited,
  );
}
