import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
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

  // For development: Allow override to test premium features
  // Set this to true to test as premium user
  static const bool _debugForcePremium = true; // Change this to test premium features

  // For now, always use cloud storage when user is signed in (regardless of subscription)
  // This ensures that Firebase auth users get their data from Firebase
  bool get _useCloudStorage {
    final currentUser = FirebaseAuth.instance.currentUser;
    final hasCloudAccess = _subscriptionService.canAccessCloudSync ||
        _debugForcePremium;

    // Use cloud storage if user is signed in (even free users need Firebase for auth)
    final useCloud = currentUser != null;

    print('HybridDataService: User signed in: ${currentUser !=
        null}, Has cloud access: $hasCloudAccess, Debug force premium: $_debugForcePremium, Using cloud: $useCloud');

    return useCloud;
  }

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
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Clear cache if different user
    if (currentUserId != _lastCachedUserId) {
      _clearCache();
      _lastCachedUserId = currentUserId;
      return true;
    }

    // Refresh cache based on age
    if (_lastProfileCacheUpdate == null) return true;
    return DateTime.now().difference(_lastProfileCacheUpdate!).compareTo(
        _profileCacheLife) > 0;
  }

  // --- PROFILE & GOAL METHODS (HEAVILY CACHED) ---

  Future<UserProfile?> getUserProfile() async {
    // Check if user is signed in first
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('HybridDataService: No user logged in');
      return null;
    }

    print('HybridDataService: Getting profile for user ${currentUser.uid}');

    if (_useCloudStorage) {
      print('HybridDataService: Using cloud storage');
      // Use aggressive caching for Firebase
      if (_cachedProfile != null && !_shouldRefreshProfileCache()) {
        print('HybridDataService: Returning cached profile');
        return _cachedProfile;
      }

      try {
        final profile = await _firebaseService.getUserProfile();
        if (profile != null) {
          print(
              'HybridDataService: Got profile from Firebase: ${profile.email}');
          _cachedProfile = profile;
          _lastProfileCacheUpdate = DateTime.now();
        } else {
          print('HybridDataService: No profile found in Firebase');
        }
        return profile;
      } catch (e) {
        print('Error getting profile from Firebase: $e');
        return null;
      }
    } else {
      print('HybridDataService: Using local storage');
      try {
        final profile = await _localService.getUserProfile();
        if (profile != null) {
          print('HybridDataService: Got profile from local storage: ${profile
              .email}');
        } else {
          print('HybridDataService: No profile found in local storage');
        }
        return profile;
      } catch (e) {
        print('Error getting profile from local storage: $e');
        return null;
      }
    }
  }

  Future<UserGoal?> getUserGoal() async {
    // Check if user is signed in first
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('HybridDataService: No user logged in for goal');
      return null;
    }

    print('HybridDataService: Getting goal for user ${currentUser.uid}');

    if (_useCloudStorage) {
      print('HybridDataService: Using cloud storage for goal');
      // Use aggressive caching for Firebase
      if (_cachedGoal != null && !_shouldRefreshProfileCache()) {
        print('HybridDataService: Returning cached goal');
        return _cachedGoal;
      }

      try {
        final goal = await _firebaseService.getUserGoal();
        if (goal != null) {
          print('HybridDataService: Got goal from Firebase: ${goal
              .lbsToLose} lbs in ${goal.days} days');
          _cachedGoal = goal;
          _lastProfileCacheUpdate = DateTime.now();
        } else {
          print('HybridDataService: No goal found in Firebase');
        }
        return goal;
      } catch (e) {
        print('Error getting goal from Firebase: $e');
        return null;
      }
    } else {
      print('HybridDataService: Using local storage for goal');
      try {
        final goal = await _localService.getUserGoal();
        if (goal != null) {
          print('HybridDataService: Got goal from local storage: ${goal
              .lbsToLose} lbs in ${goal.days} days');
        } else {
          print('HybridDataService: No goal found in local storage');
        }
        return goal;
      } catch (e) {
        print('Error getting goal from local storage: $e');
        return null;
      }
    }
  }

  Future<void> saveUserProfileAndGoal(UserProfile profile,
      UserGoal goal) async {
    try {
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
    } catch (e) {
      print('Error saving profile and goal: $e');
      rethrow;
    }
  }

  // --- FOOD LOG METHODS ---

  Future<void> addFoodLog(FoodLog log) async {
    try {
      if (_useCloudStorage) {
        await _firebaseService.addFoodLog(log);
      } else {
        await _localService.addFoodLog(log);
      }
      notifyListeners();
    } catch (e) {
      print('Error adding food log: $e');
      rethrow;
    }
  }

  Future<void> updateFoodLog(FoodLog log) async {
    try {
      if (_useCloudStorage) {
        await _firebaseService.updateFoodLog(log);
      } else {
        await _localService.updateFoodLog(log);
      }
      notifyListeners();
    } catch (e) {
      print('Error updating food log: $e');
      rethrow;
    }
  }

  Future<void> deleteFoodLog(String logId) async {
    try {
      if (_useCloudStorage) {
        await _firebaseService.deleteFoodLog(logId);
      } else {
        await _localService.deleteFoodLog(logId);
      }
      notifyListeners();
    } catch (e) {
      print('Error deleting food log: $e');
      rethrow;
    }
  }

  // --- ACTIVITY LOG METHODS ---

  Future<void> addActivityLog(ActivityLog log) async {
    try {
      if (_useCloudStorage) {
        await _firebaseService.addActivityLog(log);
      } else {
        await _localService.addActivityLog(log);
      }
      notifyListeners();
    } catch (e) {
      print('Error adding activity log: $e');
      rethrow;
    }
  }

  Future<void> updateActivityLog(ActivityLog log) async {
    try {
      if (_useCloudStorage) {
        await _firebaseService.updateActivityLog(log);
      } else {
        await _localService.updateActivityLog(log);
      }
      notifyListeners();
    } catch (e) {
      print('Error updating activity log: $e');
      rethrow;
    }
  }

  Future<void> deleteActivityLog(String logId) async {
    try {
      if (_useCloudStorage) {
        await _firebaseService.deleteActivityLog(logId);
      } else {
        await _localService.deleteActivityLog(logId);
      }
      notifyListeners();
    } catch (e) {
      print('Error deleting activity log: $e');
      rethrow;
    }
  }

  // --- WEIGHT LOG METHODS ---

  Future<void> addWeightLog(WeightLog log) async {
    try {
      if (_useCloudStorage) {
        await _firebaseService.addWeightLog(log);
      } else {
        await _localService.addWeightLog(log);
      }
      notifyListeners();
    } catch (e) {
      print('Error adding weight log: $e');
      rethrow;
    }
  }

  // --- OPTIMIZED STREAM METHODS (SINGLE CONTROLLERS) ---

  Stream<List<FoodLog>> get todaysFoodLogStream {
    print(
        'HybridDataService: Getting today\'s food log stream, useCloud: $_useCloudStorage');

    if (_useCloudStorage) {
      // Create a new stream each time to avoid shared controller issues
      return _firebaseService.todaysFoodLogStream
          .handleError((error) {
        print('HybridDataService: Error in food logs stream: $error');
        return <FoodLog>[];
      })
          .map((logs) {
        print('HybridDataService: Received ${logs
            .length} food logs from Firebase');
        return logs;
      });
    } else {
      print('HybridDataService: Using local storage for food logs');
      // Reduce frequency for local storage
      return Stream.periodic(const Duration(seconds: 3), (_) async {
        try {
          final logs = await _localService.getTodaysFoodLogs();
          print('HybridDataService: Got ${logs
              .length} food logs from local storage');
          return logs;
        } catch (e) {
          print('HybridDataService: Error getting local food logs: $e');
          return <FoodLog>[];
        }
      }).asyncMap((future) => future).distinct();
    }
  }

  Stream<List<ActivityLog>> get todaysActivityLogStream {
    print(
        'HybridDataService: Getting today\'s activity log stream, useCloud: $_useCloudStorage');

    if (_useCloudStorage) {
      // Create a new stream each time to avoid shared controller issues
      return _firebaseService.todaysActivityLogStream
          .handleError((error) {
        print('HybridDataService: Error in activity logs stream: $error');
        return <ActivityLog>[];
      })
          .map((logs) {
        print('HybridDataService: Received ${logs
            .length} activity logs from Firebase');
        return logs;
      });
    } else {
      print('HybridDataService: Using local storage for activity logs');
      return Stream.periodic(const Duration(seconds: 3), (_) async {
        try {
          final logs = await _localService.getTodaysActivityLogs();
          print('HybridDataService: Got ${logs
              .length} activity logs from local storage');
          return logs;
        } catch (e) {
          print('HybridDataService: Error getting local activity logs: $e');
          return <ActivityLog>[];
        }
      }).asyncMap((future) => future).distinct();
    }
  }

  // --- RECENT DATA (FOR PROGRESS SCREEN) - USE FUTURE INSTEAD OF STREAM ---

  Future<List<FoodLog>> getRecentFoodLogs() async {
    try {
      print(
          'HybridDataService: Getting recent food logs, useCloud: $_useCloudStorage');
      if (_useCloudStorage) {
        // Use one-time fetch instead of continuous stream
        final logs = await _firebaseService.getRecentFoodLogs();
        print('HybridDataService: Got ${logs
            .length} recent food logs from Firebase');
        return logs;
      } else {
        final maxDays = _subscriptionService.maxHistoryDays == -1
            ? 365
            : _subscriptionService.maxHistoryDays;
        final logs = await _localService.getRecentFoodLogs(days: maxDays);
        print('HybridDataService: Got ${logs
            .length} recent food logs from local storage');
        return logs;
      }
    } catch (e) {
      print('Error getting recent food logs: $e');
      return [];
    }
  }

  Future<List<ActivityLog>> getRecentActivityLogs() async {
    try {
      print(
          'HybridDataService: Getting recent activity logs, useCloud: $_useCloudStorage');
      if (_useCloudStorage) {
        // Use one-time fetch instead of continuous stream
        final logs = await _firebaseService.getRecentActivityLogs();
        print('HybridDataService: Got ${logs
            .length} recent activity logs from Firebase');
        return logs;
      } else {
        final maxDays = _subscriptionService.maxHistoryDays == -1
            ? 365
            : _subscriptionService.maxHistoryDays;
        final logs = await _localService.getRecentActivityLogs(days: maxDays);
        print('HybridDataService: Got ${logs
            .length} recent activity logs from local storage');
        return logs;
      }
    } catch (e) {
      print('Error getting recent activity logs: $e');
      return [];
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
        final maxDays = _subscriptionService.maxHistoryDays == -1
            ? 365
            : _subscriptionService.maxHistoryDays;
        return await _localService.getRecentFoodLogs(days: maxDays);
      }).asyncMap((future) => future).distinct();
    }
  }

  Stream<List<ActivityLog>> get recentActivityLogStream {
    if (_useCloudStorage) {
      // Use much less frequent updates for progress data
      return Stream.periodic(
          _streamRefreshInterval, (_) => getRecentActivityLogs())
          .asyncMap((future) => future);
    } else {
      return Stream.periodic(const Duration(seconds: 5), (_) async {
        final maxDays = _subscriptionService.maxHistoryDays == -1
            ? 365
            : _subscriptionService.maxHistoryDays;
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
        final maxLogs = _subscriptionService.maxWeightLogs == -1
            ? null
            : _subscriptionService.maxWeightLogs;
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
    try {
      if (!_useCloudStorage) {
        // Clean up old data for free users
        await _localService.cleanupOldData(
          keepDays: _subscriptionService.maxHistoryDays == -1
              ? 365
              : _subscriptionService.maxHistoryDays,
        );
      }
    } catch (e) {
      print('Error performing maintenance: $e');
    }
  }

  // --- AUTH METHODS ---

  Future<void> signOut() async {
    try {
      _clearCache(); // Clear all caches on sign out

      if (_useCloudStorage) {
        await _firebaseService.signOut();
      } else {
        await _localService.clearAllData();
      }

      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
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