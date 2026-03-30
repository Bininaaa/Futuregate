import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../models/opportunity_model.dart';
import '../models/application_model.dart';
import '../models/cv_model.dart';
import '../services/company_service.dart';

class CompanyProvider extends ChangeNotifier {
  final CompanyService _service = CompanyService();

  List<OpportunityModel> _opportunities = [];
  List<ApplicationModel> _applications = [];
  Map<String, dynamic> _stats = {};

  bool _dashboardLoading = false;
  bool _opportunitiesLoading = false;
  bool _applicationsLoading = false;

  String? _dashboardError;
  String? _opportunitiesError;
  String? _applicationsError;

  List<OpportunityModel> get opportunities => _opportunities;
  List<ApplicationModel> get applications => _applications;
  Map<String, dynamic> get stats => _stats;

  bool get dashboardLoading => _dashboardLoading;
  bool get opportunitiesLoading => _opportunitiesLoading;
  bool get applicationsLoading => _applicationsLoading;

  bool _mutationLoading = false;
  String? _mutationError;
  final Set<String> _busyAppIds = {};

  String? get dashboardError => _dashboardError;
  String? get opportunitiesError => _opportunitiesError;
  String? get applicationsError => _applicationsError;
  bool get mutationLoading => _mutationLoading;
  String? get mutationError => _mutationError;
  bool isAppBusy(String appId) => _busyAppIds.contains(appId);

  Future<void> loadDashboard(String companyId) async {
    _dashboardLoading = true;
    _dashboardError = null;
    notifyListeners();

    try {
      _opportunities = await _service.getCompanyOpportunities(companyId);
      _applications = await _service.getCompanyApplications(companyId);

      int pendingCount = 0;
      int acceptedCount = 0;
      int rejectedCount = 0;
      for (final app in _applications) {
        if (app.status == 'pending') {
          pendingCount++;
        } else if (app.status == 'accepted') {
          acceptedCount++;
        } else if (app.status == 'rejected') {
          rejectedCount++;
        }
      }

      _stats = {
        'totalOpportunities': _opportunities.length,
        'totalApplications': _applications.length,
        'pendingApplications': pendingCount,
        'acceptedApplications': acceptedCount,
        'rejectedApplications': rejectedCount,
        'openOpportunities': _opportunities
            .where((o) => o.status == 'open')
            .length,
        'closedOpportunities': _opportunities
            .where((o) => o.status == 'closed')
            .length,
      };
    } catch (e) {
      _dashboardError = e.toString();
    } finally {
      _dashboardLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOpportunities(String companyId) async {
    _opportunitiesLoading = true;
    _opportunitiesError = null;
    notifyListeners();

    try {
      _opportunities = await _service.getCompanyOpportunities(companyId);
    } catch (e) {
      _opportunitiesError = e.toString();
    } finally {
      _opportunitiesLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadApplications(String companyId) async {
    _applicationsLoading = true;
    _applicationsError = null;
    notifyListeners();

    try {
      _applications = await _service.getCompanyApplications(companyId);
    } catch (e) {
      _applicationsError = e.toString();
    } finally {
      _applicationsLoading = false;
      notifyListeners();
    }
  }

  Future<OpportunityModel?> getOpportunityById(String oppId) async {
    try {
      return await _service.getOpportunityById(oppId);
    } catch (e) {
      return null;
    }
  }

  Future<String?> createOpportunity(Map<String, dynamic> data) async {
    _mutationLoading = true;
    _mutationError = null;
    notifyListeners();
    try {
      await _service.createOpportunity(data);
      return null;
    } catch (e) {
      _mutationError = e.toString();
      return _mutationError;
    } finally {
      _mutationLoading = false;
      notifyListeners();
    }
  }

  Future<String?> updateOpportunity(
    String oppId,
    Map<String, dynamic> data,
  ) async {
    _mutationLoading = true;
    _mutationError = null;
    notifyListeners();
    try {
      await _service.updateOpportunity(oppId, data);
      return null;
    } catch (e) {
      _mutationError = e.toString();
      return _mutationError;
    } finally {
      _mutationLoading = false;
      notifyListeners();
    }
  }

  Future<bool?> deleteOpportunity(String oppId) async {
    _mutationLoading = true;
    _mutationError = null;
    notifyListeners();
    try {
      return await _service.deleteOpportunity(oppId);
    } catch (e) {
      _mutationError = e.toString();
      return null;
    } finally {
      _mutationLoading = false;
      notifyListeners();
    }
  }

  Future<String?> updateApplicationStatus({
    required String appId,
    required String status,
  }) async {
    if (_busyAppIds.contains(appId)) return null;
    _busyAppIds.add(appId);
    _mutationLoading = true;
    _mutationError = null;
    notifyListeners();
    try {
      await _service.updateApplicationStatus(appId: appId, status: status);
      return null;
    } catch (e) {
      _mutationError = e.toString();
      return _mutationError;
    } finally {
      _busyAppIds.remove(appId);
      _mutationLoading = false;
      notifyListeners();
    }
  }

  Future<CvModel?> getApplicationCv(String applicationId) async {
    try {
      return await _service.getApplicationCv(applicationId);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCompanyProfile(String companyId) async {
    try {
      return await _service.getCompanyProfile(companyId);
    } catch (e) {
      return null;
    }
  }

  Future<String?> updateProfile(
    String uid,
    Map<String, dynamic> data, {
    String commercialRegisterFilePath = '',
    String commercialRegisterFileName = '',
    Uint8List? commercialRegisterBytes,
  }) async {
    _mutationLoading = true;
    _mutationError = null;
    notifyListeners();
    try {
      await _service.updateCompanyProfile(
        uid,
        data,
        commercialRegisterFilePath: commercialRegisterFilePath,
        commercialRegisterFileName: commercialRegisterFileName,
        commercialRegisterBytes: commercialRegisterBytes,
      );
      return null;
    } catch (e) {
      _mutationError = e.toString();
      return _mutationError;
    } finally {
      _mutationLoading = false;
      notifyListeners();
    }
  }

  Future<String?> uploadCompanyLogo({
    required String uid,
    required String fileName,
    String filePath = '',
    Uint8List? fileBytes,
  }) async {
    _mutationLoading = true;
    _mutationError = null;
    notifyListeners();
    try {
      await _service.uploadAndSetCompanyLogo(
        uid: uid,
        fileName: fileName,
        filePath: filePath,
        fileBytes: fileBytes,
      );
      return null;
    } catch (e) {
      _mutationError = e.toString();
      return _mutationError;
    } finally {
      _mutationLoading = false;
      notifyListeners();
    }
  }

  Future<String?> removeCompanyLogo(String uid) async {
    _mutationLoading = true;
    _mutationError = null;
    notifyListeners();
    try {
      await _service.removeCompanyLogo(uid);
      return null;
    } catch (e) {
      _mutationError = e.toString();
      return _mutationError;
    } finally {
      _mutationLoading = false;
      notifyListeners();
    }
  }
}
