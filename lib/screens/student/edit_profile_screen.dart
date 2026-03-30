import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/avatar_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/profile_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const Color vibrantOrange = Color(0xFFFF6700);
  static const Color strongBlue = Color(0xFF004E98);
  static const Color mediumBlue = Color(0xFF3A6EA5);
  static const Color softGray = Color(0xFFEBEBEB);

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController universityController = TextEditingController();
  final TextEditingController fieldOfStudyController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  bool _initialized = false;
  bool _uploadingPhoto = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      final student = context.read<StudentProvider>().student;

      if (student != null) {
        phoneController.text = student.phone;
        locationController.text = student.location;
        universityController.text = student.university ?? '';
        fieldOfStudyController.text = student.fieldOfStudy ?? '';
        bioController.text = student.bio ?? '';
      }

      _initialized = true;
    }
  }

  Future<void> _saveProfile() async {
    final authProvider = context.read<AuthProvider>();
    final studentProvider = context.read<StudentProvider>();

    final currentUser = authProvider.userModel;
    if (currentUser == null) return;

    final error = await studentProvider.updateStudentProfile(
      uid: currentUser.uid,
      phone: phoneController.text.trim(),
      location: locationController.text.trim(),
      university: universityController.text.trim(),
      fieldOfStudy: fieldOfStudyController.text.trim(),
      bio: bioController.text.trim(),
    );

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _selectAvatar(String avatarId) async {
    final authProvider = context.read<AuthProvider>();
    final studentProvider = context.read<StudentProvider>();
    final currentUser = authProvider.userModel;
    if (currentUser == null || studentProvider.isLoading || _uploadingPhoto) {
      return;
    }

    final error = await studentProvider.selectAvatar(
      uid: currentUser.uid,
      avatarId: avatarId,
    );

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    await context.read<AuthProvider>().loadCurrentUser();
  }

  Future<void> _useUploadedPhoto() async {
    final authProvider = context.read<AuthProvider>();
    final studentProvider = context.read<StudentProvider>();
    final currentUser = authProvider.userModel;
    if (currentUser == null || studentProvider.isLoading || _uploadingPhoto) {
      return;
    }

    final error = await studentProvider.useUploadedProfilePhoto(
      currentUser.uid,
    );

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    await context.read<AuthProvider>().loadCurrentUser();
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_uploadingPhoto || context.read<StudentProvider>().isLoading) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;

    if (file.size > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image must be smaller than 5 MB')),
      );
      return;
    }

    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final studentProvider = context.read<StudentProvider>();
    final currentUser = authProvider.userModel;
    if (currentUser == null) return;

    setState(() => _uploadingPhoto = true);

    final error = await studentProvider.uploadProfilePhoto(
      uid: currentUser.uid,
      fileName: file.name,
      filePath: file.path ?? '',
      fileBytes: file.bytes,
    );

    if (!mounted) return;
    setState(() => _uploadingPhoto = false);

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    await context.read<AuthProvider>().loadCurrentUser();
  }

  Future<void> _removePhoto() async {
    final authProvider = context.read<AuthProvider>();
    final studentProvider = context.read<StudentProvider>();
    final currentUser = authProvider.userModel;
    if (currentUser == null) return;

    final error = await studentProvider.removeProfilePhoto(currentUser.uid);

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    await context.read<AuthProvider>().loadCurrentUser();
  }

  @override
  void dispose() {
    phoneController.dispose();
    locationController.dispose();
    universityController.dispose();
    fieldOfStudyController.dispose();
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.watch<StudentProvider>();
    final student = studentProvider.student;

    return Scaffold(
      backgroundColor: softGray,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: strongBlue,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: strongBlue),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Current profile picture preview
          _buildPhotoPreview(student),
          const SizedBox(height: 24),

          // Avatar picker section
          _buildAvatarPicker(student),
          const SizedBox(height: 20),

          // Upload section
          _buildUploadSection(student),
          const SizedBox(height: 24),

          // Text fields
          _buildField('Phone', phoneController),
          const SizedBox(height: 14),
          _buildField('Location', locationController),
          const SizedBox(height: 14),
          _buildField('University', universityController),
          const SizedBox(height: 14),
          _buildField('Field of Study', fieldOfStudyController),
          const SizedBox(height: 14),
          _buildField('Bio', bioController, maxLines: 4),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: studentProvider.isLoading || _uploadingPhoto
                  ? null
                  : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: vibrantOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: studentProvider.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Save Changes',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview(dynamic student) {
    final hasPhoto =
        student != null &&
        (student.photoType == 'upload' ||
            student.photoType == 'avatar' ||
            (student.profileImage as String).isNotEmpty);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (_uploadingPhoto)
              const SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            else
              ProfileAvatar(user: student, radius: 50),
          ],
        ),
        if (hasPhoto) ...[
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: studentProvider.isLoading ? null : _removePhoto,
            icon: const Icon(Icons.close, size: 16),
            label: Text(
              'Remove current photo',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ],
    );
  }

  StudentProvider get studentProvider => context.read<StudentProvider>();

  Widget _buildAvatarPicker(dynamic student) {
    final selectedAvatarId = student?.photoType == 'avatar'
        ? student?.avatarId
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose an Avatar',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: strongBlue,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: AvatarConfig.avatars.length,
            itemBuilder: (context, index) {
              final avatar = AvatarConfig.avatars[index];
              final isSelected = selectedAvatarId == avatar.id;

              return GestureDetector(
                onTap: studentProvider.isLoading || _uploadingPhoto
                    ? null
                    : () => _selectAvatar(avatar.id),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: vibrantOrange, width: 3)
                        : null,
                  ),
                  child: CircleAvatar(
                    backgroundColor: avatar.backgroundColor,
                    child: Icon(avatar.icon, color: avatar.iconColor, size: 28),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection(dynamic student) {
    final hasUploadedPhoto =
        student != null && (student.profileImage as String).isNotEmpty;
    final isUploadActive = student?.photoType == 'upload';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Or Upload Your Own Picture',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: strongBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'JPG, PNG or WebP. Max 5 MB.',
            style: GoogleFonts.poppins(fontSize: 12, color: mediumBlue),
          ),
          if (hasUploadedPhoto) ...[
            const SizedBox(height: 8),
            Text(
              isUploadActive
                  ? 'Your uploaded photo is currently active.'
                  : 'Your uploaded photo is saved. You can switch back without re-uploading.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isUploadActive ? vibrantOrange : mediumBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _uploadingPhoto ? null : _pickAndUploadPhoto,
              icon: _uploadingPhoto
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_outlined),
              label: Text(
                _uploadingPhoto
                    ? 'Uploading...'
                    : hasUploadedPhoto
                    ? 'Replace Uploaded Image'
                    : 'Choose Image',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: strongBlue,
                side: BorderSide(color: strongBlue.withValues(alpha: 0.2)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (hasUploadedPhoto && !isUploadActive) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: studentProvider.isLoading || _uploadingPhoto
                    ? null
                    : _useUploadedPhoto,
                icon: const Icon(Icons.refresh_outlined, size: 18),
                label: Text(
                  'Use Uploaded Photo',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(foregroundColor: vibrantOrange),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: strongBlue,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: vibrantOrange),
            ),
          ),
        ),
      ],
    );
  }
}
