import 'dart:typed_data';

import 'package:avenirdz/models/notification_model.dart';
import 'package:avenirdz/models/user_model.dart';
import 'package:avenirdz/providers/auth_provider.dart';
import 'package:avenirdz/providers/connectivity_provider.dart';
import 'package:avenirdz/providers/notification_provider.dart';
import 'package:avenirdz/screens/auth/role_chooser_screen.dart';
import 'package:avenirdz/screens/onboarding/get_started_screen.dart';
import 'package:avenirdz/screens/post_launch_gate_screen.dart';
import 'package:avenirdz/services/app_intro_preferences_service.dart';
import 'package:avenirdz/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class FakeAppIntroPreferencesService extends AppIntroPreferencesService {
  FakeAppIntroPreferencesService({this.hasSeen = false});

  bool hasSeen;
  int markSeenCalls = 0;

  @override
  Future<bool> hasSeenGetStarted() async => hasSeen;

  @override
  Future<void> markGetStartedSeen() async {
    hasSeen = true;
    markSeenCalls += 1;
  }

  @override
  Future<void> clearGetStartedSeen() async {
    hasSeen = false;
  }
}

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
  List<NotificationModel> get notifications => const <NotificationModel>[];

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

Widget buildTestApp({
  required AuthProvider authProvider,
  Widget? home,
}) {
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
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

UserModel buildSignedInStudent() {
  return UserModel(
    uid: 'student-1',
    fullName: 'Future Gate Student',
    email: 'student@example.com',
    role: 'student',
    phone: '',
    location: '',
    profileImage: '',
    isActive: true,
    academicLevel: 'master',
  );
}

Future<void> configurePhoneViewport(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(430, 932));
}

void main() {
  testWidgets('PostLaunchGateScreen shows onboarding when intro is unseen', (
    WidgetTester tester,
  ) async {
    await configurePhoneViewport(tester);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final introService = FakeAppIntroPreferencesService(hasSeen: false);

    await tester.pumpWidget(
      buildTestApp(
        authProvider: FakeAuthProvider(),
        home: PostLaunchGateScreen(introPreferencesService: introService),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('onboarding_title_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('onboarding_primary_button')),
      findsOneWidget,
    );
  });

  testWidgets('PostLaunchGateScreen goes to auth flow when intro is seen', (
    WidgetTester tester,
  ) async {
    await configurePhoneViewport(tester);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final introService = FakeAppIntroPreferencesService(hasSeen: true);
    final authProvider = FakeAuthProvider();

    await tester.pumpWidget(
      buildTestApp(
        authProvider: authProvider,
        home: PostLaunchGateScreen(introPreferencesService: introService),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Welcome to FutureGate'), findsOneWidget);
    expect(authProvider.loadCurrentUserCalled, isTrue);
  });

  testWidgets('GetStartedScreen advances to slide three and shows auth CTAs', (
    WidgetTester tester,
  ) async {
    await configurePhoneViewport(tester);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final introService = FakeAppIntroPreferencesService(hasSeen: false);

    await tester.pumpWidget(
      buildTestApp(
        authProvider: FakeAuthProvider(),
        home: GetStartedScreen(introPreferencesService: introService),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('onboarding_title_0')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('onboarding_primary_button')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('onboarding_primary_button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('onboarding_title_1')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('onboarding_forward_button')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('onboarding_forward_button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('onboarding_title_2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('onboarding_final_primary_button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('onboarding_login_link')),
      findsOneWidget,
    );
    expect(introService.markSeenCalls, greaterThan(0));
  });

  testWidgets('Skip marks intro as seen and returns to login flow', (
    WidgetTester tester,
  ) async {
    await configurePhoneViewport(tester);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final introService = FakeAppIntroPreferencesService(hasSeen: false);

    await tester.pumpWidget(
      buildTestApp(
        authProvider: FakeAuthProvider(),
        home: GetStartedScreen(introPreferencesService: introService),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('onboarding_skip_button')));
    await tester.pumpAndSettle();

    expect(introService.hasSeen, isTrue);
    expect(find.text('Welcome to FutureGate'), findsOneWidget);
  });

  testWidgets('Create account CTA opens role chooser after onboarding', (
    WidgetTester tester,
  ) async {
    await configurePhoneViewport(tester);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final introService = FakeAppIntroPreferencesService(hasSeen: false);

    await tester.pumpWidget(
      buildTestApp(
        authProvider: FakeAuthProvider(),
        home: GetStartedScreen(introPreferencesService: introService),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('onboarding_primary_button')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('onboarding_primary_button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('onboarding_forward_button')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('onboarding_forward_button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('onboarding_final_primary_button')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding_final_primary_button')),
    );
    await tester.pumpAndSettle();

    expect(introService.hasSeen, isTrue);
    expect(find.text('Join FutureGate'), findsOneWidget);
  });

  testWidgets('Signed-in users see continue to app on the final slide', (
    WidgetTester tester,
  ) async {
    await configurePhoneViewport(tester);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final introService = FakeAppIntroPreferencesService(hasSeen: false);

    await tester.pumpWidget(
      buildTestApp(
        authProvider: FakeAuthProvider(currentUser: buildSignedInStudent()),
        home: GetStartedScreen(introPreferencesService: introService),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('onboarding_primary_button')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('onboarding_primary_button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('onboarding_forward_button')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('onboarding_forward_button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('onboarding_forward_button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('onboarding_login_link')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('onboarding_final_primary_button')),
      findsOneWidget,
    );
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('Role chooser falls back to login when opened without back stack', (
    WidgetTester tester,
  ) async {
    await configurePhoneViewport(tester);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildTestApp(
        authProvider: FakeAuthProvider(),
        home: const RoleChooserScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Back to Login'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to FutureGate'), findsOneWidget);
  });
}
