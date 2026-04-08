import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/avatar_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../screens/settings/account_security_screens.dart';
import '../../screens/settings/settings_flow_theme.dart';
import '../../screens/settings/settings_flow_widgets.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/shared/app_feedback.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _fieldOfStudyController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _initialized = false;
  bool _uploadingPhoto = false;

  StudentProvider get _studentProvider => context.read<StudentProvider>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) {
      return;
    }

    final student = context.read<StudentProvider>().student;
    final authUser = context.read<AuthProvider>().userModel;

    _fullNameController.text = (student?.fullName ?? authUser?.fullName ?? '')
        .trim();
    _emailController.text = (student?.email ?? authUser?.email ?? '').trim();
    _phoneController.text = student?.phone ?? '';
    _locationController.text = student?.location ?? '';
    _universityController.text = student?.university ?? '';
    _fieldOfStudyController.text = student?.fieldOfStudy ?? '';
    _bioController.text = student?.bio ?? '';

    _initialized = true;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _universityController.dispose();
    _fieldOfStudyController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.userModel;
    if (currentUser == null) {
      return;
    }

    final error = await _studentProvider.updateStudentProfile(
      uid: currentUser.uid,
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      location: _locationController.text.trim(),
      university: _universityController.text.trim(),
      fieldOfStudy: _fieldOfStudyController.text.trim(),
      bio: _bioController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (error != null) {
      context.showAppSnackBar(
        error,
        title: 'Update unavailable',
        type: AppFeedbackType.error,
      );
      return;
    }

    await authProvider.loadCurrentUser();

    if (!mounted) {
      return;
    }

    context.showAppSnackBar(
      'Your profile has been updated successfully.',
      title: 'Profile updated',
      type: AppFeedbackType.success,
    );
    Navigator.pop(context);
  }

  Future<void> _selectAvatar(String avatarId) async {
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null || _studentProvider.isLoading || _uploadingPhoto) {
      return;
    }

    final error = await _studentProvider.selectAvatar(
      uid: currentUser.uid,
      avatarId: avatarId,
    );

    if (!mounted) {
      return;
    }

    if (error != null) {
      context.showAppSnackBar(
        error,
        title: 'Avatar unavailable',
        type: AppFeedbackType.error,
      );
      return;
    }

    await context.read<AuthProvider>().loadCurrentUser();
  }

  Future<void> _useUploadedPhoto() async {
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null || _studentProvider.isLoading || _uploadingPhoto) {
      return;
    }

    final error = await _studentProvider.useUploadedProfilePhoto(
      currentUser.uid,
    );

    if (!mounted) {
      return;
    }

    if (error != null) {
      context.showAppSnackBar(
        error,
        title: 'Photo unavailable',
        type: AppFeedbackType.error,
      );
      return;
    }

    await context.read<AuthProvider>().loadCurrentUser();
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_uploadingPhoto || _studentProvider.isLoading) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    final file = result.files.single;
    if (file.size > 5 * 1024 * 1024) {
      if (!mounted) {
        return;
      }
      context.showAppSnackBar(
        'Choose an image smaller than 5 MB.',
        title: 'Upload unavailable',
        type: AppFeedbackType.warning,
      );
      return;
    }

    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) {
      return;
    }

    setState(() => _uploadingPhoto = true);

    final error = await _studentProvider.uploadProfilePhoto(
      uid: currentUser.uid,
      fileName: file.name,
      filePath: file.path ?? '',
      fileBytes: file.bytes,
    );

    if (!mounted) {
      return;
    }

    setState(() => _uploadingPhoto = false);

    if (error != null) {
      context.showAppSnackBar(
        error,
        title: 'Upload unavailable',
        type: AppFeedbackType.error,
      );
      return;
    }

    await context.read<AuthProvider>().loadCurrentUser();
  }

  Future<void> _removePhoto() async {
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) {
      return;
    }

    final error = await _studentProvider.removeProfilePhoto(currentUser.uid);

    if (!mounted) {
      return;
    }

    if (error != null) {
      context.showAppSnackBar(
        error,
        title: 'Remove unavailable',
        type: AppFeedbackType.error,
      );
      return;
    }

    await context.read<AuthProvider>().loadCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final student =
        context.watch<StudentProvider>().student ?? authProvider.userModel;
    final hasUploadedPhoto =
        student != null && (student.profileImage).trim().isNotEmpty;
    final isUploadActive = student?.photoType == 'upload';

    return SettingsPageScaffold(
      title: 'Edit Profile',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsPanel(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF0F4FF), Color(0xFFE6FFFB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: SettingsFlowTheme.radius(28),
                      ),
                      child: Center(
                        child: _uploadingPhoto
                            ? const SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: SettingsFlowPalette.primary,
                                ),
                              )
                            : ProfileAvatar(user: student, radius: 32),
                      ),
                    ),
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _pickAndUploadPhoto,
                          borderRadius: BorderRadius.circular(18),
                          child: Ink(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: SettingsFlowPalette.primary,
                              borderRadius: SettingsFlowTheme.radius(16),
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Update your profile',
                  style: SettingsFlowTheme.sectionTitle(),
                ),
                const SizedBox(height: 6),
                Text(
                  'Refresh your details, switch avatars, or upload a new photo without affecting your existing account logic.',
                  style: SettingsFlowTheme.caption(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SettingsButtonGroup(
                  children: [
                    SettingsSecondaryButton(
                      label: 'Choose Avatar',
                      icon: Icons.face_retouching_natural_rounded,
                      onPressed: () =>
                          _showAvatarPicker(context, student?.avatarId),
                    ),
                    SettingsPrimaryButton(
                      label: 'Upload Photo',
                      icon: Icons.upload_rounded,
                      onPressed: _pickAndUploadPhoto,
                    ),
                  ],
                ),
                if (hasUploadedPhoto || student?.photoType == 'avatar') ...[
                  const SizedBox(height: 12),
                  SettingsButtonGroup(
                    children: [
                      if (hasUploadedPhoto && !isUploadActive)
                        SettingsSecondaryButton(
                          label: 'Use Uploaded',
                          onPressed: _useUploadedPhoto,
                        ),
                      SettingsSecondaryButton(
                        label: 'Remove Photo',
                        color: SettingsFlowPalette.error,
                        onPressed: _removePhoto,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SettingsSectionHeading(
            title: 'Basic Details',
            subtitle:
                'Use graceful fallbacks where data is missing and keep email changes on the secure auth flow.',
          ),
          const SizedBox(height: 10),
          SettingsPanel(
            child: Column(
              children: [
                _ProfileField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 14),
                _ProfileField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  readOnly: true,
                  suffix: TextButton(
                    onPressed: authProvider.isEmailProvider
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChangeEmailScreen(),
                            ),
                          )
                        : null,
                    child: Text(
                      authProvider.isEmailProvider ? 'Change' : 'Managed',
                      style: SettingsFlowTheme.micro(
                        SettingsFlowPalette.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _ProfileField(
                  controller: _phoneController,
                  label: 'Phone',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                _ProfileField(
                  controller: _locationController,
                  label: 'Location',
                  icon: Icons.location_on_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SettingsSectionHeading(
            title: 'Academic Profile',
            subtitle:
                'Keep your student context current so opportunity matching stays useful.',
          ),
          const SizedBox(height: 10),
          SettingsPanel(
            child: Column(
              children: [
                _ProfileField(
                  controller: _universityController,
                  label: 'University',
                  icon: Icons.school_outlined,
                ),
                const SizedBox(height: 14),
                _ProfileField(
                  controller: _fieldOfStudyController,
                  label: 'Field of Study',
                  icon: Icons.auto_stories_outlined,
                ),
                const SizedBox(height: 14),
                _ProfileField(
                  controller: _bioController,
                  label: 'Bio',
                  icon: Icons.notes_rounded,
                  maxLines: 5,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SettingsPrimaryButton(
            label: _studentProvider.isLoading ? 'Saving...' : 'Save Changes',
            icon: _studentProvider.isLoading ? null : Icons.check_rounded,
            onPressed: _studentProvider.isLoading || _uploadingPhoto
                ? null
                : _saveProfile,
          ),
        ],
      ),
    );
  }

  void _showAvatarPicker(BuildContext context, String? selectedAvatarId) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: SettingsFlowPalette.surface,
            borderRadius: SettingsFlowTheme.radius(26),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: SettingsFlowPalette.border,
                    borderRadius: SettingsFlowTheme.radius(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Choose an Avatar', style: SettingsFlowTheme.sectionTitle()),
              const SizedBox(height: 6),
              Text(
                'Pick a built-in look, or keep using your uploaded photo.',
                style: SettingsFlowTheme.caption(),
              ),
              const SizedBox(height: 18),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: AvatarConfig.avatars.length,
                itemBuilder: (context, index) {
                  final avatar = AvatarConfig.avatars[index];
                  final isSelected = selectedAvatarId == avatar.id;

                  return InkWell(
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _selectAvatar(avatar.id);
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? SettingsFlowPalette.primary
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundColor: avatar.backgroundColor,
                        child: Icon(
                          avatar.icon,
                          color: avatar.iconColor,
                          size: 26,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool readOnly;
  final Widget? suffix;

  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.readOnly = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      style: SettingsFlowTheme.body(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: SettingsFlowTheme.caption(),
        prefixIcon: Icon(icon, color: SettingsFlowPalette.textSecondary),
        suffixIcon: suffix,
        filled: true,
        fillColor: SettingsFlowPalette.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: SettingsFlowTheme.radius(20),
          borderSide: const BorderSide(color: SettingsFlowPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SettingsFlowTheme.radius(20),
          borderSide: const BorderSide(color: SettingsFlowPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SettingsFlowTheme.radius(20),
          borderSide: const BorderSide(color: SettingsFlowPalette.primary),
        ),
      ),
    );
  }
}
