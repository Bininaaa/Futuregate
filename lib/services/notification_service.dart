import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import 'worker_api_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final WorkerApiService _workerApi = WorkerApiService();
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _foregroundHandlerRegistered = false;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Set from main.dart — called when the user taps a push notification.
  static void Function(Map<String, dynamic> data)? onNotificationTap;

  /// Stores notification data when tap occurs before the app is ready.
  static Map<String, dynamic>? pendingNotificationData;

  static const String _channelId = 'avenirdz_notifications';
  static const String _channelName = 'FutureGate Notifications';
  static const String _channelDesc = 'Notifications from FutureGate';

  static const String _webVapidKey = String.fromEnvironment(
    'FCM_WEB_VAPID_KEY',
  );

  // ── Local notification setup ───────────────────────────────────────

  static Future<void> initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create notification channel on Android.
    if (!kIsWeb) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.high,
        ),
      );
    }

    // iOS: show notifications while app is in foreground.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      if (onNotificationTap != null) {
        onNotificationTap!(data);
      } else {
        pendingNotificationData = data;
      }
    } catch (_) {}
  }

  /// Set up tap handlers for background / terminated-state messages.
  static Future<void> setupInteractiveHandlers() async {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (onNotificationTap != null) {
        onNotificationTap!(message.data);
      } else {
        pendingNotificationData = message.data;
      }
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      pendingNotificationData = initialMessage.data;
    }
  }

  /// Consume and clear any stored notification data (called after login).
  static Map<String, dynamic>? consumePendingNotification() {
    final data = pendingNotificationData;
    pendingNotificationData = null;
    return data;
  }

  // ── Foreground message display ─────────────────────────────────────

  void setupForegroundHandler() {
    if (_foregroundHandlerRegistered) return;
    _foregroundHandlerRegistered = true;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        'FCM foreground message: ${message.notification?.title ?? message.messageId}',
      );
      _showLocalNotification(message);
    });
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  // ── FCM token management ───────────────────────────────────────────

  Future<String?> initializeFCM(String userId) async {
    try {
      final token = await getCurrentToken();

      if (token != null && token.isNotEmpty) {
        await _saveToken(userId, token);
      }

      _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM token refreshed');
        _saveToken(userId, newToken);
      });

      return token;
    } catch (e) {
      debugPrint('FCM initialization failed: $e');
      return null;
    }
  }

  Future<String?> getCurrentToken() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        debugPrint(
          'FCM permission not granted: ${settings.authorizationStatus}',
        );
        return null;
      }

      if (kIsWeb && _webVapidKey.isEmpty) {
        debugPrint(
          'FCM token unavailable on web: missing --dart-define=FCM_WEB_VAPID_KEY',
        );
        return null;
      }

      return kIsWeb
          ? await _messaging.getToken(vapidKey: _webVapidKey)
          : await _messaging.getToken();
    } catch (e) {
      debugPrint('FCM token fetch failed: $e');
      return null;
    }
  }

  Future<void> _saveToken(String userId, String token) async {
    final platform = kIsWeb
        ? 'web'
        : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');

    try {
      await _workerApi.post(
        '/api/notifications/register-token',
        body: {'token': token, 'platform': platform},
      );
      return;
    } catch (error) {
      debugPrint(
        'Worker token registration failed, falling back to Firestore: $error',
      );
    }

    await _firestore.collection('users').doc(userId).set({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      'fcmTokenPlatform': platform,
    }, SetOptions(merge: true));
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
  }

  // ── Background message handler ─────────────────────────────────────

  static void logBackgroundMessage(RemoteMessage message) {
    debugPrint(
      'FCM background message: ${message.notification?.title ?? message.messageId}',
    );
  }

  // ── Notification CRUD ──────────────────────────────────────────────

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String conversationId = '',
    String targetId = '',
  }) async {
    final docRef = _firestore.collection('notifications').doc();
    final notification = NotificationModel(
      id: docRef.id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      createdAt: Timestamp.now(),
      isRead: false,
      conversationId: conversationId,
      targetId: targetId,
    );
    await docRef.set(notification.toMap());
  }

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } on FirebaseException catch (error) {
      if (error.code == 'not-found') {
        return;
      }
      rethrow;
    }
  }

  Future<void> markAllAsRead(String userId) async {
    final unread = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    if (unread.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
