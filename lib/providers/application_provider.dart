import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/student_application_item_model.dart';
import '../services/application_service.dart';

class ApplicationProvider extends ChangeNotifier {
  final ApplicationService _service = ApplicationService();

  bool _isLoading = false;
  int _submittedApplicationsCount = 0;
  bool _submittedApplicationsLoading = false;
  String? _submittedApplicationsError;
  List<StudentApplicationItemModel> _submittedApplications = [];

  bool get isLoading => _isLoading;
  int get submittedApplicationsCount => _submittedApplicationsCount;
  bool get submittedApplicationsLoading => _submittedApplicationsLoading;
  String? get submittedApplicationsError => _submittedApplicationsError;
  List<StudentApplicationItemModel> get submittedApplications =>
      _submittedApplications;

  Future<void> fetchSubmittedApplicationsCount(String studentId) async {
    try {
      _submittedApplicationsCount = await _service.getApplicationsCount(
        studentId,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('fetchSubmittedApplicationsCount error: $e');
    }
  }

  Future<void> fetchSubmittedApplications(String studentId) async {
    final normalizedStudentId = studentId.trim();
    if (normalizedStudentId.isEmpty) {
      _submittedApplications = [];
      _submittedApplicationsCount = 0;
      _submittedApplicationsError = null;
      notifyListeners();
      return;
    }

    try {
      _submittedApplicationsLoading = true;
      _submittedApplicationsError = null;
      notifyListeners();

      final items = await _service.getSubmittedApplications(
        normalizedStudentId,
      );
      _submittedApplications = items;
      _submittedApplicationsCount = items.length;
    } catch (e) {
      _submittedApplicationsError = e.toString();
      debugPrint('fetchSubmittedApplications error: $e');
    } finally {
      _submittedApplicationsLoading = false;
      notifyListeners();
    }
  }

  /// Returns the application status for a specific opportunity, or null if
  /// the student hasn't applied.  Uses the already-loaded submitted list.
  String? applicationStatusFor(String opportunityId) {
    for (final item in _submittedApplications) {
      if (item.opportunityId == opportunityId) {
        return item.status;
      }
    }
    return null;
  }

  /// Returns a set of opportunity IDs the student has applied to.
  Map<String, String> get appliedStatusMap {
    final map = <String, String>{};
    for (final item in _submittedApplications) {
      map[item.opportunityId] = item.status;
    }
    return map;
  }

  Future<ApplicationEligibilityStatus> getEligibility({
    required String studentId,
    required String opportunityId,
  }) {
    return _service.getEligibility(
      studentId: studentId,
      opportunityId: opportunityId,
    );
  }

  Future<String?> applyToOpportunity({
    required String studentId,
    required String studentName,
    required String opportunityId,
    required String cvId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.applyToOpportunity(
        studentId: studentId,
        studentName: studentName,
        opportunityId: opportunityId,
        cvId: cvId,
      );

      _submittedApplications = await _service.getSubmittedApplications(
        studentId,
      );
      _submittedApplicationsCount = _submittedApplications.length;

      return null;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return 'We could not submit your application right now. Please try again.';
      }

      return e.message ?? e.toString();
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSession() {
    _isLoading = false;
    _submittedApplicationsCount = 0;
    _submittedApplicationsLoading = false;
    _submittedApplicationsError = null;
    _submittedApplications = <StudentApplicationItemModel>[];
    notifyListeners();
  }
}
