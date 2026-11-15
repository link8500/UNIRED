import 'package:flutter/material.dart';
import 'package:unired/models/admin/widgets/moderation_view.dart';

class AdminMarketPage extends StatelessWidget {
  const AdminMarketPage({super.key, this.ownerId});
  final String? ownerId;
  @override
  Widget build(BuildContext context) =>
      ModerationView(tutorials: false, ownerId: ownerId);
}
