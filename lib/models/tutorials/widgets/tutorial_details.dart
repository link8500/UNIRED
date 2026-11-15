import 'package:flutter/material.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/models/tutorials/models/tutorial_item.dart';

/// Abre una página real con currículo, inscripción y contenido autorizado.
void showTutorialDetails(BuildContext context, TutorialItem item) =>
    AppNavigator.go(context, '${AppRoutes.course}?id=${item.id}');
