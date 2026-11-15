import 'package:flutter/material.dart';

/// Usuario recibido del directorio administrativo autorizado.
class CommunityUser {
  const CommunityUser({
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

  CommunityUser copyWith({
    String? status,
    String? name,
    String? major,
    String? year,
    String? location,
  }) => CommunityUser(
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
