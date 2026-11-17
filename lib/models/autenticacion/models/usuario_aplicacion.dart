// Archivo: lib/models/autenticacion/models/usuario_aplicacion.dart
// Representa la cuenta autenticada y traduce su perfil, roles y permisos desde la respuesta de NestJS.

import 'package:unired/core/dominio/datos_api.dart';

/// Perfil y roles de la cuenta autenticada, recibidos de /me.
///
/// Solo contiene datos de presentación: no guarda claves ni tokens.
class UsuarioAplicacion {
  const UsuarioAplicacion({
    required this.id,
    required this.name,
    required this.email,
    required this.university,
    this.major = '',
    this.year = '',
    this.city = '',
    this.country = '',
    this.department = '',
    this.campus = '',
    this.professionalArea = '',
    this.occupation = '',
    this.works,
    this.roles = const [],
    this.phone = '',
    this.bio = '',
    this.state = 'activo',
    this.avatarId,
    this.bannerId,
    this.notificationsEnabled = true,
    this.publicPhone = false,
    this.age,
    this.emailVerificationRequired = true,
    this.hasPassword = true,
  });

  final String id;
  final String name;
  final String email;
  final String university;
  final String major;
  final String year;
  final String city;
  final String country;
  final String department;
  final String campus;
  final String professionalArea;
  final String occupation;
  final bool? works;
  final List<String> roles;
  final String phone;
  final String bio;
  final String state;
  final String? avatarId;
  final String? bannerId;
  final bool notificationsEnabled;
  final bool publicPhone;
  final int? age;
  final bool emailVerificationRequired;
  final bool hasPassword;

  /// Ciudad, universidad y carrera son datos distintos en el contrato HTTP.
  factory UsuarioAplicacion.fromJson(Json row) {
    final p = jsonObject(row['perfil']);
    return UsuarioAplicacion(
      id: textValue(row['id']),
      name: textValue(row['nombre']),
      email: textValue(row['email']),
      university: textValue(p['universidad']),
      major: textValue(p['carrera']),
      year: textValue(p['anioEstudio']),
      city: textValue(p['ciudad']),
      country: textValue(p['pais']),
      department: textValue(p['departamento']),
      campus: textValue(p['sede']),
      professionalArea: textValue(p['areaProfesional']),
      occupation: textValue(p['ocupacion']),
      works: p['trabaja'] is bool ? p['trabaja'] as bool : null,
      phone: textValue(p['telefono']),
      bio: textValue(p['presentacion']),
      roles: (row['roles'] is List ? row['roles'] as List : [])
          .map((r) => r.toString())
          .toList(),
      state: textValue(row['estado']),
      emailVerificationRequired: row['verificacionEmailRequerida'] != false,
      hasPassword: row['tienePassword'] != false,
      avatarId: p['avatarArchivoId']?.toString(),
      bannerId: p['bannerArchivoId']?.toString(),
      notificationsEnabled: p['notificacionesActivas'] != false,
      publicPhone: p['telefonoPublico'] == true,
      age: row['edad'] == null ? null : intValue(row['edad']),
    );
  }
  Json get profileData => {
    'nombre': name,
    'edad': age,
    'universidad': university,
    'carrera': major,
    'anioEstudio': year,
    'ciudad': city,
    'pais': country,
    'departamento': department,
    'sede': campus,
    'areaProfesional': professionalArea,
    'ocupacion': occupation,
    'trabaja': works,
    'telefono': phone,
    'presentacion': bio,
    'telefonoPublico': publicPhone,
  };

  /// Acceso efectivo que autoriza el servidor, no prueba de posesión del correo.
  bool get verified => state == 'activo';
  bool get isAdministrator => roles.contains('administrador');
  bool get canModerate => isAdministrator || roles.contains('moderador');
  bool get canReview => isAdministrator || roles.contains('revisor_tutores');
  bool get isStaff => canModerate || canReview;

  /// Crea una copia con los campos editables del perfil actualizados.
  UsuarioAplicacion copyWith({
    String? name,
    String? university,
    String? major,
    String? year,
    String? phone,
    String? bio,
  }) {
    return UsuarioAplicacion(
      id: id,
      name: name ?? this.name,
      email: email,
      university: university ?? this.university,
      major: major ?? this.major,
      year: year ?? this.year,
      city: city,
      country: country,
      department: department,
      campus: campus,
      professionalArea: professionalArea,
      occupation: occupation,
      works: works,
      roles: roles,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      state: state,
      emailVerificationRequired: emailVerificationRequired,
      hasPassword: hasPassword,
      avatarId: avatarId,
      bannerId: bannerId,
      notificationsEnabled: notificationsEnabled,
      publicPhone: publicPhone,
      age: age,
    );
  }
}
