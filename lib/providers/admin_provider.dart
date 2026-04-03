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
  String _companyApprovalFilter = 'all';
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
  List<UserModel> get rawUsers => List.unmodifiable(_allUsers);
  String get userRoleFilter => _userRoleFilter;
  String get userLevelFilter => _userLevelFilter;
  String get companyApprovalFilter => _companyApprovalFilter;
  String get userSearch => _userSearch;
  bool get usersLoading => _usersLoading;
  String? get usersError => _usersError;
  int get totalUsersCount => _allUsers.length;
  int get activeUsersCount => _allUsers.where((user) => user.isActive).length;
  int get blockedUsersCount => _allUsers.where((user) => !user.isActive).length;
  int get adminUsersCount =>
      _allUsers.where((user) => user.role == 'admin').length;
  int get companyUsersCount =>
      _allUsers.where((user) => user.role == 'company').length;
  int get pendingCompanyUsersCount =>
      _allUsers.where((user) => user.isCompanyPendingApproval).length;
  int get approvedCompanyUsersCount => _allUsers
      .where((user) => user.role == 'company' && user.isCompanyApproved)
      .length;
  int get rejectedCompanyUsersCount =>
      _allUsers.where((user) => user.isCompanyRejected).length;
  int get studentUsersCount =>
      _allUsers.where((user) => user.role == 'student').length;

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
    if (role != 'company' && role != 'all') {
      _companyApprovalFilter = 'all';
    }
    _applyUserFilters();
    notifyListeners();
  }

  void setUserLevelFilter(String level) {
    _userLevelFilter = level;
    _applyUserFilters();
    notifyListeners();
  }

  void setCompanyApprovalFilter(String status) {
    _companyApprovalFilter = status;
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
      if (_companyApprovalFilter != 'all') {
        if (user.role != 'company') {
          return false;
        }
        if (user.normalizedApprovalStatus != _companyApprovalFilter) {
          return false;
        }
      }
      if (_userSearch.isNotEmpty) {
        final q = _userSearch.toLowerCase();
        return user.fullName.toLowerCase().contains(q) ||
            user.email.toLowerCase().contains(q) ||
            (user.companyName ?? '').toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  Future<String?> toggleUserActive(String uid, bool isActive) async {
    try {
      await _adminService.toggleUserActive(uid, isActive);
      final idx = _allUsers.indexWhere((u) => u.uid == uid);
      if (idx != -1) {
        _allUsers[idx] = _allUsers[idx].copyWith(isActive: isActive);
        _applyUserFilters();
        notifyListeners();
      }
      return null;
    } catch (e) {
      debugPrint('toggleUserActive error: $e');
      return 'Failed to update user status';
    }
  }

  Future<String?> updateCompanyApprovalStatus(String uid, String status) async {
    try {
      await _adminService.updateCompanyApprovalStatus(uid, status);
      final idx = _allUsers.indexWhere((user) => user.uid == uid);
      if (idx != -1) {
        _allUsers[idx] = _allUsers[idx].copyWith(approvalStatus: status);
        _applyUserFilters();
        notifyListeners();
      }
      return null;
    } catch (e) {
      debugPrint('updateCompanyApprovalStatus error: $e');
      return 'Failed to update company approval status';
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
        _allProjectIdeas[idx] = old.copyWith(status: status);
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

  Future<String?> createAdminProjectIdea(Map<String, dynamic> data) async {
    try {
      final created = await _adminService.createAdminProjectIdea(data);
      _allProjectIdeas = [created, ..._allProjectIdeas];
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('createAdminProjectIdea error: $e');
      return 'Failed to create project idea';
    }
  }

  Future<String?> updateAdminProjectIdea(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final updated = await _adminService.updateAdminProjectIdea(id, data);
      final index = _allProjectIdeas.indexWhere((idea) => idea.id == id);
      if (index != -1) {
        _allProjectIdeas[index] = updated;
        notifyListeners();
      }
      return null;
    } catch (e) {
      debugPrint('updateAdminProjectIdea error: $e');
      return 'Failed to update project idea';
    }
  }

  Future<String?> deleteProjectIdea(String id) async {
    try {
      await _adminService.deleteProjectIdea(id);
      _allProjectIdeas.removeWhere((idea) => idea.id == id);
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('deleteProjectIdea error: $e');
      return 'Failed to delete project idea';
    }
  }

  Future<String?> createAdminOpportunity(Map<String, dynamic> data) async {
    try {
      final created = await _adminService.createAdminOpportunity(data);
      _allOpportunities = [created, ..._allOpportunities];
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('createAdminOpportunity error: $e');
      return 'Failed to create opportunity';
    }
  }

  Future<String?> updateAdminOpportunity(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final updated = await _adminService.updateAdminOpportunity(id, data);
      final index = _allOpportunities.indexWhere((item) => item['id'] == id);
      if (index != -1) {
        _allOpportunities[index] = updated;
        notifyListeners();
      }
      return null;
    } catch (e) {
      debugPrint('updateAdminOpportunity error: $e');
      return 'Failed to update opportunity';
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

  Future<String?> createScholarship(Map<String, dynamic> data) async {
    try {
      final created = await _adminService.createScholarship(data);
      _allScholarships = [created, ..._allScholarships];
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('createScholarship error: $e');
      return 'Failed to create scholarship';
    }
  }

  Future<String?> updateScholarship(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final updated = await _adminService.updateScholarship(id, data);
      final index = _allScholarships.indexWhere((item) => item['id'] == id);
      if (index != -1) {
        _allScholarships[index] = updated;
        notifyListeners();
      }
      return null;
    } catch (e) {
      debugPrint('updateScholarship error: $e');
      return 'Failed to update scholarship';
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
