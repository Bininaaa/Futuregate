import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/opportunity_provider.dart';
import 'providers/application_provider.dart';
import 'providers/student_provider.dart';
import 'providers/training_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/scholarship_provider.dart';
import 'providers/project_idea_provider.dart';
import 'providers/saved_opportunity_provider.dart';
import 'providers/cv_provider.dart';
import 'providers/company_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/connectivity_provider.dart';
import 'screens/auth_wrapper.dart';
import 'screens/notifications_screen.dart';

/// Global navigator key — used for push notification tap navigation.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

  runApp(const AvenirDZApp());
}

void _handleNotificationTap(Map<String, dynamic> data) {
  final state = navigatorKey.currentState;
  if (state == null) {
    // App not ready yet — store for later consumption in auth_wrapper.
    NotificationService.pendingNotificationData = data;
    return;
  }
  state.push(
    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
  );
}

class AvenirDZApp extends StatelessWidget {
  const AvenirDZApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OpportunityProvider()),
        ChangeNotifierProvider(create: (_) => ApplicationProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => TrainingProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => ScholarshipProvider()),
        ChangeNotifierProvider(create: (_) => ProjectIdeaProvider()),
        ChangeNotifierProvider(create: (_) => SavedOpportunityProvider()),
        ChangeNotifierProvider(create: (_) => CvProvider()),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'AvenirDZ',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF8C00)),
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}
