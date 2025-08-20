import 'package:flutter/foundation.dart';
import 'dart:async';
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

  // AGGRESSIVE CACHING to reduce Firebase reads
  static UserProfile? _cachedProfile;
  static UserGoal? _cachedGoal;
  static DateTime? _lastProfileCacheUpdate;
  static String? _lastCachedUserId;

  // Single stream controllers to prevent multiple Firebase listeners
  static StreamController<List<FoodLog>>? _todayFoodController;
  static StreamController<List<ActivityLog>>? _todayActivityController;
  static StreamController<List<WeightLog>>? _weightController;
  static StreamController<List<FoodLog>>? _recentFoodController;
  static StreamController<List<ActivityLog>>? _recentActivityController;

  // Cache refresh intervals
  static const Duration _profileCacheLife = Duration(minutes: 10);
  static const Duration _streamRefreshInterval = Duration(minutes: 3);

  bool get _useCloudStorage => _subscriptionService.canAccessCloudSync;

  // --- CACHE MANAGEMENT ---

  void _clearCache() {
    _cachedProfile = null;
    _cachedGoal = null;
    _lastProfileCacheUpdate = null;
    _lastCachedUserId = null;

    // Close existing controllers to prevent memory leaks
    _todayFoodController?.close();
    _todayFoodController = null;
    _todayActivityController?.close();
    _todayActivityController = null;
    _weightController?.close();
    _weightController = null;
    _recentFoodController?.close();
    _recentFoodController = null;
    _recentActivityController?.close();
    _recentActivityController = null;
  }

  bool _shouldRefreshProfileCache() {
    final currentUserId = _firebaseService.currentUser?.uid;

    // Clear cache if different user
    if (currentUserId != _lastCachedUserId) {
      _clearCache();
      _lastCachedUserId = currentUserId;
      return true;
    }

    // Refresh cache based on age
    if (_lastProfileCacheUpdate == null) return true;
    return DateTime.now().difference(_lastProfileCacheUpdate!).compareTo(_profileCacheLife) > 0;
  }

  // --- PROFILE & GOAL METHODS (HEAVILY CACHED) ---

  Future<UserProfile?> getUserProfile() async {
    if (_useCloudStorage) {
      // Use aggressive caching for Firebase
      if (_cachedProfile != null && !_shouldRefreshProfileCache()) {
        return _cachedProfile;
      }

      final profile = await _firebaseService.getUserProfile();
      if (profile != null) {
        _cachedProfile = profile;
        _lastProfileCacheUpdate = DateTime.now();
      }
      return profile;
    } else {
      return await _localService.getUserProfile();
    }
  }

  Future<UserGoal?> getUserGoal() async {
    if (_useCloudStorage) {
      // Use aggressive caching for Firebase
      if (_cachedGoal != null && !_shouldRefreshProfileCache()) {
        return _cachedGoal;
      }

      final goal = await _firebaseService.getUserGoal();
      if (goal != null) {
        _cachedGoal = goal;
        _lastProfileCacheUpdate = DateTime.now();
      }
      return goal;
    } else {
      return await _localService.getUserGoal();
    }
  }

  Future<void> saveUserProfileAndGoal(UserProfile profile, UserGoal goal) async {
    if (_useCloudStorage) {
      await _firebaseService.saveUserProfileAndGoal(profile, goal);
      // Update cache immediately
      _cachedProfile = profile;
      _cachedGoal = goal;
      _lastProfileCacheUpdate = DateTime.now();
    } else {
      await _localService.saveUserProfile(profile);
      await _localService.saveUserGoal(goal);
    }
    notifyListeners();
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

  // --- OPTIMIZED STREAM METHODS (SINGLE CONTROLLERS) ---

  Stream<List<FoodLog>> get todaysFoodLogStream {
    if (_useCloudStorage) {
      // Use single controller to prevent multiple Firebase listeners
      if (_todayFoodController != null && !_todayFoodController!.isClosed) {
        return _todayFoodController!.stream;
      }

      _todayFoodController = StreamController<List<FoodLog>>.broadcast();

      // Use the optimized Firebase stream directly (already filtered for today)
      _firebaseService.todaysFoodLogStream.listen(
            (logs) {
          if (!_todayFoodController!.isClosed) {
            _todayFoodController!.add(logs);
          }
        },
        onError: (error) {
          if (!_todayFoodController!.isClosed) {
            _todayFoodController!.addError(error);
          }
        },
      );

      return _todayFoodController!.stream;
    } else {
      // Reduce frequency for local storage
      return Stream.periodic(const Duration(seconds: 3), (_) async {
        return await _localService.getTodaysFoodLogs();
      }).asyncMap((future) => future).distinct();
    }
  }

  Stream<List<ActivityLog>> get todaysActivityLogStream {
    if (_useCloudStorage) {
      // Use single controller to prevent multiple Firebase listeners
      if (_todayActivityController != null && !_todayActivityController!.isClosed) {
        return _todayActivityController!.stream;
      }

      _todayActivityController = StreamController<List<ActivityLog>>.broadcast();

      // Use the optimized Firebase stream directly (already filtered for today)
      _firebaseService.todaysActivityLogStream.listen(
            (logs) {
          if (!_todayActivityController!.isClosed) {
            _todayActivityController!.add(logs);
          }
        },
        onError: (error) {
          if (!_todayActivityController!.isClosed) {
            _todayActivityController!.addError(error);
          }
        },
      );

      return _todayActivityController!.stream;
    } else {
      return Stream.periodic(const Duration(seconds: 3), (_) async {
        return await _localService.getTodaysActivityLogs();
      }).asyncMap((future) => future).distinct();
    }
  }

  // --- RECENT DATA (FOR PROGRESS SCREEN) - USE FUTURE INSTEAD OF STREAM ---

  Future<List<FoodLog>> getRecentFoodLogs() async {
    if (_useCloudStorage) {
      // Use one-time fetch instead of continuous stream
      return await _firebaseService.getRecentFoodLogs();
    } else {
      final maxDays = _subscriptionService.maxHistoryDays == -1 ? 365 : _subscriptionService.maxHistoryDays;
      return await _localService.getRecentFoodLogs(days: maxDays);
    }
  }

  Future<List<ActivityLog>> getRecentActivityLogs() async {
    if (_useCloudStorage) {
      // Use one-time fetch instead of continuous stream
      return await _firebaseService.getRecentActivityLogs();
    } else {
      final maxDays = _subscriptionService.maxHistoryDays == -1 ? 365 : _subscriptionService.maxHistoryDays;
      return await _localService.getRecentActivityLogs(days: maxDays);
    }
  }

  // Keep these as streams but optimize them
  Stream<List<FoodLog>> get recentFoodLogStream {
    if (_useCloudStorage) {
      // Use much less frequent updates for progress data
      return Stream.periodic(_streamRefreshInterval, (_) => getRecentFoodLogs())
          .asyncMap((future) => future);
    } else {
      return Stream.periodic(const Duration(seconds: 5), (_) async {
        final maxDays = _subscriptionService.maxHistoryDays == -1 ? 365 : _subscriptionService.maxHistoryDays;
        return await _localService.getRecentFoodLogs(days: maxDays);
      }).asyncMap((future) => future).distinct();
    }
  }

  Stream<List<ActivityLog>> get recentActivityLogStream {
    if (_useCloudStorage) {
      // Use much less frequent updates for progress data
      return Stream.periodic(_streamRefreshInterval, (_) => getRecentActivityLogs())
          .asyncMap((future) => future);
    } else {
      return Stream.periodic(const Duration(seconds: 5), (_) async {
        final maxDays = _subscriptionService.maxHistoryDays == -1 ? 365 : _subscriptionService.maxHistoryDays;
        return await _localService.getRecentActivityLogs(days: maxDays);
      }).asyncMap((future) => future).distinct();
    }
  }

  Stream<List<WeightLog>> get weightLogStream {
    if (_useCloudStorage) {
      // Use single controller to prevent multiple Firebase listeners
      if (_weightController != null && !_weightController!.isClosed) {
        return _weightController!.stream;
      }

      _weightController = StreamController<List<WeightLog>>.broadcast();

      // Use the optimized Firebase stream directly
      _firebaseService.weightLogStream.listen(
            (logs) {
          if (!_weightController!.isClosed) {
            _weightController!.add(logs);
          }
        },
        onError: (error) {
          if (!_weightController!.isClosed) {
            _weightController!.addError(error);
          }
        },
      );

      return _weightController!.stream;
    } else {
      return Stream.periodic(const Duration(seconds: 5), (_) async {
        final maxLogs = _subscriptionService.maxWeightLogs == -1 ? null : _subscriptionService.maxWeightLogs;
        return await _localService.getWeightLogs(limit: maxLogs);
      }).asyncMap((future) => future).distinct();
    }
  }

  Stream<List<FoodLog>> get frequentFoodLogStream {
    if (_useCloudStorage) {
      // Use optimized Firebase frequent streams (already cached and limited)
      return _firebaseService.frequentFoodLogStream;
    } else {
      return Stream.periodic(const Duration(seconds: 10), (_) async {
        return await _localService.getFrequentFoodLogs();
      }).asyncMap((future) => future).distinct();
    }
  }

  Stream<List<ActivityLog>> get frequentActivityLogStream {
    if (_useCloudStorage) {
      // Use optimized Firebase frequent streams (already cached and limited)
      return _firebaseService.frequentActivityLogStream;
    } else {
      return Stream.periodic(const Duration(seconds: 10), (_) async {
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

        // Update cache immediately
        _cachedProfile = profile;
        _cachedGoal = goal;
        _lastProfileCacheUpdate = DateTime.now();
      }

      // Migrate food logs (in batches to avoid overwhelming Firebase)
      final foodLogs = (localData['foodLogs'] as List? ?? [])
          .map((json) => FoodLog.fromJson(json, ''))
          .toList();

      for (int i = 0; i < foodLogs.length; i += 10) {
        final batch = foodLogs.skip(i).take(10);
        for (final log in batch) {
          await _firebaseService.addFoodLog(log);
        }
        // Small delay between batches to prevent rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Migrate activity logs (in batches)
      final activityLogs = (localData['activityLogs'] as List? ?? [])
          .map((json) => ActivityLog.fromJson(json, ''))
          .toList();

      for (int i = 0; i < activityLogs.length; i += 10) {
        final batch = activityLogs.skip(i).take(10);
        for (final log in batch) {
          await _firebaseService.addActivityLog(log);
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Migrate weight logs (in batches)
      final weightLogs = (localData['weightLogs'] as List? ?? [])
          .map((json) => WeightLog.fromJson(json, ''))
          .toList();

      for (int i = 0; i < weightLogs.length; i += 10) {
        final batch = weightLogs.skip(i).take(10);
        for (final log in batch) {
          await _firebaseService.addWeightLog(log);
        }
        await Future.delayed(const Duration(milliseconds: 100));
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
    _clearCache(); // Clear all caches on sign out

    if (_useCloudStorage) {
      await _firebaseService.signOut();
    } else {
      await _localService.clearAllData();
    }
    notifyListeners();
  }

  // --- SUBSCRIPTION CHANGE HANDLERS ---

  void onSubscriptionChanged() {
    _clearCache(); // Clear cache when subscription changes

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
    _clearCache();
    _localService.close();
    super.dispose();
  }
}