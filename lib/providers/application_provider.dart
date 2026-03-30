import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/application_service.dart';

class ApplicationProvider extends ChangeNotifier {
  final ApplicationService _service = ApplicationService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

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
}
