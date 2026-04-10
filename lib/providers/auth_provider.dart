import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_navigation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _userModel;
  bool _isLoading = false;
  bool _isInitialLoadDone = false;
  bool _isBlockedOnLogin = false;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;
  Future<void>? _loadCurrentUserFuture;
  String? _listeningUserUid;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isInitialLoadDone => _isInitialLoadDone;
  bool get isBlockedOnLogin => _isBlockedOnLogin;

  bool get needsAcademicLevel => _userModel?.needsAcademicLevel ?? false;

  void clearBlockedFlag() {
    _isBlockedOnLogin = false;
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    final existingRequest = _loadCurrentUserFuture;
    if (existingRequest != null) {
      return existingRequest;
    }

    final request = _loadCurrentUserInternal();
    _loadCurrentUserFuture = request;

    try {
      await request;
    } finally {
      if (identical(_loadCurrentUserFuture, request)) {
        _loadCurrentUserFuture = null;
      }
    }
  }

  Future<void> _loadCurrentUserInternal() async {
    try {
      _isLoading = true;
      notifyListeners();

      _userModel = await _authService.getCurrentUserProfile();

      if (_userModel != null) {
        _startUserDocListener(_userModel!.uid);
      }
    } catch (e) {
      if (_isIgnorableFirebaseCancellation(e)) {
        _isLoading = false;
        _isInitialLoadDone = true;
        notifyListeners();
        return;
      }
      debugPrint('loadCurrentUser error: $e');
    } finally {
      _isLoading = false;
      _isInitialLoadDone = true;
      notifyListeners();
    }
  }

  void _startUserDocListener(String uid) {
    if (_listeningUserUid == uid && _userDocSubscription != null) {
      return;
    }

    _userDocSubscription?.cancel();
    _listeningUserUid = uid;
    _userDocSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
          (snapshot) {
            if (!snapshot.exists) return;
            final data = snapshot.data();
            if (data == null) return;

            final updatedUser = UserModel.fromMap(data);

            if (!updatedUser.isActive) {
              _stopUserDocListener();
              _isBlockedOnLogin = true;
              _userModel = null;
              _authService.logout();
              notifyListeners();
              return;
            }

            _userModel = updatedUser;
            notifyListeners();
          },
          onError: (error, stackTrace) {
            if (_isIgnorableFirebaseCancellation(error)) {
              return;
            }

            debugPrint('User profile listener error: $error');
          },
        );
  }

  void _stopUserDocListener() {
    _userDocSubscription?.cancel();
    _userDocSubscription = null;
    _listeningUserUid = null;
  }

  bool _isIgnorableFirebaseCancellation(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('firebaseignoreexception') &&
        message.contains('http request was aborted');
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _isBlockedOnLogin = false;
      notifyListeners();

      await _authService.login(email: email, password: password);

      _userModel = await _authService.getCurrentUserProfile();

      if (_userModel != null && !_userModel!.isActive) {
        await _authService.logout();
        _userModel = null;
        _isBlockedOnLogin = true;
        return null;
      }

      if (_userModel != null) {
        _startUserDocListener(_userModel!.uid);
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e.code);
    } catch (e) {
      return 'An unexpected error occurred. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static String _mapAuthError(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'wrong-password';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Login failed. Please try again.';
    }
  }

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
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.register(
        fullName: fullName,
        email: email,
        password: password,
        selectedRole: selectedRole,
        researchTopic: researchTopic,
        laboratory: laboratory,
        supervisor: supervisor,
        researchDomain: researchDomain,
      );

      // Send email verification for email/password signups
      await _authService.sendEmailVerification();

      _userModel = await _authService.getCurrentUserProfile();

      if (_userModel != null) {
        _startUserDocListener(_userModel!.uid);
      }

      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> registerCompany({
    required String companyName,
    required String email,
    required String password,
    required String commercialRegisterFileName,
    String commercialRegisterFilePath = '',
    Uint8List? commercialRegisterBytes,
    String phone = '',
    String website = '',
    String sector = '',
    String description = '',
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.registerCompany(
        companyName: companyName,
        email: email,
        password: password,
        commercialRegisterFileName: commercialRegisterFileName,
        commercialRegisterFilePath: commercialRegisterFilePath,
        commercialRegisterBytes: commercialRegisterBytes,
        phone: phone,
        website: website,
        sector: sector,
        description: description,
      );

      // Send email verification for email/password signups
      await _authService.sendEmailVerification();

      _userModel = await _authService.getCurrentUserProfile();

      if (_userModel != null) {
        _startUserDocListener(_userModel!.uid);
      }

      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      _isLoading = true;
      _isBlockedOnLogin = false;
      notifyListeners();

      await _authService.signInWithGoogle();

      _userModel = await _authService.getCurrentUserProfile();

      if (_userModel != null && !_userModel!.isActive) {
        await _authService.logout();
        _userModel = null;
        _isBlockedOnLogin = true;
        return null;
      }

      if (_userModel != null) {
        _startUserDocListener(_userModel!.uid);
      }

      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> updateAcademicLevel(String academicLevel) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_userModel == null) return 'User not found';

      await _authService.updateAcademicLevel(_userModel!.uid, academicLevel);
      _userModel = await _authService.getCurrentUserProfile();

      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --------------- Email Verification ---------------

  bool get isEmailProvider => _authService.getSignInProvider() == 'email';

  bool get isEmailVerified => _authService.isEmailVerified;

  Future<String?> sendEmailVerification() async {
    try {
      await _authService.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Failed to send verification email.';
    } catch (e) {
      return 'Failed to send verification email.';
    }
  }

  Future<bool> reloadAndCheckVerification() async {
    return await _authService.reloadAndCheckVerification();
  }

  // --------------- Password Reset ---------------

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No account found with this email.';
      }
      if (e.code == 'invalid-email') {
        return 'The email address is not valid.';
      }
      if (e.code == 'too-many-requests') {
        return 'Too many attempts. Please try again later.';
      }
      return e.message ?? 'Failed to send reset email.';
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  // --------------- Change Password ---------------

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Current password is incorrect.';
      }
      if (e.code == 'weak-password') {
        return 'New password is too weak.';
      }
      if (e.code == 'too-many-requests') {
        return 'Too many attempts. Please try again later.';
      }
      return e.message ?? 'Failed to change password.';
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  // --------------- Change Email ---------------

  Future<String?> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    try {
      await _authService.changeEmail(
        currentPassword: currentPassword,
        newEmail: newEmail,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Current password is incorrect.';
      }
      if (e.code == 'email-already-in-use') {
        return 'This email is already in use by another account.';
      }
      if (e.code == 'invalid-email') {
        return 'The new email address is not valid.';
      }
      if (e.code == 'too-many-requests') {
        return 'Too many attempts. Please try again later.';
      }
      return e.message ?? 'Failed to change email.';
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  // --------------- Provider Detection ---------------

  String get signInProvider => _authService.getSignInProvider();

  Future<void> logout() async {
    _stopUserDocListener();
    _isBlockedOnLogin = false;
    await _authService.logout();
    _userModel = null;
    notifyListeners();
    appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _stopUserDocListener();
    super.dispose();
  }
}
