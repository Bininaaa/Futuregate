import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/profile_avatar.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) {
        return;
      }
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.userModel;

      if (currentUser != null) {
        context.read<StudentProvider>().loadStudentProfile(currentUser.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.watch<StudentProvider>();
    final student = studentProvider.student;

    if (studentProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (student == null) {
      return const Scaffold(
        body: Center(
          child: Text('No student data found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              final studentProvider = context.read<StudentProvider>();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditProfileScreen(),
                ),
              );

              if (!mounted) return;
              final currentUser = authProvider.userModel;

              if (currentUser != null) {
                studentProvider.loadStudentProfile(currentUser.uid);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Center(child: ProfileAvatar(user: student, radius: 50)),
          const SizedBox(height: 12),
          Center(
            child: Text(
              student.fullName,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF004E98),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Email'),
            subtitle: Text(student.email),
          ),
          ListTile(
            title: const Text('Role'),
            subtitle: Text(student.role),
          ),
          ListTile(
            title: const Text('Academic Level'),
            subtitle: Text(student.academicLevel ?? ''),
          ),
          ListTile(
            title: const Text('Phone'),
            subtitle: Text(student.phone),
          ),
          ListTile(
            title: const Text('Location'),
            subtitle: Text(student.location),
          ),
          ListTile(
            title: const Text('University'),
            subtitle: Text(student.university ?? ''),
          ),
          ListTile(
            title: const Text('Field of Study'),
            subtitle: Text(student.fieldOfStudy ?? ''),
          ),
          ListTile(
            title: const Text('Bio'),
            subtitle: Text(student.bio ?? ''),
          ),
        ],
      ),
    );
  }
}
