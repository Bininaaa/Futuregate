import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/project_idea_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_idea_provider.dart';

class EditProjectIdeaScreen extends StatefulWidget {
  final ProjectIdeaModel idea;

  const EditProjectIdeaScreen({super.key, required this.idea});

  @override
  State<EditProjectIdeaScreen> createState() => _EditProjectIdeaScreenState();
}

class _EditProjectIdeaScreenState extends State<EditProjectIdeaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _domainController;
  late final TextEditingController _toolsController;

  late String _selectedLevel;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.idea.title);
    _descriptionController = TextEditingController(
      text: widget.idea.description,
    );
    _domainController = TextEditingController(text: widget.idea.domain);
    _toolsController = TextEditingController(text: widget.idea.tools);
    _selectedLevel = widget.idea.level;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _domainController.dispose();
    _toolsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final provider = context.read<ProjectIdeaProvider>();
    final currentUser = authProvider.userModel;

    if (currentUser == null) return;

    final error = await provider.updateProjectIdea(
      id: widget.idea.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      domain: _domainController.text.trim(),
      level: _selectedLevel,
      tools: _toolsController.text.trim(),
      submittedBy: currentUser.uid,
    );

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Idea updated successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectIdeaProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Project Idea')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can only edit this idea while it is pending review.',
                      style: TextStyle(fontSize: 13, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Project Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _domainController,
              decoration: const InputDecoration(
                labelText: 'Domain (e.g. AI, Web, Mobile)',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Domain is required' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedLevel,
              decoration: const InputDecoration(
                labelText: 'Target Level',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'bac', child: Text('Bachelor')),
                DropdownMenuItem(value: 'licence', child: Text('Licence')),
                DropdownMenuItem(value: 'master', child: Text('Master')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _selectedLevel = v);
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _toolsController,
              decoration: const InputDecoration(
                labelText: 'Tools / Technologies',
                border: OutlineInputBorder(),
                hintText: 'e.g. Flutter, Python, Firebase',
              ),
            ),
            const SizedBox(height: 24),
            provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
