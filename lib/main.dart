import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'config/app_navigation.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/presence_service.dart';
import 'providers/auth_provider.dart';
import 'providers/opportunity_provider.dart';
import 'providers/application_provider.dart';
import 'providers/student_provider.dart';
import 'providers/training_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/scholarship_provider.dart';
import 'providers/project_idea_provider.dart';
import 'providers/saved_opportunity_provider.dart';
import 'providers/saved_scholarship_provider.dart';
import 'providers/cv_provider.dart';
import 'providers/company_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/connectivity_provider.dart';
import 'screens/launch_screen.dart';
import 'screens/notifications_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  NotificationService.logBackgroundMessage(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await NotificationService.initializeLocalNotifications();
  await NotificationService.setupInteractiveHandlers();

  // Handle notification taps — navigate to the notifications screen so the
  // user can see the full notification and tap through to the target.
  NotificationService.onNotificationTap = _handleNotificationTap;

  final themeController = ThemeController();
  await themeController.load();

  runApp(FutureGateApp(themeController: themeController));
}

void _handleNotificationTap(Map<String, dynamic> data) {
  final state = appNavigatorKey.currentState;
  if (state == null) {
    // App not ready yet — store for later consumption in auth_wrapper.
    NotificationService.pendingNotificationData = data;
    return;
  }
  state.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
}

class FutureGateApp extends StatelessWidget {
  final ThemeController themeController;

  const FutureGateApp({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OpportunityProvider()),
        ChangeNotifierProvider(create: (_) => ApplicationProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => TrainingProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => ScholarshipProvider()),
        ChangeNotifierProvider(create: (_) => ProjectIdeaProvider()),
        ChangeNotifierProvider(create: (_) => SavedOpportunityProvider()),
        ChangeNotifierProvider(create: (_) => SavedScholarshipProvider()),
        ChangeNotifierProvider(create: (_) => CvProvider()),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: const _PresenceAwareApp(),
    );
  }
}

class _PresenceAwareApp extends StatefulWidget {
  const _PresenceAwareApp();

  @override
  State<_PresenceAwareApp> createState() => _PresenceAwareAppState();
}

class _PresenceAwareAppState extends State<_PresenceAwareApp>
    with WidgetsBindingObserver {
  AppLifecycleState? _lastLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPresence());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lastLifecycleState = state;
    _syncPresence();
  }

  Future<void> _syncPresence() async {
    final auth = context.read<AuthProvider>().userModel;
    if (auth == null) {
      return;
    }

    final isOnline =
        _lastLifecycleState == null ||
        _lastLifecycleState == AppLifecycleState.resumed;
    try {
      await PresenceService.instance.updatePresence(
        userId: auth.uid,
        isOnline: isOnline,
      );
    } catch (_) {
      // Presence is best-effort and should never block the app shell.
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    context.select<AuthProvider, String?>(
      (provider) => provider.userModel?.uid,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPresence());

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'FutureGate',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeController.themeMode,
      themeAnimationDuration: const Duration(milliseconds: 220),
      themeAnimationCurve: Curves.easeOutCubic,
      builder: (context, child) {
        final colors = AppColors.of(context);
        final overlayStyle = colors.isDarkMode
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: colors.background,
            systemNavigationBarDividerColor: Colors.transparent,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const LaunchScreen(),
    );
  }
}
