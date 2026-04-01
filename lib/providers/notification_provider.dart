import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  Future<void>? _startListeningFuture;
  String? _activeUserId;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isFetchingToken => _isFetchingToken;
  String? get fcmToken => _fcmToken;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> startListening(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return;
    }

    if (_activeUserId == normalizedUserId && _startListeningFuture != null) {
      return _startListeningFuture;
    }

    if (_activeUserId == normalizedUserId && _sub != null) {
      return;
    }

    final request = _startListeningInternal(normalizedUserId);
    _startListeningFuture = request;

    try {
      await request;
    } finally {
      if (identical(_startListeningFuture, request)) {
        _startListeningFuture = null;
      }
    }
  }

  Future<void> _startListeningInternal(String userId) async {
    _activeUserId = userId;
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
    _startListeningFuture = null;
    _activeUserId = null;
    _notifications = [];
    _isLoading = false;
    _isFetchingToken = false;
    _fcmToken = null;
    _service.dispose();
    notifyListeners();
  }

  void listenToNotifications(String userId) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return;
    }

    if (_activeUserId == normalizedUserId && _sub != null) {
      return;
    }

    _activeUserId = normalizedUserId;
    _sub?.cancel();
    _isLoading = true;
    notifyListeners();

    _sub = _service
        .getNotifications(normalizedUserId)
        .listen(
          (data) {
            _notifications = data;
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            if (!_isIgnorableFirebaseCancellation(e)) {
              debugPrint('Notification stream error: $e');
              _isLoading = false;
              notifyListeners();
            }
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

  bool _isIgnorableFirebaseCancellation(Object error) {
    if (error is FirebaseException &&
        (error.code == 'aborted' || error.code == 'cancelled')) {
      return true;
    }
    final message = error.toString().toLowerCase();
    return message.contains('firebaseignoreexception') &&
        message.contains('http request was aborted');
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service.dispose();
    super.dispose();
  }
}
