import 'package:flutter/material.dart';

import '../../models/project_idea_model.dart';
import 'create_idea_screen.dart';

class EditProjectIdeaScreen extends StatelessWidget {
  final ProjectIdeaModel idea;

  const EditProjectIdeaScreen({super.key, required this.idea});

  @override
  Widget build(BuildContext context) {
    return CreateIdeaScreen(idea: idea, isEditMode: true);
  }
}
