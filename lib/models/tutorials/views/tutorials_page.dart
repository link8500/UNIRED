import 'package:flutter/material.dart';
import 'package:unired/shared/widgets/remote_catalog.dart';

class TutorialsPage extends StatelessWidget {
  const TutorialsPage({super.key});
  @override
  Widget build(BuildContext context) => const RemoteCatalog(tutorials: true);
}
