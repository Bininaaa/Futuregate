import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/project_idea_provider.dart';

class SubmitProjectIdeaScreen extends StatefulWidget {
  const SubmitProjectIdeaScreen({super.key});

  @override
  State<SubmitProjectIdeaScreen> createState() =>
      _SubmitProjectIdeaScreenState();
}

class _SubmitProjectIdeaScreenState extends State<SubmitProjectIdeaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _domainController = TextEditingController();
  final _toolsController = TextEditingController();

  String _selectedLevel = 'bac';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _domainController.dispose();
    _toolsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final provider = context.read<ProjectIdeaProvider>();
    final currentUser = authProvider.userModel;

    if (currentUser == null) return;

    final error = await provider.submitProjectIdea(
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
        const SnackBar(content: Text('Project idea submitted successfully')),
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
      appBar: AppBar(title: const Text('Submit Project Idea')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Submit Idea',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
