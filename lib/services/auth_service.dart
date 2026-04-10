import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'notification_worker_service.dart';
import 'storage_service.dart';

class AuthService {
  static const String _googleClientId =
      '620923930909-fjgicjfe2ftr5khlslq0fj2m3e3s6bh5.apps.googleusercontent.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final NotificationWorkerService _notificationWorker =
      NotificationWorkerService();
  final StorageService _storageService = StorageService();

  bool _googleInitialized = false;

  User? get currentFirebaseUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> _initGoogleSignIn() async {
    if (_googleInitialized) return;

    await _googleSignIn.initialize(
      clientId: kIsWeb ? _googleClientId : null,
      serverClientId: _googleClientId,
    );
    _googleInitialized = true;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> register({
    required String fullName,
    required String email,
    required String password,
    required String selectedRole,
    String researchTopic = '',
    String laboratory = '',
    String supervisor = '',
    String researchDomain = '',
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCredential.user!.uid;

    String role = 'student';
    String academicLevel = selectedRole;

    final userData = {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'role': role,
      'academicLevel': academicLevel,
      'phone': '',
      'location': '',
      'profileImage': '',
      'photoType': null,
      'avatarId': null,
      'university': '',
      'fieldOfStudy': '',
      'bio': '',
      'companyName': '',
      'sector': '',
      'description': '',
      'website': '',
      'logo': '',
      'adminLevel': '',
      'researchTopic': researchTopic,
      'laboratory': laboratory,
      'supervisor': supervisor,
      'researchDomain': researchDomain,
      'approvalStatus': '',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'provider': 'email',
      'studentOnboardingPending': false,
    };

    try {
      await _firestore.collection('users').doc(uid).set(userData);
    } catch (e) {
      await userCredential.user!.delete();
      rethrow;
    }

    return userCredential;
  }

  Future<UserCredential> registerCompany({
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
    if (commercialRegisterFileName.trim().isEmpty) {
      throw Exception('سجل تجاري is required to register a company account.');
    }

    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCredential.user!.uid;
    StoredFileUploadResult? uploadedCommercialRegister;

    try {
      uploadedCommercialRegister = await _storageService
          .uploadCommercialRegister(
            userId: uid,
            filePath: commercialRegisterFilePath,
            fileName: commercialRegisterFileName,
            fileBytes: commercialRegisterBytes,
          );
    } catch (e) {
      await userCredential.user!.delete();
      rethrow;
    }

    final userData = {
      'uid': uid,
      'fullName': companyName,
      'email': email,
      'role': 'company',
      'academicLevel': '',
      'phone': phone,
      'location': '',
      'profileImage': '',
      'photoType': null,
      'avatarId': null,
      'university': '',
      'fieldOfStudy': '',
      'bio': '',
      'companyName': companyName,
      'sector': sector,
      'description': description,
      'website': website,
      'logo': '',
      'adminLevel': '',
      'researchTopic': '',
      'laboratory': '',
      'supervisor': '',
      'researchDomain': '',
      'commercialRegisterUrl': uploadedCommercialRegister.fileUrl,
      'commercialRegisterFileName': uploadedCommercialRegister.fileName,
      'commercialRegisterMimeType': uploadedCommercialRegister.mimeType,
      'commercialRegisterStoragePath': uploadedCommercialRegister.objectKey,
      'commercialRegisterUploadedAt': FieldValue.serverTimestamp(),
      'approvalStatus': 'pending',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'provider': 'email',
      'studentOnboardingPending': false,
    };

    try {
      await _firestore.collection('users').doc(uid).set(userData);
      await _notificationWorker.notifyCompanyRegistration(uid);
    } catch (e) {
      if (uploadedCommercialRegister.storagePath.trim().isNotEmpty) {
        try {
          await _storageService.deleteFileByPath(
            uploadedCommercialRegister.storagePath,
          );
        } catch (_) {
          // Ignore cleanup failures while rolling back registration.
        }
      }
      await userCredential.user!.delete();
      rethrow;
    }

    return userCredential;
  }

  Future<UserCredential> signInWithGoogle() async {
    await _initGoogleSignIn();

    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken?.trim() ?? '';

      if (idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message:
              'Google sign-in could not retrieve the required account token.',
        );
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'google-user-missing',
          message: 'Google sign in failed.',
        );
      }

      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        final userData = {
          'uid': user.uid,
          'fullName': user.displayName ?? '',
          'email': user.email ?? '',
          'role': 'student',
          'academicLevel': '',
          'phone': '',
          'location': '',
          'profileImage': user.photoURL ?? '',
          'photoType': null,
          'avatarId': null,
          'university': '',
          'fieldOfStudy': '',
          'bio': '',
          'companyName': '',
          'sector': '',
          'description': '',
          'website': '',
          'logo': '',
          'adminLevel': '',
          'researchTopic': '',
          'laboratory': '',
          'supervisor': '',
          'researchDomain': '',
          'approvalStatus': '',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'provider': 'google',
          'studentOnboardingPending': true,
        };

        await docRef.set(userData);
      } else {
        await _repairLegacyUserProfile(
          user: user,
          docRef: docRef,
          existingData: doc.data() ?? const <String, dynamic>{},
        );
      }

      return userCredential;
    } catch (_) {
      await _cleanupGoogleSignInSession();
      rethrow;
    }
  }

  Future<void> updateAcademicLevel(String uid, String academicLevel) async {
    await _firestore.collection('users').doc(uid).update({
      'academicLevel': academicLevel,
    });
  }

  Future<void> completeStudentOnboarding({
    required String uid,
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
    await _firestore.collection('users').doc(uid).update({
      'fullName': fullName,
      'phone': phone,
      'location': location,
      'university': university,
      'fieldOfStudy': fieldOfStudy,
      'bio': bio,
      'researchTopic': researchTopic,
      'laboratory': laboratory,
      'supervisor': supervisor,
      'researchDomain': researchDomain,
      'studentOnboardingPending': false,
    });
  }

  // --------------- Email Verification ---------------

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<bool> reloadAndCheckVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // --------------- Password Reset ---------------

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // --------------- Re-authentication ---------------

  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  // --------------- Change Password ---------------

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await reauthenticate(currentPassword);
    await _auth.currentUser!.updatePassword(newPassword);
  }

  // --------------- Change Email ---------------

  Future<void> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    await reauthenticate(currentPassword);
    await _auth.currentUser!.verifyBeforeUpdateEmail(newEmail);
  }

  // --------------- Provider Detection ---------------

  String getSignInProvider() {
    final user = _auth.currentUser;
    if (user == null) return 'unknown';
    for (final info in user.providerData) {
      if (info.providerId == 'google.com') return 'google';
      if (info.providerId == 'password') return 'email';
    }
    return 'unknown';
  }

  Future<void> logout() async {
    final shouldSignOutGoogle = getSignInProvider() == 'google';
    await _auth.signOut();

    if (shouldSignOutGoogle) {
      await _cleanupGoogleSignInSession();
    }
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    final patchedData = await _repairLegacyUserProfile(
      user: user,
      docRef: docRef,
      existingData: data,
    );

    return UserModel.fromMap(patchedData ?? data);
  }

  Future<Map<String, dynamic>?> _repairLegacyUserProfile({
    required User user,
    required DocumentReference<Map<String, dynamic>> docRef,
    required Map<String, dynamic> existingData,
  }) async {
    final patch = <String, dynamic>{};
    final detectedProvider = _detectProviderForUser(user);

    void setIfMissing(String key, dynamic value) {
      if (!existingData.containsKey(key)) {
        patch[key] = value;
      }
    }

    void setIfBlank(String key, String value) {
      final current = (existingData[key] ?? '').toString().trim();
      if (current.isEmpty && value.trim().isNotEmpty) {
        patch[key] = value.trim();
      }
    }

    setIfMissing('uid', user.uid);
    setIfBlank('fullName', user.displayName ?? '');
    setIfBlank('email', user.email ?? '');
    setIfMissing('role', 'student');
    setIfMissing('academicLevel', '');
    setIfMissing('phone', '');
    setIfMissing('location', '');
    setIfMissing('photoType', null);
    setIfMissing('avatarId', null);
    setIfMissing('university', '');
    setIfMissing('fieldOfStudy', '');
    setIfMissing('bio', '');
    setIfMissing('companyName', '');
    setIfMissing('sector', '');
    setIfMissing('description', '');
    setIfMissing('website', '');
    setIfMissing('logo', '');
    setIfMissing('adminLevel', '');
    setIfMissing('researchTopic', '');
    setIfMissing('laboratory', '');
    setIfMissing('supervisor', '');
    setIfMissing('researchDomain', '');
    setIfMissing('isActive', true);
    setIfMissing('studentOnboardingPending', false);

    if (!existingData.containsKey('profileImage')) {
      patch['profileImage'] = (user.photoURL ?? '').trim();
    }

    final existingProvider = (existingData['provider'] ?? '').toString().trim();
    if (existingProvider.isEmpty && detectedProvider.isNotEmpty) {
      patch['provider'] = detectedProvider;
    }

    if (patch.isEmpty) {
      return null;
    }

    await docRef.set(patch, SetOptions(merge: true));

    return {...existingData, ...patch};
  }

  String _detectProviderForUser(User user) {
    for (final info in user.providerData) {
      if (info.providerId == 'google.com') {
        return 'google';
      }

      if (info.providerId == 'password') {
        return 'email';
      }
    }

    return '';
  }

  Future<void> _cleanupGoogleSignInSession() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Ignore cleanup failures after auth exceptions.
    }

    try {
      await _initGoogleSignIn();
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore cleanup failures after auth exceptions.
    }
  }
}
