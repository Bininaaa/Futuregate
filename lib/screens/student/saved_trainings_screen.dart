import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/training_provider.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/shared/app_feedback.dart';
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
      context.showAppSnackBar(
        'This resource does not have a link yet.',
        title: 'Link unavailable',
        type: AppFeedbackType.warning,
      );
      return;
    }

    final uri = Uri.tryParse(link);
    if (uri == null) {
      context.showAppSnackBar(
        'This resource link is not valid.',
        title: 'Link unavailable',
        type: AppFeedbackType.warning,
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && mounted) {
      context.showAppSnackBar(
        'We couldn\'t open this link right now.',
        title: 'Open unavailable',
        type: AppFeedbackType.error,
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
      context.showAppSnackBar(
        'This resource was removed from your saved list.',
        title: 'Saved items updated',
        type: AppFeedbackType.success,
      );
      return;
    }

    context.showAppSnackBar(
      error,
      title: 'Update unavailable',
      type: AppFeedbackType.error,
    );
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
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: AppEmptyStateNotice(
                    type: AppFeedbackType.warning,
                    icon: Icons.lock_outline_rounded,
                    title: 'Login required',
                    message:
                        'Sign in to view the training resources you saved.',
                  ),
                ),
              )
            : provider.isSavedLoading && provider.savedTrainings.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : provider.savedErrorMessage != null &&
                  provider.savedTrainings.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppEmptyStateNotice(
                    type: AppFeedbackType.error,
                    icon: Icons.cloud_off_rounded,
                    title: 'Saved resources unavailable',
                    message: provider.savedErrorMessage!,
                    action: AppFeedbackButton(
                      label: 'Retry',
                      onPressed: _refreshSaved,
                      icon: Icons.refresh_rounded,
                      type: AppFeedbackType.error,
                    ),
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _refreshSaved,
                child: provider.savedTrainings.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: AppEmptyStateNotice(
                              type: AppFeedbackType.neutral,
                              icon: Icons.bookmark_border_rounded,
                              title: 'No saved resources yet',
                              message:
                                  'Bookmark training resources to keep them here for later.',
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
