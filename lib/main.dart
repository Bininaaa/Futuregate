import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'config/app_navigation.dart';
import 'firebase_options.dart';
import 'l10n/generated/app_localizations.dart';
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
import 'providers/opportunity_translation_provider.dart';
import 'providers/premium_provider.dart';
import 'providers/subscription_provider.dart';
import 'screens/launch_screen.dart';
import 'screens/notifications_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/locale_controller.dart';
import 'theme/theme_controller.dart';
import 'widgets/shared/app_restart_scope.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  NotificationService.logBackgroundMessage(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await NotificationService.initializeLocalNotifications();
  await NotificationService.setupInteractiveHandlers();

  NotificationService.onNotificationTap = _handleNotificationTap;

  final themeController = ThemeController();
  await themeController.load();

  final localeController = LocaleController();
  await localeController.load();

  runApp(
    AppRestartScope(
      child: FutureGateApp(
        themeController: themeController,
        localeController: localeController,
      ),
    ),
  );
}

void _handleNotificationTap(Map<String, dynamic> data) {
  final state = appNavigatorKey.currentState;
  if (state == null) {
    NotificationService.pendingNotificationData = data;
    return;
  }
  state.push(
    MaterialPageRoute(
      builder: (_) => NotificationsScreen(initialNotificationData: data),
    ),
  );
}

class FutureGateApp extends StatelessWidget {
  final ThemeController themeController;
  final LocaleController localeController;

  const FutureGateApp({
    super.key,
    required this.themeController,
    required this.localeController,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider.value(value: localeController),
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
        ChangeNotifierProvider(create: (_) => OpportunityTranslationProvider()),
        ChangeNotifierProvider(create: (_) => PremiumProvider()..startConfigStream()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
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
    if (state == AppLifecycleState.resumed) {
      context.read<AuthProvider>().loadCurrentUser();
      final uid = context.read<AuthProvider>().userModel?.uid ?? '';
      if (uid.isNotEmpty) {
        context.read<SubscriptionProvider>().refresh(uid);
      }
    }
    _syncPresence();
  }

  Future<void> _syncPresence() async {
    final auth = context.read<AuthProvider>().userModel;
    if (auth == null) return;

    final isOnline =
        _lastLifecycleState == null ||
        _lastLifecycleState == AppLifecycleState.resumed;
    try {
      await PresenceService.instance.updatePresence(
        userId: auth.uid,
        isOnline: isOnline,
      );
    } catch (_) {
      // Presence is best-effort.
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final localeController = context.watch<LocaleController>();

    final languageCode = localeController.locale?.languageCode;

    final uid = context.select<AuthProvider, String?>(
      (provider) => provider.userModel?.uid,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPresence();
      final subProvider = context.read<SubscriptionProvider>();
      subProvider.listenToSubscription(uid ?? '');
    });

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'FutureGate',

      // ── Localization ──────────────────────────────────────────────────────
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: localeController.locale,
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        // If the user has chosen a locale, use it.
        if (localeController.locale != null) return localeController.locale;
        // Otherwise try to match device locale.
        for (final supported in supportedLocales) {
          if (deviceLocale?.languageCode == supported.languageCode) {
            return supported;
          }
        }
        return const Locale('en');
      },

      // ── Theme (locale-aware for Arabic font) ──────────────────────────────
      theme: AppTheme.lightFor(languageCode),
      darkTheme: AppTheme.darkFor(languageCode),
      themeMode: themeController.themeMode,
      themeAnimationDuration: const Duration(milliseconds: 220),
      themeAnimationCurve: Curves.easeOutCubic,

      builder: (context, child) {
        final colors = AppColors.of(context);
        final isArabic = languageCode == 'ar';
        final overlayStyle = colors.isDarkMode
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark;

        Widget content = AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: colors.background,
            systemNavigationBarDividerColor: Colors.transparent,
          ),
          child: child ?? const SizedBox.shrink(),
        );

        // Wrap with explicit Directionality so RTL is enforced for Arabic
        // even in widgets that don't inherit it automatically.
        if (isArabic) {
          content = Directionality(
            textDirection: TextDirection.rtl,
            child: content,
          );
        }

        return content;
      },
      home: const LaunchScreen(),
    );
  }
}
