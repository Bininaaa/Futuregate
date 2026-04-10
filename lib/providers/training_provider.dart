import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/training_model.dart';
import '../services/training_service.dart';

class TrainingProvider extends ChangeNotifier {
  final TrainingService _service = TrainingService();

  List<TrainingModel> _trainings = [];
  List<TrainingModel> _savedTrainings = [];
  final Set<String> _savedTrainingIds = <String>{};
  final Set<String> _busyTrainingIds = <String>{};
  bool _isLoading = false;
  bool _isSavedLoading = false;
  String? _errorMessage;
  String? _savedErrorMessage;

  List<TrainingModel> get trainings => _trainings;
  List<TrainingModel> get savedTrainings => _savedTrainings;
  Set<String> get savedTrainingIds => _savedTrainingIds;
  List<TrainingModel> get featuredTrainings => _trainings
      .where((training) => training.isApproved && training.isFeatured)
      .toList();
  bool get isLoading => _isLoading;
  bool get isSavedLoading => _isSavedLoading;
  String? get errorMessage => _errorMessage;
  String? get savedErrorMessage => _savedErrorMessage;

  bool isTrainingSaved(String trainingId) =>
      _savedTrainingIds.contains(trainingId);

  bool isTrainingBusy(String trainingId) =>
      _busyTrainingIds.contains(trainingId);

  Future<void> fetchTrainings() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _trainings = await _service.getAllTrainings();
    } catch (e) {
      _errorMessage = 'Could not load training resources.';
      debugPrint('fetchTrainings error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSavedTrainings(String userId) async {
    try {
      _isSavedLoading = true;
      _savedErrorMessage = null;
      notifyListeners();

      _savedTrainings = await _service.getSavedTrainings(userId);
      _savedTrainingIds
        ..clear()
        ..addAll(_savedTrainings.map((training) => training.id));
    } catch (e) {
      _savedErrorMessage = 'Could not load saved resources.';
      debugPrint('fetchSavedTrainings error: $e');
    } finally {
      _isSavedLoading = false;
      notifyListeners();
    }
  }

  Future<String?> saveTraining({
    required String userId,
    required TrainingModel training,
  }) async {
    _busyTrainingIds.add(training.id);
    notifyListeners();

    try {
      await _service.saveTraining(userId: userId, training: training);

      _savedTrainingIds.add(training.id);
      _savedTrainings.removeWhere((item) => item.id == training.id);
      _savedTrainings.insert(0, training.copyWith(savedAt: Timestamp.now()));
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _busyTrainingIds.remove(training.id);
      notifyListeners();
    }
  }

  Future<String?> unsaveTraining({
    required String userId,
    required String trainingId,
  }) async {
    _busyTrainingIds.add(trainingId);
    notifyListeners();

    try {
      await _service.unsaveTraining(userId: userId, trainingId: trainingId);

      _savedTrainingIds.remove(trainingId);
      _savedTrainings.removeWhere((item) => item.id == trainingId);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _busyTrainingIds.remove(trainingId);
      notifyListeners();
    }
  }

  Future<String?> toggleSavedTraining({
    required String userId,
    required TrainingModel training,
  }) async {
    if (isTrainingSaved(training.id)) {
      return unsaveTraining(userId: userId, trainingId: training.id);
    }

    return saveTraining(userId: userId, training: training);
  }

  Future<bool> checkIfTrainingSaved({
    required String userId,
    required String trainingId,
  }) {
    return _service.isTrainingSaved(userId: userId, trainingId: trainingId);
  }

  Future<String?> deleteTraining(String trainingId) async {
    _busyTrainingIds.add(trainingId);
    notifyListeners();

    try {
      await _service.deleteTraining(trainingId);
      _trainings.removeWhere((training) => training.id == trainingId);
      _savedTrainingIds.remove(trainingId);
      _savedTrainings.removeWhere((training) => training.id == trainingId);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _busyTrainingIds.remove(trainingId);
      notifyListeners();
    }
  }

  Future<String?> updateFeaturedStatus({
    required String trainingId,
    required bool isFeatured,
  }) async {
    _busyTrainingIds.add(trainingId);
    notifyListeners();

    try {
      await _service.updateFeaturedStatus(
        trainingId: trainingId,
        isFeatured: isFeatured,
      );

      _trainings = _trainings
          .map(
            (training) => training.id == trainingId
                ? training.copyWith(isFeatured: isFeatured)
                : training,
          )
          .toList();

      _savedTrainings = _savedTrainings
          .map(
            (training) => training.id == trainingId
                ? training.copyWith(isFeatured: isFeatured)
                : training,
          )
          .toList();

      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _busyTrainingIds.remove(trainingId);
      notifyListeners();
    }
  }

  void clearSavedState() {
    _savedTrainings = <TrainingModel>[];
    _savedTrainingIds.clear();
    _busyTrainingIds.clear();
    _isSavedLoading = false;
    _savedErrorMessage = null;
    notifyListeners();
  }
}
