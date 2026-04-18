import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/project_idea_model.dart';
import '../models/saved_idea_model.dart';
import '../services/project_idea_service.dart';

class ProjectIdeaProvider extends ChangeNotifier {
  ProjectIdeaProvider({ProjectIdeaService? service})
    : _service = service ?? ProjectIdeaService();

  final ProjectIdeaService _service;

  List<ProjectIdeaModel> _approvedIdeas = <ProjectIdeaModel>[];
  List<ProjectIdeaModel> _myIdeas = <ProjectIdeaModel>[];
  List<SavedIdeaModel> _savedIdeas = <SavedIdeaModel>[];
  bool _isLoading = false;
  bool _savedIdeasLoading = false;
  String? _savedIdeasError;
  String _currentUserId = '';
  String? _filterDomain;
  String? _filterStatus;
  final Set<String> _busyInteractionKeys = <String>{};

  List<ProjectIdeaModel> get approvedIdeas {
    var list = _approvedIdeas;
    if (_filterDomain != null && _filterDomain!.isNotEmpty) {
      list = list
          .where((idea) => idea.displayCategory == _filterDomain)
          .toList(growable: false);
    }
    return list;
  }

  List<ProjectIdeaModel> get myIdeas {
    var list = _myIdeas;
    if (_filterDomain != null && _filterDomain!.isNotEmpty) {
      list = list
          .where((idea) => idea.displayCategory == _filterDomain)
          .toList(growable: false);
    }
    if (_filterStatus != null && _filterStatus!.isNotEmpty) {
      list = list
          .where((idea) => idea.status == _filterStatus)
          .toList(growable: false);
    }
    return list;
  }

  List<String> get availableDomains {
    final domains = <String>{
      ..._approvedIdeas.map((idea) => idea.displayCategory),
      ..._myIdeas.map((idea) => idea.displayCategory),
    }.where((domain) => domain.trim().isNotEmpty).toList();
    domains.sort();
    return domains;
  }

  String? get filterDomain => _filterDomain;
  String? get filterStatus => _filterStatus;
  bool get isLoading => _isLoading;
  bool get savedIdeasLoading => _savedIdeasLoading;
  String? get savedIdeasError => _savedIdeasError;
  String get currentUserId => _currentUserId;
  List<SavedIdeaModel> get savedIdeas => _savedIdeas;
  int get totalMyIdeaSparks =>
      _myIdeas.fold<int>(0, (total, idea) => total + idea.sparksCount);
  int get totalMyIdeaInterested =>
      _myIdeas.fold<int>(0, (total, idea) => total + idea.interestedCount);

  bool isInteractionBusy(String ideaId, ProjectIdeaInteractionType type) {
    return _busyInteractionKeys.contains('${type.name}:$ideaId');
  }

  ProjectIdeaModel? findIdeaById(String ideaId) {
    for (final idea in <ProjectIdeaModel>[..._approvedIdeas, ..._myIdeas]) {
      if (idea.id == ideaId) {
        return idea;
      }
    }
    return null;
  }

  void setFilterDomain(String? domain) {
    _filterDomain = (domain ?? '').trim().isEmpty ? null : domain?.trim();
    notifyListeners();
  }

  void setFilterStatus(String? status) {
    _filterStatus = (status ?? '').trim().isEmpty ? null : status?.trim();
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
      await _hydrateEngagement();
    } catch (e) {
      debugPrint('fetchApprovedIdeas error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyProjectIdeas(String studentId) async {
    try {
      _currentUserId = studentId.trim();
      _isLoading = true;
      notifyListeners();
      _myIdeas = await _service.getProjectIdeasByStudent(_currentUserId);
      await _hydrateEngagement();
    } catch (e) {
      debugPrint('fetchMyProjectIdeas error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchIdeas(String studentId) async {
    _currentUserId = studentId.trim();
    _isLoading = true;
    notifyListeners();

    try {
      List<ProjectIdeaModel> approved = const <ProjectIdeaModel>[];
      List<ProjectIdeaModel> mine = const <ProjectIdeaModel>[];

      await Future.wait([
        _service
            .getApprovedProjectIdeas()
            .then((result) => approved = result)
            .catchError((Object error) {
              debugPrint('fetchApprovedIdeas error: $error');
              return const <ProjectIdeaModel>[];
            }),
        if (_currentUserId.isNotEmpty)
          _service
              .getProjectIdeasByStudent(_currentUserId)
              .then((result) => mine = result)
              .catchError((Object error) {
                debugPrint('fetchMyIdeas error: $error');
                return const <ProjectIdeaModel>[];
              }),
      ]);

      _approvedIdeas = approved;
      _myIdeas = mine;
      await _hydrateEngagement();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshIdeaEngagement() async {
    await _hydrateEngagement();
    notifyListeners();
  }

  Future<void> fetchSavedIdeas(String studentId, {bool silent = false}) async {
    final normalizedStudentId = studentId.trim();
    if (normalizedStudentId.isEmpty) {
      _savedIdeas = <SavedIdeaModel>[];
      _savedIdeasError = null;
      if (!silent) {
        notifyListeners();
      }
      return;
    }

    _currentUserId = normalizedStudentId;

    try {
      if (!silent) {
        _savedIdeasLoading = true;
        _savedIdeasError = null;
        notifyListeners();
      } else {
        _savedIdeasError = null;
      }

      _savedIdeas = await _service.getSavedIdeas(normalizedStudentId);
    } catch (e) {
      _savedIdeasError = e.toString();
      debugPrint('fetchSavedIdeas error: $e');
    } finally {
      _savedIdeasLoading = false;
      notifyListeners();
    }
  }

  Future<String?> submitProjectIdea({
    required String title,
    required String description,
    required String domain,
    required String level,
    required String tools,
    required String submittedBy,
    String originalLanguage = '',
    String tagline = '',
    String shortDescription = '',
    String category = '',
    List<String> tags = const <String>[],
    String stage = '',
    List<String> skillsNeeded = const <String>[],
    List<String> teamNeeded = const <String>[],
    String targetAudience = '',
    String problemStatement = '',
    String solution = '',
    String resourcesNeeded = '',
    String benefits = '',
    String imageUrl = '',
    String attachmentUrl = '',
    bool isPublic = true,
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
        originalLanguage: originalLanguage,
        tagline: tagline,
        shortDescription: shortDescription,
        category: category,
        tags: tags,
        stage: stage,
        skillsNeeded: skillsNeeded,
        teamNeeded: teamNeeded,
        targetAudience: targetAudience,
        problemStatement: problemStatement,
        solution: solution,
        resourcesNeeded: resourcesNeeded,
        benefits: benefits,
        imageUrl: imageUrl,
        attachmentUrl: attachmentUrl,
        isPublic: isPublic,
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
    String originalLanguage = '',
    String tagline = '',
    String shortDescription = '',
    String category = '',
    List<String> tags = const <String>[],
    String stage = '',
    List<String> skillsNeeded = const <String>[],
    List<String> teamNeeded = const <String>[],
    String targetAudience = '',
    String problemStatement = '',
    String solution = '',
    String resourcesNeeded = '',
    String benefits = '',
    String imageUrl = '',
    String attachmentUrl = '',
    bool isPublic = true,
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
        originalLanguage: originalLanguage,
        tagline: tagline,
        shortDescription: shortDescription,
        category: category,
        tags: tags,
        stage: stage,
        skillsNeeded: skillsNeeded,
        teamNeeded: teamNeeded,
        targetAudience: targetAudience,
        problemStatement: problemStatement,
        solution: solution,
        resourcesNeeded: resourcesNeeded,
        benefits: benefits,
        imageUrl: imageUrl,
        attachmentUrl: attachmentUrl,
        isPublic: isPublic,
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

  Future<String?> toggleSpark(ProjectIdeaModel idea, String userId) {
    return _toggleInteraction(
      idea: idea,
      userId: userId,
      type: ProjectIdeaInteractionType.spark,
      isEnabled: idea.isSparkedByCurrentUser,
    );
  }

  Future<String?> toggleInterest(ProjectIdeaModel idea, String userId) {
    return _toggleInteraction(
      idea: idea,
      userId: userId,
      type: ProjectIdeaInteractionType.interest,
      isEnabled: idea.isJoinedByCurrentUser,
    );
  }

  Future<String?> toggleSave(ProjectIdeaModel idea, String userId) {
    return _toggleInteraction(
      idea: idea,
      userId: userId,
      type: ProjectIdeaInteractionType.save,
      isEnabled: idea.isSavedByCurrentUser,
    );
  }

  Future<String?> _toggleInteraction({
    required ProjectIdeaModel idea,
    required String userId,
    required ProjectIdeaInteractionType type,
    required bool isEnabled,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return 'You need to be signed in.';
    }

    final busyKey = '${type.name}:${idea.id}';
    if (_busyInteractionKeys.contains(busyKey)) {
      return null;
    }

    _busyInteractionKeys.add(busyKey);
    _applyInteractionLocally(ideaId: idea.id, type: type, enabled: !isEnabled);
    if (type == ProjectIdeaInteractionType.save) {
      _applySavedIdeaLocally(
        idea: idea,
        userId: normalizedUserId,
        enabled: !isEnabled,
      );
    }
    notifyListeners();

    try {
      await _service.setInteraction(
        ideaId: idea.id,
        userId: normalizedUserId,
        type: type,
        enabled: !isEnabled,
      );
      if (type == ProjectIdeaInteractionType.save) {
        _currentUserId = normalizedUserId;
        await fetchSavedIdeas(normalizedUserId, silent: true);
      }
      return null;
    } catch (e) {
      _applyInteractionLocally(ideaId: idea.id, type: type, enabled: isEnabled);
      if (type == ProjectIdeaInteractionType.save) {
        _applySavedIdeaLocally(
          idea: idea,
          userId: normalizedUserId,
          enabled: isEnabled,
        );
      }
      notifyListeners();
      return e.toString();
    } finally {
      _busyInteractionKeys.remove(busyKey);
      notifyListeners();
    }
  }

  Future<void> _hydrateEngagement() async {
    final allIdeas = <ProjectIdeaModel>[..._approvedIdeas, ..._myIdeas];
    final ideaIds = allIdeas.map((idea) => idea.id).toSet().toList();
    if (ideaIds.isEmpty) {
      return;
    }

    final engagement = await _service.getEngagementForIdeas(
      ideaIds: ideaIds,
      currentUserId: _currentUserId,
    );

    _approvedIdeas = _applyEngagement(_approvedIdeas, engagement);
    _myIdeas = _applyEngagement(_myIdeas, engagement);
  }

  List<ProjectIdeaModel> _applyEngagement(
    List<ProjectIdeaModel> ideas,
    ProjectIdeaEngagementSnapshot engagement,
  ) {
    return ideas
        .map(
          (idea) => idea.copyWith(
            sparksCount: engagement.sparksByIdeaId[idea.id] ?? idea.sparksCount,
            interestedCount:
                engagement.interestedByIdeaId[idea.id] ?? idea.interestedCount,
            isSavedByCurrentUser: engagement.savedIdeaIds.contains(idea.id),
            isSparkedByCurrentUser: engagement.sparkedIdeaIds.contains(idea.id),
            isJoinedByCurrentUser: engagement.joinedIdeaIds.contains(idea.id),
          ),
        )
        .toList(growable: false);
  }

  void _applyInteractionLocally({
    required String ideaId,
    required ProjectIdeaInteractionType type,
    required bool enabled,
  }) {
    _approvedIdeas = _approvedIdeas
        .map(
          (idea) =>
              idea.id == ideaId ? _withInteraction(idea, type, enabled) : idea,
        )
        .toList(growable: false);
    _myIdeas = _myIdeas
        .map(
          (idea) =>
              idea.id == ideaId ? _withInteraction(idea, type, enabled) : idea,
        )
        .toList(growable: false);
  }

  void _applySavedIdeaLocally({
    required ProjectIdeaModel idea,
    required String userId,
    required bool enabled,
  }) {
    if (enabled) {
      final updatedIdea = idea.copyWith(isSavedByCurrentUser: true);
      final existingIndex = _savedIdeas.indexWhere(
        (item) => item.ideaId == idea.id,
      );
      final nextItem = SavedIdeaModel(
        id: existingIndex >= 0
            ? _savedIdeas[existingIndex].id
            : 'local_save_${userId}_${idea.id}',
        ideaId: idea.id,
        userId: userId,
        idea: updatedIdea,
        savedAt: Timestamp.now(),
      );

      if (existingIndex >= 0) {
        _savedIdeas[existingIndex] = nextItem;
      } else {
        _savedIdeas = <SavedIdeaModel>[nextItem, ..._savedIdeas];
      }
      return;
    }

    _savedIdeas = _savedIdeas
        .where((item) => item.ideaId != idea.id)
        .toList(growable: false);
  }

  ProjectIdeaModel _withInteraction(
    ProjectIdeaModel idea,
    ProjectIdeaInteractionType type,
    bool enabled,
  ) {
    switch (type) {
      case ProjectIdeaInteractionType.spark:
        return idea.copyWith(
          sparksCount: enabled
              ? idea.sparksCount + 1
              : (idea.sparksCount > 0 ? idea.sparksCount - 1 : 0),
          isSparkedByCurrentUser: enabled,
        );
      case ProjectIdeaInteractionType.interest:
        return idea.copyWith(
          interestedCount: enabled
              ? idea.interestedCount + 1
              : (idea.interestedCount > 0 ? idea.interestedCount - 1 : 0),
          isJoinedByCurrentUser: enabled,
        );
      case ProjectIdeaInteractionType.save:
        return idea.copyWith(isSavedByCurrentUser: enabled);
    }
  }

  void clearUserSession() {
    _myIdeas = <ProjectIdeaModel>[];
    _savedIdeas = <SavedIdeaModel>[];
    _isLoading = false;
    _savedIdeasLoading = false;
    _savedIdeasError = null;
    _currentUserId = '';
    _filterDomain = null;
    _filterStatus = null;
    _busyInteractionKeys.clear();
    _approvedIdeas = _approvedIdeas
        .map(
          (idea) => idea.copyWith(
            isSavedByCurrentUser: false,
            isSparkedByCurrentUser: false,
            isJoinedByCurrentUser: false,
          ),
        )
        .toList(growable: false);
    notifyListeners();
  }
}
