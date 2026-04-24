import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_navigation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/crashlytics_logger.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _userModel;
  bool _isLoading = false;
  bool _isInitialLoadDone = false;
  bool _isBlockedOnLogin = false;
  bool _hasReceivedAuthState = false;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;
  StreamSubscription<User?>? _authStateSubscription;
  Future<void>? _loadCurrentUserFuture;
  String? _loadCurrentUserUid;
  String? _listeningUserUid;
  String? _lastFirebaseUserSignature;

  AuthProvider() {
    _authStateSubscription = _authService.authStateChanges.listen(
      _handleFirebaseAuthStateChanged,
      onError: (error, stackTrace) {
        if (_isIgnorableFirebaseCancellation(error)) {
          return;
        }

        recordNonFatal(error, stackTrace, context: 'auth_state_listener');
      },
    );
  }

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isInitialLoadDone => _isInitialLoadDone;
  bool get isBlockedOnLogin => _isBlockedOnLogin;

  bool get needsAcademicLevel => _userModel?.needsAcademicLevel ?? false;
  bool get needsStudentOnboarding =>
      _userModel?.needsStudentOnboarding ?? false;

  void clearBlockedFlag() {
    _isBlockedOnLogin = false;
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    final requestedUid = _authService.currentFirebaseUser?.uid;
    final existingRequest = _loadCurrentUserFuture;
    if (existingRequest != null && _loadCurrentUserUid == requestedUid) {
      return existingRequest;
    }

    final request = _loadCurrentUserInternal(requestedUid);
    _loadCurrentUserFuture = request;
    _loadCurrentUserUid = requestedUid;

    try {
      await request;
    } finally {
      if (identical(_loadCurrentUserFuture, request)) {
        _loadCurrentUserFuture = null;
        _loadCurrentUserUid = null;
      }
    }
  }

  Future<void> _loadCurrentUserInternal(String? expectedUid) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (expectedUid == null) {
        _stopUserDocListener();
        _userModel = null;
        return;
      }

      final userModel = await _authService.getCurrentUserProfile(
        reloadAuthUser: true,
      );
      if (_authService.currentFirebaseUser?.uid != expectedUid) {
        return;
      }

      _userModel = userModel;

      if (userModel != null) {
        _startUserDocListener(userModel.uid);
      } else {
        _stopUserDocListener();
      }
    } catch (e) {
      if (_isIgnorableFirebaseCancellation(e)) {
        _isLoading = false;
        _isInitialLoadDone = true;
        notifyListeners();
        return;
      }
      recordNonFatal(e, StackTrace.current, context: 'load_current_user');
    } finally {
      if (expectedUid == null ||
          _authService.currentFirebaseUser?.uid == expectedUid) {
        _isLoading = false;
        _isInitialLoadDone = true;
        notifyListeners();
      }
    }
  }

  void _handleFirebaseAuthStateChanged(User? firebaseUser) {
    final signature = _buildFirebaseUserSignature(firebaseUser);
    if (_hasReceivedAuthState && _lastFirebaseUserSignature == signature) {
      return;
    }

    _hasReceivedAuthState = true;
    _lastFirebaseUserSignature = signature;

    if (firebaseUser == null) {
      _handleSignedOutAuthState();
      return;
    }

    unawaited(loadCurrentUser());
  }

  void _handleSignedOutAuthState() {
    final shouldNotify =
        _userModel != null || _isLoading || !_isInitialLoadDone;

    _stopUserDocListener();
    _userModel = null;
    _isLoading = false;
    _isInitialLoadDone = true;
    _lastFirebaseUserSignature = null;

    if (shouldNotify) {
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

            final updatedUser = _mergeLiveAuthFields(
              profileData: data,
              userModel: UserModel.fromMap(data),
            );

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

            recordNonFatal(error, stackTrace, context: 'user_doc_listener');
          },
        );
  }

  void _stopUserDocListener() {
    _userDocSubscription?.cancel();
    _userDocSubscription = null;
    _listeningUserUid = null;
  }

  String? _buildFirebaseUserSignature(User? firebaseUser) {
    if (firebaseUser == null) {
      return null;
    }

    final providers =
        firebaseUser.providerData
            .map((info) => info.providerId.trim())
            .where((providerId) => providerId.isNotEmpty)
            .toList()
          ..sort();

    return [
      firebaseUser.uid,
      (firebaseUser.email ?? '').trim().toLowerCase(),
      firebaseUser.emailVerified ? 'verified' : 'unverified',
      providers.join(','),
    ].join('|');
  }

  UserModel _mergeLiveAuthFields({
    required Map<String, dynamic> profileData,
    required UserModel userModel,
  }) {
    final firebaseUser = _authService.currentFirebaseUser;
    if (firebaseUser == null || firebaseUser.uid != userModel.uid) {
      return userModel;
    }

    final authEmail = (firebaseUser.email ?? '').trim();
    final storedEmail = (profileData['email'] ?? '').toString().trim();
    if (authEmail.isEmpty || authEmail == storedEmail) {
      return userModel;
    }

    unawaited(_authService.syncCurrentUserEmailToProfile().catchError((_) {}));
    return userModel.copyWith(email: authEmail);
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

      final signedInUid = _authService.currentFirebaseUser?.uid;
      return await _finishSignIn(
        signedInUid,
        incompleteMessage: 'Login did not finish. Please try again.',
      );
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e.code);
    } on TimeoutException {
      return 'Sign in is taking too long. Please check your connection and try again.';
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
      case 'auth-timeout':
      case 'profile-load-timeout':
        return 'Sign in is taking too long. Please check your connection and try again.';
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

      final signedInUid = _authService.currentFirebaseUser?.uid;
      return await _finishSignIn(
        signedInUid,
        incompleteMessage: 'Google sign-in did not finish. Please try again.',
      );
    } on GoogleSignInException catch (e) {
      return _mapGoogleSignInError(e);
    } on FirebaseAuthException catch (e) {
      return _mapGoogleSignInError(e);
    } catch (e) {
      return _mapGoogleSignInError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static String _mapGoogleSignInError(Object error) {
    if (error is GoogleSignInException) {
      switch (error.code) {
        case GoogleSignInExceptionCode.canceled:
          return 'Google sign-in was canceled.';
        case GoogleSignInExceptionCode.interrupted:
          return 'Google sign-in was interrupted. Please try again.';
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
          return 'Google sign-in is not configured correctly for this app build.';
        case GoogleSignInExceptionCode.uiUnavailable:
          return 'Google sign-in could not open right now. Please try again.';
        case GoogleSignInExceptionCode.userMismatch:
          return 'Google sign-in used a different account than expected. Please try again.';
        case GoogleSignInExceptionCode.unknownError:
          final description = (error.description ?? '').trim();
          if (description.isNotEmpty) {
            return description;
          }
          return 'Google sign-in failed. Please try again.';
      }
    }

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'auth-timeout':
        case 'google-init-timeout':
        case 'profile-load-timeout':
          return error.message ??
              'Google sign-in is taking too long. Please try again.';
        case 'missing-google-id-token':
          return 'Google sign-in did not return the required token. Check the Google/Firebase setup.';
        case 'account-exists-with-different-credential':
          return 'This email is already linked to another sign-in method.';
        case 'invalid-credential':
          return 'Google sign-in returned an invalid credential. Please try again.';
        case 'network-request-failed':
          return 'Network error. Please check your connection and try again.';
        default:
          return error.message ?? 'Google sign-in failed. Please try again.';
      }
    }

    if (error is TimeoutException) {
      return 'The request is taking too long. Please check your connection and try again.';
    }

    final message = error.toString().trim();
    if (message.isEmpty) {
      return 'Google sign-in failed. Please try again.';
    }

    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }

  Future<String?> _finishSignIn(
    String? signedInUid, {
    required String incompleteMessage,
  }) async {
    if (signedInUid == null) {
      return incompleteMessage;
    }

    await loadCurrentUser();

    if (_authService.currentFirebaseUser?.uid != signedInUid) {
      return incompleteMessage;
    }

    final user = _userModel;
    if (user == null) {
      await _authService.logout();
      return 'Account profile could not be loaded. Please try again.';
    }

    if (!user.isActive) {
      await _authService.logout();
      _userModel = null;
      _isBlockedOnLogin = true;
      return null;
    }

    _startUserDocListener(user.uid);
    return null;
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
    try {
      _isLoading = true;
      notifyListeners();

      if (_userModel == null) {
        return 'User not found';
      }

      await _authService.completeStudentOnboarding(
        uid: _userModel!.uid,
        fullName: fullName,
        phone: phone,
        location: location,
        university: university,
        fieldOfStudy: fieldOfStudy,
        bio: bio,
        researchTopic: researchTopic,
        laboratory: laboratory,
        supervisor: supervisor,
        researchDomain: researchDomain,
      );

      _userModel = await _authService.getCurrentUserProfile();

      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> updatePreferredPostingLanguage(String languageCode) async {
    final currentUser = _userModel;
    if (currentUser == null) {
      return 'User not found';
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update(<String, dynamic>{
            'preferredPostingLanguage': languageCode.trim(),
          });

      _userModel = currentUser.copyWith(
        preferredPostingLanguage: languageCode.trim(),
      );
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // --------------- Email Verification ---------------

  bool get hasPasswordProvider => _authService.hasPasswordProvider;

  bool get hasGoogleProvider => _authService.hasGoogleProvider;

  bool get hasMultipleSignInMethods => _authService.hasMultipleSignInMethods;

  bool get canAddPassword => _authService.canAddPassword;

  bool get isEmailProvider => hasPasswordProvider && !hasGoogleProvider;

  bool get canChangePassword => _authService.canChangePassword;

  bool get canChangeEmail {
    if (_userModel?.isAdmin == true) {
      return false;
    }
    return _authService.canChangeEmail;
  }

  bool get requiresEmailVerification => _authService.requiresEmailVerification;

  String get linkedProviderLabel => _authService.linkedProviderLabel;

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
      return _mapPasswordResetError(e);
    } catch (e) {
      return 'We could not send the reset link right now. Please try again in a moment.';
    }
  }

  String _mapPasswordResetError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No account was found for that email address.';
      case 'invalid-email':
        return 'Enter a valid email address and try again.';
      case 'password-reset-google-only':
        return 'This account signs in with Google. Go back and continue with Google, then add a password later from Settings if you want reset emails too.';
      case 'too-many-requests':
        return 'Too many reset attempts were made. Please wait a little and try again.';
      case 'network-request-failed':
        return 'We could not reach the password reset service. Check your connection and try again.';
      case 'password-reset-failed':
        return _mapPasswordResetFailureMessage(error.message);
      default:
        return _mapPasswordResetFailureMessage(error.message);
    }
  }

  String _mapPasswordResetFailureMessage(String? rawMessage) {
    final message = (rawMessage ?? '').trim().toLowerCase();

    if (message.contains('google sign-in') ||
        message.contains('sign in with google')) {
      return 'This account signs in with Google. Go back and continue with Google, then add a password later from Settings if you want reset emails too.';
    }

    if (message.contains('network') || message.contains('connection')) {
      return 'We could not reach the password reset service. Check your connection and try again.';
    }

    if (message.contains('too many') || message.contains('try again later')) {
      return 'Too many reset attempts were made. Please wait a little and try again.';
    }

    if (message.contains('internal server error') ||
        message.contains('not configured') ||
        message.contains('temporarily unavailable') ||
        message.contains('firebase_web_api_key')) {
      return 'Password reset is temporarily unavailable. Please try again in a few minutes.';
    }

    return 'We could not send the reset link right now. Please try again in a moment.';
  }

  // --------------- Add Password ---------------

  Future<String?> addPassword({required String newPassword}) async {
    try {
      await _authService.addPassword(newPassword: newPassword);
      _userModel = await _authService.getCurrentUserProfile();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'Password is too weak.';
      }
      if (e.code == 'password-already-available') {
        return 'This account already has email and password sign-in enabled.';
      }
      if (e.code == 'credential-already-in-use') {
        return 'This email is already linked to another password account.';
      }
      if (e.code == 'provider-already-linked') {
        return 'Email and password sign-in is already linked to this account.';
      }
      if (e.code == 'requires-recent-login') {
        return 'For security, sign in again with Google and then try adding a password.';
      }
      if (e.code == 'missing-email') {
        return e.message ??
            'This account does not have an email address available for password sign-in.';
      }
      return e.message ?? 'Failed to add a password.';
    } catch (e) {
      return 'An unexpected error occurred.';
    } finally {
      notifyListeners();
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
      if (e.code == 'password-change-not-supported' ||
          e.code == 'password-provider-not-linked') {
        return 'Password changes are only available after email and password sign-in is linked to this account.';
      }
      if (e.code == 'requires-recent-login') {
        return 'For security, sign in again and then try changing your password.';
      }
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
    if (_userModel?.isAdmin == true) {
      return 'Admin accounts cannot change their sign-in email from inside the app.';
    }

    try {
      await _authService.changeEmail(
        currentPassword: currentPassword,
        newEmail: newEmail,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-change-not-supported' ||
          e.code == 'password-provider-not-linked') {
        return e.message ??
            'This account cannot change its sign-in email from inside the app.';
      }
      if (e.code == 'requires-recent-login') {
        return 'For security, sign in again and then try changing your email.';
      }
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
    final previousUser = _userModel;

    _stopUserDocListener();
    _isBlockedOnLogin = false;
    _userModel = null;
    _isLoading = false;
    _isInitialLoadDone = true;
    notifyListeners();

    try {
      final logoutFuture = _authService.logout();
      await WidgetsBinding.instance.endOfFrame;
      appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      await logoutFuture;
    } catch (_) {
      if (_authService.currentFirebaseUser != null && previousUser != null) {
        _userModel = previousUser;
        _startUserDocListener(previousUser.uid);
        notifyListeners();
        rethrow;
      }
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _stopUserDocListener();
    super.dispose();
  }
}
