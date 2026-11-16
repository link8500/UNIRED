// Archivo: lib/models/tutorias/models/tutoria.dart
// Modelo de presentación de un curso con tutor, modalidad, precio, métricas y estado.

import 'package:flutter/material.dart';
import 'package:unired/core/constantes/estado_publicacion.dart';

/// Curso recibido desde la API, con cifras calculadas por el servidor.
class Tutoria {
  const Tutoria({
    required this.id,
    required this.title,
    required this.meta,
    required this.icon,
    required this.accent,
    required this.category,
    required this.body,
    this.mentor = 'Comunidad UniRed',
    this.mentorId = '',
    this.students = 0,
    this.rating = 0,
    this.amount = 0,
    this.level = 'Todos los niveles',
    this.status = EstadoPublicacion.published,
    this.discountPercent = 0,
    this.areaId = 0,
    this.versionLock = 1,
    this.imageId,
    this.modality = 'grabada',
    this.currency = 'NIO',
    this.lessonCount = 0,
    this.sectionCount = 0,
    this.resourceCount = 0,
    this.durationMinutes = 0,
  });

  final String id;
  final String title;
  final String meta;
  final IconData icon;
  final Color accent;
  final String category;
  final String body;
  final String mentor;
  final String mentorId;
  final int students;
  final double rating;
  final double amount;
  final String level;
  final EstadoPublicacion status;
  final double discountPercent;
  final int areaId;
  final int versionLock;
  final String? imageId;
  final String modality;
  final String currency;
  final int lessonCount, sectionCount, resourceCount, durationMinutes;
  double get effectiveAmount =>
      double.parse((amount * (1 - discountPercent / 100)).toStringAsFixed(2));
  String get displayPrice => amount == 0
      ? 'Gratis'
      : '$currency ${effectiveAmount.toStringAsFixed(2)}';

  /// Mantiene identidad y métricas al guardar una edición administrativa.
  Tutoria copyWith({
    String? title,
    String? meta,
    String? category,
    String? body,
    String? mentor,
    String? mentorId,
    double? amount,
    String? level,
    int? students,
    EstadoPublicacion? status,
    double? discountPercent,
  }) {
    return Tutoria(
      id: id,
      title: title ?? this.title,
      meta: meta ?? this.meta,
      icon: icon,
      accent: accent,
      category: category ?? this.category,
      body: body ?? this.body,
      mentor: mentor ?? this.mentor,
      mentorId: mentorId ?? this.mentorId,
      students: students ?? this.students,
      rating: rating,
      amount: amount ?? this.amount,
      level: level ?? this.level,
      status: status ?? this.status,
      discountPercent: discountPercent ?? this.discountPercent,
      areaId: areaId,
      versionLock: versionLock,
      imageId: imageId,
      modality: modality,
      currency: currency,
      lessonCount: lessonCount,
      sectionCount: sectionCount,
      resourceCount: resourceCount,
      durationMinutes: durationMinutes,
    );
  }
}
