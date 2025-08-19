import 'package:flutter/foundation.dart';
import 'package:zeno/src/models/food_log.dart';
import 'package:zeno/src/models/activity_log.dart';
import 'package:zeno/src/models/weight_log.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/services/firebase_service.dart';
import 'package:zeno/src/services/local_storage_service.dart';
import 'package:zeno/src/services/subscription_service.dart';

class HybridDataService extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final LocalStorageService _localService = LocalStorageService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  bool get _useCloudStorage => _subscriptionService.canAccessCloudSync;

  // --- PROFILE & GOAL METHODS ---
  Future<UserProfile?> getUserProfile() async {
    if (_useCloudStorage) {
      return await _firebaseService.getUserProfile();
    } else {
      return await _localService.getUserProfile();
    }
  }

  Future<UserGoal?> getUserGoal() async {
    if (_useCloudStorage) {
      return await _firebaseService.getUserGoal();
    } else {
      return await _localService.getUserGoal();
    }
  }

  Future<void> saveUserProfileAndGoal(UserProfile profile, UserGoal goal) async {
    if (_useCloudStorage) {
      // Use existing Firebase method
      await _firebaseService.saveUserProfileAndGoal(profile, goal);
    } else {
      // Use local storage methods
      await _localService.saveUserProfile(profile);
      await _localService.saveUserGoal(goal);
    }
  }

  // --- FOOD LOG METHODS ---
  Future<void> addFoodLog(FoodLog log) async {
    if (_useCloudStorage) {
      await _firebaseService.addFoodLog(log);
    } else {
      await _localService.addFoodLog(log);
    }
    notifyListeners();
  }

  Future<void> updateFoodLog(FoodLog log) async {
    if (_useCloudStorage) {
      await _firebaseService.updateFoodLog(log);
    } else {
      await _localService.updateFoodLog(log);
    }
    notifyListeners();
  }

  Future<void> deleteFoodLog(String logId) async {
    if (_useCloudStorage) {
      await _firebaseService.deleteFoodLog(logId);
    } else {
      await _localService.deleteFoodLog(logId);
    }
    notifyListeners();
  }

  // --- ACTIVITY LOG METHODS ---
  Future<void> addActivityLog(ActivityLog log) async {
    if (_useCloudStorage) {
      await _firebaseService.addActivityLog(log);
    } else {
      await _localService.addActivityLog(log);
    }
    notifyListeners();
  }

  Future<void> updateActivityLog(ActivityLog log) async {
    if (_useCloudStorage) {
      await _firebaseService.updateActivityLog(log);
    } else {
      await _localService.updateActivityLog(log);
    }
    notifyListeners();
  }

  Future<void> deleteActivityLog(String logId) async {
    if (_useCloudStorage) {
      await _firebaseService.deleteActivityLog(logId);
    } else {
      await _localService.deleteActivityLog(logId);
    }
    notifyListeners();
  }

  // --- WEIGHT LOG METHODS ---
  Future<void> addWeightLog(WeightLog log) async {
    if (_useCloudStorage) {
      await _firebaseService.addWeightLog(log);
    } else {
      await _localService.addWeightLog(log);
    }
    notifyListeners();
  }

  // --- STREAM METHODS (with fallback for local) ---
  Stream<List<FoodLog>> get todaysFoodLogStream {
    if (_useCloudStorage) {
      // Use existing Firebase streams but filter for today
      return _firebaseService.foodLogStream.map((logs) {
        final today = DateTime.now();
        return logs.where((log) =>
        log.date.year == today.year &&
            log.date.month == today.month &&
            log.date.day == today.day
        ).toList();
      });
    } else {
      // For local storage, create a periodic stream
      return Stream.periodic(const Duration(seconds: 1), (_) async {
        return await _localService.getTodaysFoodLogs();
      }).asyncMap((future) => future).distinct();
    }
  }

  Stream<List<ActivityLog>> get todaysActivityLogStream {
    if (_useCloudStorage) {
      // Use existing Firebase streams but filter for today
      return _firebaseService.activityLogStream.map((logs) {
        final today = DateTime.now();
        return logs.where((log) =>
        log.date.year == today.year &&
            log.date.month == today.month &&
            log.date.day == today.day
        ).toList();
      });
    } else {
      return Stream.periodic(const Duration(seconds: 1), (_) async {
        return await _localService.getTodaysActivityLogs();
      }).asyncMap((future) => future).distinct();
    }
  }

  Stream<List<FoodLog>> get recentFoodLogStream {
    if (_useCloudStorage) {
      return _firebaseService.foodLogStream;
    } else {
      return Stream.periodic(const Duration(seconds: 2), (_) async {
        final maxDays = _subscriptionService.maxHistoryDays == -1 ? 365 : _subscriptionService.maxHistoryDays;
        return await _localService.getRecentFoodLogs(days: maxDays);
      }).asyncMap((future) => future).distinct();
    }
  }

  Stream<List<ActivityLog>> get recentActivityLogStream {
    if (_useCloudStorage) {
      return _firebaseService.activityLogStream;
    } else {
      return Stream.periodic(const Duration(seconds: 2), (_) async {
        final maxDays = _subscriptionService.maxHistoryDays == -1 ? 365 : _subscriptionService.maxHistoryDays;
        return await _localService.getRecentActivityLogs(days: maxDays);
      }).asyncMap((future) => future).distinct();
    }
  }

  Stream<List<WeightLog>> get weightLogStream {
    if (_useCloudStorage) {
      return _firebaseService.weightLogStream;
    } else {
      return Stream.periodic(const Duration(seconds: 2), (_) async {
        final maxLogs = _subscriptionService.maxWeightLogs == -1 ? null : _subscriptionService.maxWeightLogs;
        return await _localService.getWeightLogs(limit: maxLogs);
      }).asyncMap((future) => future).distinct();
    }
  }

  Stream<List<FoodLog>> get frequentFoodLogStream {
    if (_useCloudStorage) {
      return _firebaseService.frequentFoodLogStream;
    } else {
      return Stream.periodic(const Duration(seconds: 5), (_) async {
        return await _localService.getFrequentFoodLogs();
      }).asyncMap((future) => future).distinct();
    }
  }

  Stream<List<ActivityLog>> get frequentActivityLogStream {
    if (_useCloudStorage) {
      return _firebaseService.frequentActivityLogStream;
    } else {
      return Stream.periodic(const Duration(seconds: 5), (_) async {
        return await _localService.getFrequentActivityLogs();
      }).asyncMap((future) => future).distinct();
    }
  }

  // --- PREMIUM UPGRADE MIGRATION ---
  Future<void> migrateToCloudStorage() async {
    if (!_subscriptionService.canAccessCloudSync) {
      throw Exception('Cloud sync not available in current plan');
    }

    try {
      // Export all local data
      final localData = await _localService.exportAllData();

      // Save profile and goal to cloud using existing method
      if (localData['profile'] != null && localData['goal'] != null) {
        final profile = UserProfile.fromJson(localData['profile']);
        final goal = UserGoal.fromJson(localData['goal']);
        await _firebaseService.saveUserProfileAndGoal(profile, goal);
      }

      // Migrate food logs
      final foodLogs = (localData['foodLogs'] as List? ?? [])
          .map((json) => FoodLog.fromJson(json, ''))
          .toList();
      for (final log in foodLogs) {
        await _firebaseService.addFoodLog(log);
      }

      // Migrate activity logs
      final activityLogs = (localData['activityLogs'] as List? ?? [])
          .map((json) => ActivityLog.fromJson(json, ''))
          .toList();
      for (final log in activityLogs) {
        await _firebaseService.addActivityLog(log);
      }

      // Migrate weight logs
      final weightLogs = (localData['weightLogs'] as List? ?? [])
          .map((json) => WeightLog.fromJson(json, ''))
          .toList();
      for (final log in weightLogs) {
        await _firebaseService.addWeightLog(log);
      }

      // Clear local data after successful migration
      await _localService.clearAllData();

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to migrate data to cloud: $e');
    }
  }

  // --- DATA EXPORT (Premium feature) ---
  Future<Map<String, dynamic>> exportData() async {
    if (!_subscriptionService.canExportData) {
      throw Exception('Data export is a premium feature');
    }

    if (_useCloudStorage) {
      // For cloud storage, we'd need to fetch all data and export it
      // This is a simplified version - you'd want to implement proper cloud export
      throw UnimplementedError('Cloud data export not yet implemented');
    } else {
      return await _localService.exportAllData();
    }
  }

  // --- DATA MAINTENANCE ---
  Future<void> performMaintenance() async {
    if (!_useCloudStorage) {
      // Clean up old data for free users
      await _localService.cleanupOldData(
        keepDays: _subscriptionService.maxHistoryDays == -1 ? 365 : _subscriptionService.maxHistoryDays,
      );
    }
  }

  // --- AUTH METHODS ---
  Future<void> signOut() async {
    if (_useCloudStorage) {
      await _firebaseService.signOut();
    } else {
      // For local storage, just clear data
      await _localService.clearAllData();
    }
    notifyListeners();
  }

  // --- SUBSCRIPTION CHANGE HANDLERS ---
  void onSubscriptionChanged() {
    if (_subscriptionService.canAccessCloudSync) {
      // User upgraded to premium - offer to migrate data
      _showMigrationDialog();
    } else {
      // User downgraded - data stays in cloud but app uses local storage
    }
    notifyListeners();
  }

  void _showMigrationDialog() {
    // Auto-migration for now
    migrateToCloudStorage().catchError((e) {
      debugPrint('Auto-migration failed: $e');
    });
  }

  @override
  void dispose() {
    _localService.close();
    super.dispose();
  }
}