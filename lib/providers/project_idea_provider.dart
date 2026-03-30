import 'package:flutter/material.dart';
import '../models/project_idea_model.dart';
import '../services/project_idea_service.dart';
import 'package:flutter/foundation.dart';

class ProjectIdeaProvider extends ChangeNotifier {
  final ProjectIdeaService _service = ProjectIdeaService();

  List<ProjectIdeaModel> _approvedIdeas = [];
  List<ProjectIdeaModel> _myIdeas = [];
  bool _isLoading = false;

  String? _filterDomain;
  String? _filterStatus;

  List<ProjectIdeaModel> get approvedIdeas {
    var list = _approvedIdeas;
    if (_filterDomain != null && _filterDomain!.isNotEmpty) {
      list = list.where((i) => i.domain == _filterDomain).toList();
    }
    return list;
  }

  List<ProjectIdeaModel> get myIdeas {
    var list = _myIdeas;
    if (_filterDomain != null && _filterDomain!.isNotEmpty) {
      list = list.where((i) => i.domain == _filterDomain).toList();
    }
    if (_filterStatus != null && _filterStatus!.isNotEmpty) {
      list = list.where((i) => i.status == _filterStatus).toList();
    }
    return list;
  }

  List<String> get availableDomains {
    final allIdeas = [..._approvedIdeas, ..._myIdeas];
    final domains = allIdeas
        .map((i) => i.domain)
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList();
    domains.sort();
    return domains;
  }

  String? get filterDomain => _filterDomain;
  String? get filterStatus => _filterStatus;
  bool get isLoading => _isLoading;

  void setFilterDomain(String? domain) {
    _filterDomain = domain;
    notifyListeners();
  }

  void setFilterStatus(String? status) {
    _filterStatus = status;
    notifyListeners();
  }

  void clearFilters() {
    _filterDomain = null;
    _filterStatus = null;
    notifyListeners();
  }

  Future<void> fetchApprovedIdeas() async {
    try {
      _isLoading = true;
      notifyListeners();
      _approvedIdeas = await _service.getApprovedProjectIdeas();
    } catch (e) {
      debugPrint('fetchApprovedIdeas error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyProjectIdeas(String studentId) async {
    try {
      _isLoading = true;
      notifyListeners();
      _myIdeas = await _service.getProjectIdeasByStudent(studentId);
    } catch (e) {
      debugPrint('fetchMyProjectIdeas error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches both approved ideas (public) and the student's own ideas independently.
  /// Each fetch is isolated so a failure in one does not prevent the other from loading.
  Future<void> fetchIdeas(String studentId) async {
    _isLoading = true;
    notifyListeners();

    // Fetch both independently — a failure in approved ideas must never hide the
    // student's own ideas, and vice-versa.
    await Future.wait([
      _service
          .getApprovedProjectIdeas()
          .then((result) {
            _approvedIdeas = result;
          })
          .catchError((e) {
            debugPrint('fetchApprovedIdeas error: $e');
          }),
      _service
          .getProjectIdeasByStudent(studentId)
          .then((result) {
            _myIdeas = result;
          })
          .catchError((e) {
            debugPrint('fetchMyIdeas error: $e');
          }),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> submitProjectIdea({
    required String title,
    required String description,
    required String domain,
    required String level,
    required String tools,
    required String submittedBy,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.submitProjectIdea(
        title: title,
        description: description,
        domain: domain,
        level: level,
        tools: tools,
      );

      await fetchIdeas(submittedBy);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> updateProjectIdea({
    required String id,
    required String title,
    required String description,
    required String domain,
    required String level,
    required String tools,
    required String submittedBy,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.updateProjectIdea(
        id: id,
        title: title,
        description: description,
        domain: domain,
        level: level,
        tools: tools,
      );

      // Refresh so UI reflects the update immediately
      await fetchIdeas(submittedBy);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> deleteProjectIdea(String id) async {
    try {
      await _service.deleteProjectIdea(id);
      _approvedIdeas.removeWhere((idea) => idea.id == id);
      _myIdeas.removeWhere((idea) => idea.id == id);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
