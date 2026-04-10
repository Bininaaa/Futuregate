import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';
import '../providers/application_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/company_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/cv_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/project_idea_provider.dart';
import '../providers/saved_opportunity_provider.dart';
import '../providers/saved_scholarship_provider.dart';
import '../providers/student_provider.dart';
import '../providers/training_provider.dart';
import '../services/notification_service.dart';
import '../widgets/no_internet_screen.dart';
import 'auth/login_screen.dart';
import 'auth/academic_level_selection_screen.dart';
import 'auth/email_verification_screen.dart';
import 'admin/home_screen.dart' as admin;
import 'company/company_approval_status_screen.dart';
import 'company/home_screen.dart' as company;
import 'notifications_screen.dart';
import 'student/home_screen.dart' as student;

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _notificationUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthProvider>().loadCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectivityProvider = context.watch<ConnectivityProvider>();
    final authProvider = context.watch<AuthProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    if (!connectivityProvider.isConnected) {
      return NoInternetScreen(onRetry: () => connectivityProvider.checkNow());
    }

    if (!authProvider.isInitialLoadDone && authProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = authProvider.userModel;

    // --- Blocked on fresh login: show blocked page even though user is null ---
    if (user == null && authProvider.isBlockedOnLogin) {
      return _BlockedScreen(
        onLogout: () {
          authProvider.clearBlockedFlag();
        },
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (user == null) {
        if (_notificationUserId != null) {
          _notificationUserId = null;
          notificationProvider.stopListening();
          _resetSignedOutSession();
        }
        return;
      }

      if (_notificationUserId == user.uid) return;

      _notificationUserId = user.uid;
      notificationProvider.startListening(user.uid);

      // If the app was opened via a push notification tap, navigate now.
      final pending = NotificationService.consumePendingNotification();
      if (pending != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      }
    });

    if (user == null) {
      return const LoginScreen();
    }

    // Mid-session block: listener already set _isBlockedOnLogin and cleared
    // _userModel, so this branch only triggers if the listener hasn't fired
    // yet (race condition safety net). Show blocked screen and sign out.
    if (!user.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        authProvider.logout();
      });
      return _BlockedScreen(
        onLogout: () {
          authProvider.clearBlockedFlag();
        },
      );
    }

    // Email verification gate: only for non-admin email/password users.
    // Admins are identified by their Firestore role and bypass this check
    // so they are never locked out by unverified Firebase Auth email status.
    if (user.isEmailProvider &&
        !user.isAdmin &&
        !authProvider.isEmailVerified) {
      return const EmailVerificationScreen();
    }

    if (user.isCompany && !user.isCompanyApproved) {
      return const CompanyApprovalStatusScreen();
    }

    if (user.needsAcademicLevel) {
      return const AcademicLevelSelectionScreen();
    }

    if (user.role == 'student') {
      return const student.HomeScreen();
    } else if (user.role == 'company') {
      return const company.HomeScreen();
    } else if (user.role == 'admin') {
      return const admin.HomeScreen();
    }

    return const LoginScreen();
  }

  void _resetSignedOutSession() {
    context.read<StudentProvider>().clearStudent();
    context.read<CvProvider>().clearCv();
    context.read<ApplicationProvider>().clearSession();
    context.read<SavedOpportunityProvider>().clearSavedOpportunities();
    context.read<SavedScholarshipProvider>().clearSavedScholarships();
    context.read<TrainingProvider>().clearSavedState();
    context.read<ProjectIdeaProvider>().clearUserSession();
    context.read<CompanyProvider>().clearSession();
    context.read<ChatProvider>().resetSession();
    context.read<AdminProvider>().resetSession();
  }
}

class _BlockedScreen extends StatelessWidget {
  final VoidCallback onLogout;

  const _BlockedScreen({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.block_rounded,
                  size: 56,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Account Blocked',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF004E98),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your account has been blocked by an administrator. '
                'You can no longer access the platform. '
                'If you believe this is a mistake, please contact support.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 180,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout, size: 20),
                  label: Text(
                    'Back to sign in',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
