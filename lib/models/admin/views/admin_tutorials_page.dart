import 'package:flutter/material.dart';
import 'package:unired/models/admin/widgets/moderation_view.dart';

class AdminTutorialsPage extends StatelessWidget {
  const AdminTutorialsPage({super.key, this.ownerId});
  final String? ownerId;
  @override
  Widget build(BuildContext context) =>
      ModerationView(tutorials: true, ownerId: ownerId);
}
