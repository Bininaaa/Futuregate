import 'package:flutter/material.dart';
import '../models/admin_activity_model.dart';
import '../models/admin_application_item_model.dart';
import '../models/user_model.dart';
import '../models/project_idea_model.dart';
import '../models/training_model.dart';
import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  Map<String, dynamic> _stats = {};
  List<UserModel> _recentUsers = [];
  List<Map<String, dynamic>> _recentOpportunities = [];
  List<AdminActivityModel> _recentActivity = [];
  bool _dashboardLoading = false;
  String? _dashboardError;

  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  String _userRoleFilter = 'all';
  String _userLevelFilter = 'all';
  String _userSearch = '';
  bool _usersLoading = false;
  String? _usersError;

  List<ProjectIdeaModel> _allProjectIdeas = [];
  List<AdminApplicationItemModel> _allApplications = [];
  List<Map<String, dynamic>> _allOpportunities = [];
  List<Map<String, dynamic>> _allScholarships = [];
  List<TrainingModel> _allTrainings = [];
  final Set<String> _busyIdeaIds = <String>{};
  bool _moderationLoading = false;
  String? _moderationError;
  bool _activityLoading = false;
  bool _activityLoadingMore = false;
  String? _activityError;
  int _activityPerCollectionLimit = 4;

  Map<String, dynamic> get stats => _stats;
  List<UserModel> get recentUsers => _recentUsers;
  List<Map<String, dynamic>> get recentOpportunities => _recentOpportunities;
  List<AdminActivityModel> get recentActivity => _recentActivity;
  bool get isLoading => _dashboardLoading;
  String? get dashboardError => _dashboardError;

  List<UserModel> get allUsers => _filteredUsers;
  String get userRoleFilter => _userRoleFilter;
  String get userLevelFilter => _userLevelFilter;
  String get userSearch => _userSearch;
  bool get usersLoading => _usersLoading;
  String? get usersError => _usersError;

  List<ProjectIdeaModel> get allProjectIdeas => _allProjectIdeas;
  List<AdminApplicationItemModel> get allApplications => _allApplications;
  List<Map<String, dynamic>> get allOpportunities => _allOpportunities;
  List<Map<String, dynamic>> get allScholarships => _allScholarships;
  List<TrainingModel> get allTrainings => _allTrainings;
  Set<String> get busyIdeaIds => Set.unmodifiable(_busyIdeaIds);
  bool get moderationLoading => _moderationLoading;
  String? get moderationError => _moderationError;
  bool get activityLoading => _activityLoading;
  bool get activityLoadingMore => _activityLoadingMore;
  String? get activityError => _activityError;

  Future<void> loadDashboardData() async {
    try {
      _dashboardLoading = true;
      _dashboardError = null;
      notifyListeners();

      final results = await Future.wait([
        _adminService.getDashboardStats(),
        _adminService.getRecentUsers(),
        _adminService.getRecentOpportunities(),
        _adminService.getAdminActivities(
          perCollectionLimit: _activityPerCollectionLimit,
        ),
      ]);

      _stats = results[0] as Map<String, dynamic>;
      _recentUsers = results[1] as List<UserModel>;
      _recentOpportunities = results[2] as List<Map<String, dynamic>>;
      _recentActivity = results[3] as List<AdminActivityModel>;
    } catch (e) {
      _dashboardError = 'Failed to load dashboard data';
      debugPrint('loadDashboardData error: $e');
    } finally {
      _dashboardLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllUsers() async {
    try {
      _usersLoading = true;
      _usersError = null;
      notifyListeners();

      _allUsers = await _adminService.getAllUsers();
      _applyUserFilters();
    } catch (e) {
      _usersError = 'Failed to load users';
      debugPrint('loadAllUsers error: $e');
    } finally {
      _usersLoading = false;
      notifyListeners();
    }
  }

  void setUserRoleFilter(String role) {
    _userRoleFilter = role;
    if (role != 'student') {
      _userLevelFilter = 'all';
    }
    _applyUserFilters();
    notifyListeners();
  }

  void setUserLevelFilter(String level) {
    _userLevelFilter = level;
    _applyUserFilters();
    notifyListeners();
  }

  void setUserSearch(String query) {
    _userSearch = query;
    _applyUserFilters();
    notifyListeners();
  }

  void _applyUserFilters() {
    _filteredUsers = _allUsers.where((user) {
      if (_userRoleFilter != 'all' && user.role != _userRoleFilter) {
        return false;
      }
      if (_userLevelFilter != 'all' &&
          (user.academicLevel ?? '') != _userLevelFilter) {
        return false;
      }
      if (_userSearch.isNotEmpty) {
        final q = _userSearch.toLowerCase();
        return user.fullName.toLowerCase().contains(q) ||
            user.email.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  Future<String?> toggleUserActive(String uid, bool isActive) async {
    try {
      await _adminService.toggleUserActive(uid, isActive);
      final idx = _allUsers.indexWhere((u) => u.uid == uid);
      if (idx != -1) {
        final old = _allUsers[idx];
        _allUsers[idx] = UserModel(
          uid: old.uid,
          fullName: old.fullName,
          email: old.email,
          role: old.role,
          phone: old.phone,
          location: old.location,
          profileImage: old.profileImage,
          isActive: isActive,
          academicLevel: old.academicLevel,
          university: old.university,
          fieldOfStudy: old.fieldOfStudy,
          bio: old.bio,
          companyName: old.companyName,
          sector: old.sector,
          description: old.description,
          website: old.website,
          logo: old.logo,
          adminLevel: old.adminLevel,
          researchTopic: old.researchTopic,
          laboratory: old.laboratory,
          supervisor: old.supervisor,
          researchDomain: old.researchDomain,
          photoType: old.photoType,
          avatarId: old.avatarId,
          commercialRegisterUrl: old.commercialRegisterUrl,
          commercialRegisterFileName: old.commercialRegisterFileName,
          commercialRegisterMimeType: old.commercialRegisterMimeType,
          commercialRegisterStoragePath: old.commercialRegisterStoragePath,
          commercialRegisterUploadedAt: old.commercialRegisterUploadedAt,
          provider: old.provider,
        );
        _applyUserFilters();
        notifyListeners();
      }
      return null;
    } catch (e) {
      debugPrint('toggleUserActive error: $e');
      return 'Failed to update user status';
    }
  }

  Future<void> loadModerationData() async {
    try {
      _moderationLoading = true;
      _moderationError = null;
      notifyListeners();

      final results = await Future.wait([
        _adminService.getAllProjectIdeas(),
        _adminService.getAllApplications(),
        _adminService.getAllOpportunities(),
        _adminService.getAllScholarships(),
        _adminService.getAllTrainings(),
      ]);

      _allProjectIdeas = results[0] as List<ProjectIdeaModel>;
      _allApplications = results[1] as List<AdminApplicationItemModel>;
      _allOpportunities = results[2] as List<Map<String, dynamic>>;
      _allScholarships = results[3] as List<Map<String, dynamic>>;
      _allTrainings = results[4] as List<TrainingModel>;
    } catch (e) {
      _moderationError = 'Failed to load moderation data';
      debugPrint('loadModerationData error: $e');
    } finally {
      _moderationLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadActivityFeed({bool reset = false}) async {
    try {
      if (reset) {
        _activityPerCollectionLimit = 4;
      }

      _activityLoading = true;
      _activityError = null;
      notifyListeners();

      _recentActivity = await _adminService.getAdminActivities(
        perCollectionLimit: _activityPerCollectionLimit,
      );
    } catch (e) {
      _activityError = 'Failed to load recent activity';
      debugPrint('loadActivityFeed error: $e');
    } finally {
      _activityLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreActivityFeed() async {
    if (_activityLoadingMore) {
      return;
    }

    try {
      _activityLoadingMore = true;
      _activityError = null;
      _activityPerCollectionLimit += 4;
      notifyListeners();

      _recentActivity = await _adminService.getAdminActivities(
        perCollectionLimit: _activityPerCollectionLimit,
      );
    } catch (e) {
      _activityError = 'Failed to load more activity';
      debugPrint('loadMoreActivityFeed error: $e');
    } finally {
      _activityLoadingMore = false;
      notifyListeners();
    }
  }

  Future<String?> updateProjectIdeaStatus(String id, String status) async {
    if (_busyIdeaIds.contains(id)) {
      return 'Idea moderation is already in progress';
    }

    try {
      _busyIdeaIds.add(id);
      notifyListeners();

      final didUpdate = await _adminService.updateProjectIdeaStatus(id, status);
      final idx = _allProjectIdeas.indexWhere((i) => i.id == id);
      if (didUpdate && idx != -1) {
        final old = _allProjectIdeas[idx];
        _allProjectIdeas[idx] = ProjectIdeaModel(
          id: old.id,
          title: old.title,
          description: old.description,
          domain: old.domain,
          level: old.level,
          tools: old.tools,
          status: status,
          submittedBy: old.submittedBy,
          submittedByName: old.submittedByName,
          createdAt: old.createdAt,
        );
        notifyListeners();
      }
      return null;
    } catch (e) {
      debugPrint('updateProjectIdeaStatus error: $e');
      return 'Failed to update idea status';
    } finally {
      _busyIdeaIds.remove(id);
      notifyListeners();
    }
  }

  Future<String?> deleteOpportunity(String id) async {
    try {
      await _adminService.deleteOpportunity(id);
      _allOpportunities.removeWhere((o) => o['id'] == id);
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('deleteOpportunity error: $e');
      return 'Failed to delete opportunity';
    }
  }

  Future<String?> deleteScholarship(String id) async {
    try {
      await _adminService.deleteScholarship(id);
      _allScholarships.removeWhere((s) => s['id'] == id);
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('deleteScholarship error: $e');
      return 'Failed to delete scholarship';
    }
  }
}
