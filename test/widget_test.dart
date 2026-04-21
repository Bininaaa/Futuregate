import 'dart:typed_data';

import 'package:avenirdz/models/notification_model.dart';
import 'package:avenirdz/models/user_model.dart';
import 'package:avenirdz/providers/auth_provider.dart';
import 'package:avenirdz/providers/connectivity_provider.dart';
import 'package:avenirdz/providers/notification_provider.dart';
import 'package:avenirdz/screens/auth_wrapper.dart';
import 'package:avenirdz/l10n/generated/app_localizations.dart';
import 'package:avenirdz/widgets/shared/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  FakeAuthProvider({
    this.loading = false,
    this.currentUser,
    bool blockedOnLogin = false,
    this.initialLoadDone = true,
    this.passwordProviderLinked = false,
    this.googleProviderLinked = false,
  }) : _blockedOnLogin = blockedOnLogin;

  final bool loading;
  final bool initialLoadDone;
  final UserModel? currentUser;
  final bool passwordProviderLinked;
  final bool googleProviderLinked;
  bool loadCurrentUserCalled = false;
  bool _blockedOnLogin;

  @override
  bool get isLoading => loading;

  @override
  bool get isInitialLoadDone => initialLoadDone;

  @override
  UserModel? get userModel => currentUser;

  @override
  bool get isBlockedOnLogin => _blockedOnLogin;

  @override
  void clearBlockedFlag() {
    _blockedOnLogin = false;
  }

  @override
  Future<void> loadCurrentUser() async {
    loadCurrentUserCalled = true;
  }

  @override
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    return null;
  }

  @override
  Future<String?> register({
    required String fullName,
    required String email,
    required String password,
    required String selectedRole,
    String researchTopic = '',
    String laboratory = '',
    String supervisor = '',
    String researchDomain = '',
  }) async {
    return null;
  }

  @override
  Future<String?> registerCompany({
    required String companyName,
    required String email,
    required String password,
    String phone = '',
    String website = '',
    String sector = '',
    String description = '',
    required String commercialRegisterFileName,
    String commercialRegisterFilePath = '',
    Uint8List? commercialRegisterBytes,
  }) async {
    return null;
  }

  @override
  Future<String?> signInWithGoogle() async {
    return null;
  }

  @override
  Future<String?> updatePreferredPostingLanguage(String languageCode) async {
    return null;
  }

  @override
  Future<void> logout() async {}

  @override
  bool get needsAcademicLevel => false;

  @override
  bool get needsStudentOnboarding => false;

  @override
  Future<String?> updateAcademicLevel(String level) async {
    return null;
  }

  @override
  Future<String?> completeStudentOnboarding({
    required String fullName,
    required String phone,
    required String location,
    required String university,
    required String fieldOfStudy,
    required String bio,
    String researchTopic = '',
    String laboratory = '',
    String supervisor = '',
    String researchDomain = '',
  }) async {
    return null;
  }

  @override
  bool get hasPasswordProvider => passwordProviderLinked;

  @override
  bool get hasGoogleProvider => googleProviderLinked;

  @override
  bool get hasMultipleSignInMethods =>
      passwordProviderLinked && googleProviderLinked;

  @override
  bool get canAddPassword => googleProviderLinked && !passwordProviderLinked;

  @override
  bool get isEmailProvider => passwordProviderLinked && !googleProviderLinked;

  @override
  bool get canChangePassword => passwordProviderLinked;

  @override
  bool get canChangeEmail => passwordProviderLinked && !googleProviderLinked;

  @override
  bool get requiresEmailVerification =>
      passwordProviderLinked && !googleProviderLinked;

  @override
  String get linkedProviderLabel {
    if (passwordProviderLinked && googleProviderLinked) {
      return 'Google + Email & Password';
    }
    if (passwordProviderLinked) {
      return 'Email & Password';
    }
    if (googleProviderLinked) {
      return 'Google';
    }
    return 'Unknown';
  }

  @override
  bool get isEmailVerified => true;

  @override
  Future<String?> sendEmailVerification() async => null;

  @override
  Future<bool> reloadAndCheckVerification() async => true;

  @override
  Future<String?> sendPasswordResetEmail(String email) async => null;

  @override
  Future<String?> addPassword({required String newPassword}) async => null;

  @override
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => null;

  @override
  Future<String?> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async => null;

  @override
  String get signInProvider {
    if (passwordProviderLinked && googleProviderLinked) {
      return 'multiple';
    }
    if (passwordProviderLinked) {
      return 'email';
    }
    if (googleProviderLinked) {
      return 'google';
    }
    return 'unknown';
  }
}

class FakeConnectivityProvider extends ChangeNotifier
    implements ConnectivityProvider {
  FakeConnectivityProvider({this.connected = true});

  final bool connected;
  bool checkNowCalled = false;

  @override
  bool get isConnected => connected;

  @override
  Future<void> checkNow() async {
    checkNowCalled = true;
  }
}

class FakeNotificationProvider extends ChangeNotifier
    implements NotificationProvider {
  bool startListeningCalled = false;
  bool stopListeningCalled = false;
  String? listenedUserId;

  @override
  List<NotificationModel> get notifications => const [];

  @override
  bool get isLoading => false;

  @override
  bool get isFetchingToken => false;

  @override
  String? get fcmToken => null;

  @override
  int get unreadCount => 0;

  @override
  Future<void> startListening(String userId) async {
    startListeningCalled = true;
    listenedUserId = userId;
  }

  @override
  Future<String?> fetchFcmToken(String userId) async {
    return null;
  }

  @override
  void stopListening() {
    stopListeningCalled = true;
  }

  @override
  void listenToNotifications(String userId) {}

  @override
  Future<void> markAsRead(String notificationId) async {}

  @override
  Future<void> markAllAsRead(String userId) async {}

  @override
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String conversationId = '',
    String targetId = '',
  }) async {}
}

void main() {
  Widget buildTestApp(FakeAuthProvider authProvider) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: FakeNotificationProvider(),
        ),
        ChangeNotifierProvider<ConnectivityProvider>.value(
          value: FakeConnectivityProvider(),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AuthWrapper(),
      ),
    );
  }

  testWidgets('AuthWrapper shows a loading indicator while auth is loading', (
    WidgetTester tester,
  ) async {
    final authProvider = FakeAuthProvider(
      loading: true,
      initialLoadDone: false,
    );

    await tester.pumpWidget(buildTestApp(authProvider));
    await tester.pump();

    expect(find.byType(AppLoadingView), findsOneWidget);
    expect(authProvider.loadCurrentUserCalled, isTrue);
  });

  testWidgets('AuthWrapper shows the login screen when there is no user', (
    WidgetTester tester,
  ) async {
    final authProvider = FakeAuthProvider();

    await tester.pumpWidget(buildTestApp(authProvider));
    await tester.pump();

    expect(find.text('Welcome to FutureGate'), findsOneWidget);
    expect(find.text('Login'), findsAtLeastNWidgets(1));
    expect(authProvider.loadCurrentUserCalled, isTrue);
  });
}
