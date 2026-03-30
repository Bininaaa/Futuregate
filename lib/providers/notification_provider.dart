import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _isFetchingToken = false;
  String? _fcmToken;
  StreamSubscription? _sub;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isFetchingToken => _isFetchingToken;
  String? get fcmToken => _fcmToken;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> startListening(String userId) async {
    listenToNotifications(userId);
    _fcmToken = await _service.initializeFCM(userId);
    _service.setupForegroundHandler();
    notifyListeners();
  }

  Future<String?> fetchFcmToken(String userId) async {
    _isFetchingToken = true;
    notifyListeners();

    try {
      _fcmToken = await _service.initializeFCM(userId);
      return _fcmToken;
    } finally {
      _isFetchingToken = false;
      notifyListeners();
    }
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
    _notifications = [];
    _isLoading = false;
    _isFetchingToken = false;
    _fcmToken = null;
    _service.dispose();
    notifyListeners();
  }

  void listenToNotifications(String userId) {
    _sub?.cancel();
    _isLoading = true;
    notifyListeners();

    _sub = _service
        .getNotifications(userId)
        .listen(
          (data) {
            _notifications = data;
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Notification stream error: $e');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> markAsRead(String notificationId) async {
    await _service.markAsRead(notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _service.markAllAsRead(userId);
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String conversationId = '',
    String targetId = '',
  }) async {
    await _service.createNotification(
      userId: userId,
      title: title,
      message: message,
      type: type,
      conversationId: conversationId,
      targetId: targetId,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service.dispose();
    super.dispose();
  }
}
