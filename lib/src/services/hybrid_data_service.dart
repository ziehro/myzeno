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
  // Set this to false in production
  static const bool _debugForcePremium = false; // Change this to false for production

  // Track storage state changes
  static bool? _lastCloudStorageState;

  // FIXED: Proper hybrid storage logic - but keep Firebase for auth users initially
  bool get _useCloudStorage {
    final currentUser = FirebaseAuth.instance.currentUser;
    final hasCloudAccess = _subscriptionService.canAccessCloudSync || _debugForcePremium;

    // IMPORTANT: If user is signed in, always use cloud storage initially
    // This prevents breaking existing users who have data in Firebase
    // Later we can add migration logic when they downgrade
    final useCloud = currentUser != null;

    print('HybridDataService: User signed in: ${currentUser != null}, Has cloud access: $hasCloudAccess, Using cloud: $useCloud');

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
    return DateTime.now().difference(_lastProfileCacheUpdate!).compareTo(_profileCacheLife) > 0;
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
          print('HybridDataService: Got profile from Firebase: ${profile.email}');
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
          print('HybridDataService: Got profile from local storage: ${profile.email}');
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
          print('HybridDataService: Got goal from Firebase: ${goal.lbsToLose} lbs in ${goal.days} days');
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
          print('HybridDataService: Got goal from local storage: ${goal.lbsToLose} lbs in ${goal.days} days');
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

  Future<void> saveUserProfileAndGoal(UserProfile profile, UserGoal goal) async {
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
    print('HybridDataService: Getting today\'s food log stream, useCloud: $_useCloudStorage');

    if (_useCloudStorage) {
      // Create a new stream each time to avoid shared controller issues
      return _firebaseService.todaysFoodLogStream
          .handleError((error) {
        print('HybridDataService: Error in food logs stream: $error');
        return <FoodLog>[];
      })
          .map((logs) {
        print('HybridDataService: Received ${logs.length} food logs from Firebase');
        return logs;
      });
    } else {
      print('HybridDataService: Using local storage for food logs');
      // Reduce frequency for local storage
      return Stream.periodic(const Duration(seconds: 3), (_) async {
        try {
          final logs = await _localService.getTodaysFoodLogs();
          print('HybridDataService: Got ${logs.length} food logs from local storage');
          return logs;
        } catch (e) {
          print('HybridDataService: Error getting local food logs: $e');
          return <FoodLog>[];
        }
      }).asyncMap((future) => future).distinct();
    }
  }

  Stream<List<ActivityLog>> get todaysActivityLogStream {
    print('HybridDataService: Getting today\'s activity log stream, useCloud: $_useCloudStorage');

    if (_useCloudStorage) {
      // Create a new stream each time to avoid shared controller issues
      return _firebaseService.todaysActivityLogStream
          .handleError((error) {
        print('HybridDataService: Error in activity logs stream: $error');
        return <ActivityLog>[];
      })
          .map((logs) {
        print('HybridDataService: Received ${logs.length} activity logs from Firebase');
        return logs;
      });
    } else {
      print('HybridDataService: Using local storage for activity logs');
      return Stream.periodic(const Duration(seconds: 3), (_) async {
        try {
          final logs = await _localService.getTodaysActivityLogs();
          print('HybridDataService: Got ${logs.length} activity logs from local storage');
          return logs;
        } catch (e) {
          print('HybridDataService: Error getting local activity logs: $e');
          return <ActivityLog>[];
        }
      }).asyncMap((future) => future).distinct();
    }
  }

  // --- WEIGHT STREAM METHODS ---

  Stream<List<WeightLog>> get weightLogStream {
    print('HybridDataService: Getting weight log stream, useCloud: $_useCloudStorage');

    if (_useCloudStorage) {
      // Use direct Firebase stream without intermediate controllers
      return _firebaseService.weightLogStream
          .handleError((error) {
        print('HybridDataService: Error in weight logs stream: $error');
        return <WeightLog>[];
      })
          .map((logs) {
        print('HybridDataService: Received ${logs.length} weight logs from Firebase');
        return logs;
      });
    } else {
      print('HybridDataService: Using local storage for weight logs');
      // Simpler local storage stream
      return Stream.periodic(const Duration(seconds: 2), (_) async {
        try {
          final maxLogs = _subscriptionService.maxWeightLogs == -1 ? null : _subscriptionService.maxWeightLogs;
          final logs = await _localService.getWeightLogs(limit: maxLogs);
          print('HybridDataService: Got ${logs.length} weight logs from local storage');
          return logs;
        } catch (e) {
          print('HybridDataService: Error getting local weight logs: $e');
          return <WeightLog>[];
        }
      }).asyncMap((future) => future).distinct();
    }
  }

  // Add this new method for more reliable weight log fetching:
  Future<List<WeightLog>> getWeightLogs() async {
    try {
      print('HybridDataService: Getting weight logs as Future, useCloud: $_useCloudStorage');

      if (_useCloudStorage) {
        // For cloud storage, get first emission from stream
        final logs = await _firebaseService.weightLogStream.first.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('HybridDataService: Weight logs timeout, returning empty list');
            return <WeightLog>[];
          },
        );
        print('HybridDataService: Got ${logs.length} weight logs from Firebase');
        return logs;
      } else {
        // For local storage, get directly
        final maxLogs = _subscriptionService.maxWeightLogs == -1 ? null : _subscriptionService.maxWeightLogs;
        final logs = await _localService.getWeightLogs(limit: maxLogs);
        print('HybridDataService: Got ${logs.length} weight logs from local storage');
        return logs;
      }
    } catch (e) {
      print('HybridDataService: Error getting weight logs: $e');
      return [];
    }
  }

  // --- RECENT DATA (FOR PROGRESS SCREEN) - USE FUTURE INSTEAD OF STREAM ---

  Future<List<FoodLog>> getRecentFoodLogs() async {
    try {
      print('HybridDataService: Getting recent food logs, useCloud: $_useCloudStorage');
      if (_useCloudStorage) {
        // Use one-time fetch instead of continuous stream
        final logs = await _firebaseService.getRecentFoodLogs();
        print('HybridDataService: Got ${logs.length} recent food logs from Firebase');
        return logs;
      } else {
        final maxDays = _subscriptionService.maxHistoryDays == -1 ? 365 : _subscriptionService.maxHistoryDays;
        final logs = await _localService.getRecentFoodLogs(days: maxDays);
        print('HybridDataService: Got ${logs.length} recent food logs from local storage');
        return logs;
      }
    } catch (e) {
      print('Error getting recent food logs: $e');
      return [];
    }
  }

  Future<List<ActivityLog>> getRecentActivityLogs() async {
    try {
      print('HybridDataService: Getting recent activity logs, useCloud: $_useCloudStorage');
      if (_useCloudStorage) {
        // Use one-time fetch instead of continuous stream
        final logs = await _firebaseService.getRecentActivityLogs();
        print('HybridDataService: Got ${logs.length} recent activity logs from Firebase');
        return logs;
      } else {
        final maxDays = _subscriptionService.maxHistoryDays == -1 ? 365 : _subscriptionService.maxHistoryDays;
        final logs = await _localService.getRecentActivityLogs(days: maxDays);
        print('HybridDataService: Got ${logs.length} recent activity logs from local storage');
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

  // --- DATA MIGRATION METHODS ---

  // ENHANCED: Handle subscription changes with data migration
  void onSubscriptionChanged() {
    final wasUsingCloud = _lastCloudStorageState ?? false;
    final nowUsingCloud = _useCloudStorage;

    print('HybridDataService: Subscription changed - Was using cloud: $wasUsingCloud, Now using cloud: $nowUsingCloud');

    _clearCache(); // Clear cache when subscription changes

    if (!wasUsingCloud && nowUsingCloud) {
      // User upgraded: Free → Premium
      print('HybridDataService: User upgraded to premium, migrating to cloud');
      _migrateLocalToCloud();
    } else if (wasUsingCloud && !nowUsingCloud) {
      // User downgraded: Premium → Free
      print('HybridDataService: User downgraded to free, migrating to local');
      _migrateCloudToLocal();
    }

    _lastCloudStorageState = nowUsingCloud;
    notifyListeners();
  }

  // ENHANCED: Migrate from local storage to cloud (upgrade)
  Future<void> _migrateLocalToCloud() async {
    try {
      print('HybridDataService: Starting migration from local to cloud');

      // Export all local data
      final localData = await _localService.exportAllData();

      if (localData['profile'] != null && localData['goal'] != null) {
        final profile = UserProfile.fromJson(localData['profile']);
        final goal = UserGoal.fromJson(localData['goal']);
        await _firebaseService.saveUserProfileAndGoal(profile, goal);

        // Update cache
        _cachedProfile = profile;
        _cachedGoal = goal;
        _lastProfileCacheUpdate = DateTime.now();

        print('HybridDataService: Migrated profile and goal to cloud');
      }

      // Migrate data in batches to avoid overwhelming Firebase
      await _migrateFoodLogsToCloud(localData);
      await _migrateActivityLogsToCloud(localData);
      await _migrateWeightLogsToCloud(localData);

      // Clear local data after successful migration
      await _localService.clearAllData();

      print('HybridDataService: Successfully migrated all data to cloud and cleared local storage');

      // Show success message
      _showMigrationSuccessMessage('Data successfully synced to cloud!');

    } catch (e) {
      print('HybridDataService: Error migrating to cloud: $e');
      _showMigrationErrorMessage('Failed to sync data to cloud. Please try again.');
    }
  }

  // NEW: Migrate from cloud storage to local (downgrade)
  Future<void> _migrateCloudToLocal() async {
    try {
      print('HybridDataService: Starting migration from cloud to local');

      // Get all data from Firebase
      final profile = await _firebaseService.getUserProfile();
      final goal = await _firebaseService.getUserGoal();
      final foodLogs = await _firebaseService.getRecentFoodLogs();
      final activityLogs = await _firebaseService.getRecentActivityLogs();
      final weightLogs = await _firebaseService.weightLogStream.first.timeout(
        const Duration(seconds: 10),
        onTimeout: () => <WeightLog>[],
      );

      // Save to local storage
      if (profile != null) {
        await _localService.saveUserProfile(profile);
        _cachedProfile = profile;
        print('HybridDataService: Migrated profile to local storage');
      }

      if (goal != null) {
        await _localService.saveUserGoal(goal);
        _cachedGoal = goal;
        print('HybridDataService: Migrated goal to local storage');
      }

      // Migrate logs in batches
      for (final log in foodLogs) {
        await _localService.addFoodLog(log);
      }
      print('HybridDataService: Migrated ${foodLogs.length} food logs to local storage');

      for (final log in activityLogs) {
        await _localService.addActivityLog(log);
      }
      print('HybridDataService: Migrated ${activityLogs.length} activity logs to local storage');

      for (final log in weightLogs) {
        await _localService.addWeightLog(log);
      }
      print('HybridDataService: Migrated ${weightLogs.length} weight logs to local storage');

      _lastProfileCacheUpdate = DateTime.now();

      print('HybridDataService: Successfully migrated all data to local storage');

      // Show success message
      _showMigrationSuccessMessage('Data downloaded and saved locally!');

    } catch (e) {
      print('HybridDataService: Error migrating to local: $e');
      _showMigrationErrorMessage('Failed to download data. Your cloud data is still safe.');
    }
  }

  // Helper methods for batch migration to cloud
  Future<void> _migrateFoodLogsToCloud(Map<String, dynamic> localData) async {
    final foodLogs = (localData['foodLogs'] as List? ?? [])
        .map((json) => FoodLog.fromJson(json, ''))
        .toList();

    for (int i = 0; i < foodLogs.length; i += 10) {
      final batch = foodLogs.skip(i).take(10);
      for (final log in batch) {
        await _firebaseService.addFoodLog(log);
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    print('HybridDataService: Migrated ${foodLogs.length} food logs to cloud');
  }

  Future<void> _migrateActivityLogsToCloud(Map<String, dynamic> localData) async {
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
    print('HybridDataService: Migrated ${activityLogs.length} activity logs to cloud');
  }

  Future<void> _migrateWeightLogsToCloud(Map<String, dynamic> localData) async {
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
    print('HybridDataService: Migrated ${weightLogs.length} weight logs to cloud');
  }

  // Helper methods for user feedback
  void _showMigrationSuccessMessage(String message) {
    // This would show a snackbar or notification to the user
    // You'd need to implement this based on your UI framework
    print('SUCCESS: $message');
  }

  void _showMigrationErrorMessage(String message) {
    // This would show an error dialog to the user
    // You'd need to implement this based on your UI framework
    print('ERROR: $message');
  }

  // LEGACY: Keep the old method for manual migration (if needed)
  Future<void> migrateToCloudStorage() async {
    if (!_subscriptionService.canAccessCloudSync) {
      throw Exception('Cloud sync not available in current plan');
    }
    await _migrateLocalToCloud();
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
          keepDays: _subscriptionService.maxHistoryDays == -1 ? 365 : _subscriptionService.maxHistoryDays,
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

  @override
  void dispose() {
    _clearCache();
    _localService.close();
    super.dispose();
  }
}