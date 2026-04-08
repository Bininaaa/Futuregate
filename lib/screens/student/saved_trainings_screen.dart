import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/training_provider.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/student/student_workspace_shell.dart';
import '../../widgets/training_resource_card.dart';

class SavedTrainingsScreen extends StatefulWidget {
  const SavedTrainingsScreen({super.key});

  @override
  State<SavedTrainingsScreen> createState() => _SavedTrainingsScreenState();
}

class _SavedTrainingsScreenState extends State<SavedTrainingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) {
        return;
      }

      final uid = context.read<AuthProvider>().userModel?.uid;
      if (uid != null && uid.isNotEmpty) {
        await context.read<TrainingProvider>().fetchSavedTrainings(uid);
      }
    });
  }

  Future<void> _refreshSaved() async {
    final uid = context.read<AuthProvider>().userModel?.uid;
    if (uid == null || uid.isEmpty) {
      return;
    }

    await context.read<TrainingProvider>().fetchSavedTrainings(uid);
  }

  Future<void> _openLink(String link) async {
    if (link.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This resource does not have a link yet.'),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(link);
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid link')));
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We couldn\'t open this link.')),
      );
    }
  }

  Future<void> _removeSaved(String trainingId) async {
    final provider = context.read<TrainingProvider>();
    final uid = context.read<AuthProvider>().userModel?.uid;

    if (uid == null || uid.isEmpty) {
      return;
    }

    final error = await provider.unsaveTraining(
      userId: uid,
      trainingId: trainingId,
    );

    if (!mounted) {
      return;
    }

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from saved resources')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final provider = context.watch<TrainingProvider>();
    final uid = authProvider.userModel?.uid ?? '';

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: StudentWorkspaceAppBar(
          title: 'Saved Resources',
          subtitle: 'Training content you bookmarked for later.',
          icon: Icons.bookmark_rounded,
          showBackButton: true,
          onBack: () => Navigator.maybePop(context),
          actions: [
            StudentWorkspaceActionButton(
              icon: Icons.refresh_rounded,
              tooltip: 'Refresh saved resources',
              onTap: () => _refreshSaved(),
            ),
          ],
        ),
        body: uid.isEmpty
            ? const Center(
                child: Text('You must be logged in to view saved resources'),
              )
            : provider.isSavedLoading && provider.savedTrainings.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : provider.savedErrorMessage != null &&
                  provider.savedTrainings.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        provider.savedErrorMessage!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _refreshSaved,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _refreshSaved,
                child: provider.savedTrainings.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 180),
                          Icon(
                            Icons.bookmark_border_rounded,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Center(
                            child: Text(
                              'You have no saved resources yet.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: provider.savedTrainings.length,
                        itemBuilder: (context, index) {
                          final training = provider.savedTrainings[index];
                          return TrainingResourceCard(
                            training: training,
                            isSaved: true,
                            isSaveBusy: provider.isTrainingBusy(training.id),
                            onOpen: () => _openLink(training.displayLink),
                            onToggleSaved: () => _removeSaved(training.id),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
