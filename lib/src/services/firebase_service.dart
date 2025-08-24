import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zeno/src/models/activity_log.dart';
import 'package:zeno/src/models/food_log.dart';
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/models/weight_log.dart';
import 'package:zeno/src/models/tip.dart';
import 'package:zeno/src/models/recipe.dart';
import 'dart:async';
import 'package:zeno/src/services/subscription_service.dart';
import 'package:zeno/src/models/alcohol_entry.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // AGGRESSIVE CACHING - Only refresh when absolutely necessary
  static UserProfile? _cachedProfile;
  static UserGoal? _cachedGoal;
  static List<FoodLog>? _cachedTodayFood;
  static List<ActivityLog>? _cachedTodayActivity;
  static List<WeightLog>? _cachedWeightLogs;
  static DateTime? _lastCacheUpdate;
  static String? _lastCachedUserId;

  // Single controllers for each data type (prevent multiple listeners)
  static StreamController<List<FoodLog>>? _todayFoodController;
  static StreamController<List<ActivityLog>>? _todayActivityController;
  static StreamController<List<WeightLog>>? _weightController;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Reference to the current user's document
  DocumentReference<Map<String, dynamic>>? get _userDocRef {
    final user = currentUser;
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid);
  }

  // --- CACHE MANAGEMENT ---
  void _clearCache() {
    _cachedProfile = null;
    _cachedGoal = null;
    _cachedTodayFood = null;
    _cachedTodayActivity = null;
    _cachedWeightLogs = null;
    _lastCacheUpdate = null;
    _lastCachedUserId = null;

    // Close existing controllers
    _todayFoodController?.close();
    _todayFoodController = null;
    _todayActivityController?.close();
    _todayActivityController = null;
    _weightController?.close();
    _weightController = null;
  }

  bool _shouldRefreshCache() {
    final currentUserId = currentUser?.uid;

    // Clear cache if different user
    if (currentUserId != _lastCachedUserId) {
      _clearCache();
      _lastCachedUserId = currentUserId;
      return true;
    }

    // Refresh cache every 5 minutes MAX
    if (_lastCacheUpdate == null) return true;
    return DateTime.now().difference(_lastCacheUpdate!).inMinutes > 5;
  }

  // --- AUTH METHODS ---
  Future<UserCredential> signUp(String email, String password) async {
    try {
      _clearCache(); // Clear cache on auth change
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print('Error signing up: $e');
      rethrow;
    }
  }

  Future<UserCredential> signIn(String email, String password) async {
    try {
      _clearCache(); // Clear cache on auth change
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      _clearCache(); // Clear cache on sign out
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // --- PROFILE & GOAL METHODS (HEAVILY CACHED) ---

  Future<bool> checkIfUserProfileExists() async {
    final userDoc = _userDocRef;
    if (userDoc == null) return false;

    try {
      // Check both profile and goal exist
      final profileDoc = await userDoc.get();
      final goalDoc = await userDoc.collection('goals').doc('main_goal').get();

      final profileExists = profileDoc.exists && profileDoc.data() != null;
      final goalExists = goalDoc.exists && goalDoc.data() != null;

      print('Profile exists: $profileExists, Goal exists: $goalExists');

      // Cache the profile if it exists
      if (profileExists) {
        _cachedProfile = UserProfile.fromJson(profileDoc.data()!);
        _lastCacheUpdate = DateTime.now();
      }

      // Cache the goal if it exists
      if (goalExists) {
        _cachedGoal = UserGoal.fromJson(goalDoc.data()!);
        _lastCacheUpdate = DateTime.now();
      }

      // Both must exist for complete setup
      return profileExists && goalExists;
    } catch (e) {
      print('Error checking if user profile exists: $e');
      return false;
    }
  }

  Future<void> saveUserProfileAndGoal(UserProfile profile, UserGoal goal) async {
    final userDoc = _userDocRef;
    if (userDoc == null) throw Exception("User not logged in");

    try {
      // Save to Firebase
      await userDoc.set(profile.toJson());
      await userDoc.collection('goals').doc('main_goal').set(goal.toJson());

      // Update cache immediately
      _cachedProfile = profile;
      _cachedGoal = goal;
      _lastCacheUpdate = DateTime.now();
    } catch (e) {
      print('Error saving user profile and goal: $e');
      rethrow;
    }
  }

  Future<UserProfile?> getUserProfile() async {
    // Check if user is logged in
    if (currentUser == null) {
      print('No user logged in');
      return null;
    }

    // Return cached version if available and fresh
    if (_cachedProfile != null && !_shouldRefreshCache()) {
      return _cachedProfile;
    }

    final userDoc = _userDocRef;
    if (userDoc == null) return null;

    try {
      final snapshot = await userDoc.get();
      if (snapshot.exists && snapshot.data() != null) {
        _cachedProfile = UserProfile.fromJson(snapshot.data()!);
        _lastCacheUpdate = DateTime.now();
        return _cachedProfile;
      } else {
        print('User profile document does not exist');
        return null;
      }
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<UserGoal?> getUserGoal() async {
    // Check if user is logged in
    if (currentUser == null) {
      print('No user logged in');
      return null;
    }

    // Return cached version if available and fresh
    if (_cachedGoal != null && !_shouldRefreshCache()) {
      return _cachedGoal;
    }

    final userDoc = _userDocRef;
    if (userDoc == null) return null;

    try {
      final snapshot = await userDoc.collection('goals').doc('main_goal').get();
      if (snapshot.exists && snapshot.data() != null) {
        _cachedGoal = UserGoal.fromJson(snapshot.data()!);
        _lastCacheUpdate = DateTime.now();
        return _cachedGoal;
      } else {
        print('User goal document does not exist');
        return null;
      }
    } catch (e) {
      print('Error getting user goal: $e');
      return null;
    }
  }

  // --- TODAY'S DATA STREAMS (SINGLE SOURCE OF TRUTH) ---

  Stream<List<FoodLog>> get todaysFoodLogStream {
    final userDoc = _userDocRef;
    if (userDoc == null) {
      print('FirebaseService: No user document reference, returning empty stream');
      return Stream.value([]);
    }

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    print('FirebaseService: Creating direct food logs stream for ${startOfDay.toIso8601String()}');

    return userDoc.collection('food_logs')
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('date', isLessThan: endOfDay.toIso8601String())
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      try {
        print('FirebaseService: Processing ${snapshot.docs.length} food log documents');
        final logs = snapshot.docs.map((doc) {
          try {
            return FoodLog.fromJson(doc.data(), doc.id);
          } catch (e) {
            print('FirebaseService: Error parsing food log ${doc.id}: $e');
            return null;
          }
        }).where((log) => log != null).cast<FoodLog>().toList();

        print('FirebaseService: Successfully parsed ${logs.length} food logs');
        return logs;
      } catch (e) {
        print('FirebaseService: Error processing food logs: $e');
        return <FoodLog>[];
      }
    })
        .handleError((error) {
      print('FirebaseService: Error in food logs stream: $error');
      return <FoodLog>[];
    });
  }

  Stream<List<ActivityLog>> get todaysActivityLogStream {
    final userDoc = _userDocRef;
    if (userDoc == null) {
      print('FirebaseService: No user document reference, returning empty stream');
      return Stream.value([]);
    }

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    print('FirebaseService: Creating direct activity logs stream for ${startOfDay.toIso8601String()}');

    return userDoc.collection('activity_logs')
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('date', isLessThan: endOfDay.toIso8601String())
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      try {
        print('FirebaseService: Processing ${snapshot.docs.length} activity log documents');
        final logs = snapshot.docs.map((doc) {
          try {
            return ActivityLog.fromJson(doc.data(), doc.id);
          } catch (e) {
            print('FirebaseService: Error parsing activity log ${doc.id}: $e');
            return null;
          }
        }).where((log) => log != null).cast<ActivityLog>().toList();

        print('FirebaseService: Successfully parsed ${logs.length} activity logs');
        return logs;
      } catch (e) {
        print('FirebaseService: Error processing activity logs: $e');
        return <ActivityLog>[];
      }
    })
        .handleError((error) {
      print('FirebaseService: Error in activity logs stream: $error');
      return <ActivityLog>[];
    });
  }

  // --- WEIGHT LOGS (CACHED & LIMITED) ---


  Stream<List<WeightLog>> get weightLogStream {
    final userDoc = _userDocRef;
    if (userDoc == null) {
      print('FirebaseService: No user document reference for weight logs');
      return Stream.value([]);
    }

    print('FirebaseService: Creating direct weight logs stream');

    // Use direct Firebase stream instead of complex controller logic
    return userDoc.collection('weight_logs')
        .orderBy('date', descending: true)
        .limit(50) // Reasonable limit for performance
        .snapshots()
        .map((snapshot) {
      try {
        print('FirebaseService: Processing ${snapshot.docs.length} weight log documents');
        final logs = snapshot.docs.map((doc) {
          try {
            return WeightLog.fromJson(doc.data(), doc.id);
          } catch (e) {
            print('FirebaseService: Error parsing weight log ${doc.id}: $e');
            return null;
          }
        }).where((log) => log != null).cast<WeightLog>().toList();

        print('FirebaseService: Successfully parsed ${logs.length} weight logs');
        // Update cache for other methods that need it
        _cachedWeightLogs = logs;
        return logs;
      } catch (e) {
        print('FirebaseService: Error processing weight logs: $e');
        return <WeightLog>[];
      }
    })
        .handleError((error) {
      print('FirebaseService: Error in weight logs stream: $error');
      return <WeightLog>[];
    });
  }

  // --- PROGRESS DATA (STATIC QUERIES) ---

  Future<List<FoodLog>> getRecentFoodLogs() async {
    final userDoc = _userDocRef;
    if (userDoc == null) {
      print('FirebaseService: No user document for recent food logs');
      return [];
    }

    try {
      // Get last 30 days for progress (increased from 14)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      print('FirebaseService: Querying recent food logs from ${thirtyDaysAgo.toIso8601String()}');

      final snapshot = await userDoc.collection('food_logs')
          .where('date', isGreaterThanOrEqualTo: thirtyDaysAgo.toIso8601String())
          .orderBy('date', descending: true)
          .limit(200) // Increased limit
          .get();

      final logs = snapshot.docs.map((doc) {
        try {
          return FoodLog.fromJson(doc.data(), doc.id);
        } catch (e) {
          print('FirebaseService: Error parsing recent food log ${doc.id}: $e');
          return null;
        }
      }).where((log) => log != null).cast<FoodLog>().toList();

      print('FirebaseService: Retrieved ${logs.length} recent food logs');
      return logs;
    } catch (e) {
      print('Error getting recent food logs: $e');
      return [];
    }
  }

  Future<List<ActivityLog>> getRecentActivityLogs() async {
    final userDoc = _userDocRef;
    if (userDoc == null) {
      print('FirebaseService: No user document for recent activity logs');
      return [];
    }

    try {
      // Get last 30 days for progress (increased from 14)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      print('FirebaseService: Querying recent activity logs from ${thirtyDaysAgo.toIso8601String()}');

      final snapshot = await userDoc.collection('activity_logs')
          .where('date', isGreaterThanOrEqualTo: thirtyDaysAgo.toIso8601String())
          .orderBy('date', descending: true)
          .limit(200) // Increased limit
          .get();

      final logs = snapshot.docs.map((doc) {
        try {
          return ActivityLog.fromJson(doc.data(), doc.id);
        } catch (e) {
          print('FirebaseService: Error parsing recent activity log ${doc.id}: $e');
          return null;
        }
      }).where((log) => log != null).cast<ActivityLog>().toList();

      print('FirebaseService: Retrieved ${logs.length} recent activity logs');
      return logs;
    } catch (e) {
      print('Error getting recent activity logs: $e');
      return [];
    }
  }

  // Use these for progress screen instead of streams
  Stream<List<FoodLog>> get recentFoodLogStream async* {
    yield await getRecentFoodLogs();
  }

  Stream<List<ActivityLog>> get recentActivityLogStream async* {
    yield await getRecentActivityLogs();
  }

  // --- FREQUENT ITEMS (MUCH LESS FREQUENT UPDATES) ---

  Stream<List<FoodLog>> get frequentFoodLogStream {
    final userDoc = _userDocRef;
    if (userDoc == null) return Stream.value([]);

    // Get subscription service to check limits
    final subscriptionService = SubscriptionService();
    final limit = subscriptionService.isPremium ? 50 : 8; // Premium gets 50, free gets 8

    return userDoc.collection('frequent_food_logs')
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FoodLog.fromJson(doc.data(), doc.id)).toList())
        .handleError((error) {
      print('Error in frequent food logs stream: $error');
      return <FoodLog>[];
    });
  }

  Stream<List<ActivityLog>> get frequentActivityLogStream {
    final userDoc = _userDocRef;
    if (userDoc == null) return Stream.value([]);

    // Get subscription service to check limits
    final subscriptionService = SubscriptionService();
    final limit = subscriptionService.isPremium ? 50 : 8; // Premium gets 50, free gets 8

    return userDoc.collection('frequent_activity_logs')
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ActivityLog.fromJson(doc.data(), doc.id)).toList())
        .handleError((error) {
      print('Error in frequent activity logs stream: $error');
      return <ActivityLog>[];
    });
  }

  // --- TIPS & RECIPES (GLOBAL DATA - CACHE HEAVILY) ---

  static List<Tip>? _cachedTips;
  static List<Recipe>? _cachedRecipes;
  static DateTime? _lastGlobalCacheUpdate;

  Stream<List<Tip>> get tipsStream async* {
    // Use cache for global data
    if (_cachedTips != null && _lastGlobalCacheUpdate != null &&
        DateTime.now().difference(_lastGlobalCacheUpdate!).inHours < 1) {
      yield _cachedTips!;
      return;
    }

    try {
      final snapshot = await _firestore.collection('tips').limit(15).get();
      _cachedTips = snapshot.docs.map((d) => Tip.fromFirestore(d)).toList();
      _lastGlobalCacheUpdate = DateTime.now();
      yield _cachedTips!;
    } catch (e) {
      print('Error getting tips: $e');
      yield [];
    }
  }

  Stream<List<Recipe>> get recipesStream async* {
    // Use cache for global data
    if (_cachedRecipes != null && _lastGlobalCacheUpdate != null &&
        DateTime.now().difference(_lastGlobalCacheUpdate!).inHours < 1) {
      yield _cachedRecipes!;
      return;
    }

    try {
      final snapshot = await _firestore.collection('recipes').limit(15).get();
      _cachedRecipes = snapshot.docs.map((d) => Recipe.fromFirestore(d)).toList();
      _lastGlobalCacheUpdate = DateTime.now();
      yield _cachedRecipes!;
    } catch (e) {
      print('Error getting recipes: $e');
      yield [];
    }
  }

  // --- CRUD OPERATIONS (OPTIMIZED) ---

  Future<void> addFoodLog(FoodLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) throw Exception("User not logged in");

    try {
      await userDoc.collection('food_logs').add(log.toJson());

      // Update frequent logs only every 10th addition
      if (DateTime.now().second % 10 == 0) {
        await addFrequentFoodLog(log);
      }
    } catch (e) {
      print('Error adding food log: $e');
      rethrow;
    }
  }

  Future<void> addActivityLog(ActivityLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) throw Exception("User not logged in");

    try {
      await userDoc.collection('activity_logs').add(log.toJson());

      // Update frequent logs only every 10th addition
      if (DateTime.now().second % 10 == 0) {
        await addFrequentActivityLog(log);
      }
    } catch (e) {
      print('Error adding activity log: $e');
      rethrow;
    }
  }

  Future<void> addWeightLog(WeightLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) throw Exception("User not logged in");

    try {
      await userDoc.collection('weight_logs').add(log.toJson());
    } catch (e) {
      print('Error adding weight log: $e');
      rethrow;
    }
  }

  Future<void> updateFoodLog(FoodLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) throw Exception("User not logged in");

    try {
      await userDoc.collection('food_logs').doc(log.id).update(log.toJson());
    } catch (e) {
      print('Error updating food log: $e');
      rethrow;
    }
  }

  Future<void> updateActivityLog(ActivityLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) throw Exception("User not logged in");

    try {
      await userDoc.collection('activity_logs').doc(log.id).update(log.toJson());
    } catch (e) {
      print('Error updating activity log: $e');
      rethrow;
    }
  }

  Future<void> deleteFoodLog(String logId) async {
    final userDoc = _userDocRef;
    if (userDoc == null) throw Exception("User not logged in");

    try {
      await userDoc.collection('food_logs').doc(logId).delete();
    } catch (e) {
      print('Error deleting food log: $e');
      rethrow;
    }
  }

  Future<void> deleteActivityLog(String logId) async {
    final userDoc = _userDocRef;
    if (userDoc == null) throw Exception("User not logged in");

    try {
      await userDoc.collection('activity_logs').doc(logId).delete();
    } catch (e) {
      print('Error deleting activity log: $e');
      rethrow;
    }
  }

  // --- FREQUENT LISTS (MINIMAL UPDATES) ---

  Future<void> addFrequentFoodLog(FoodLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) return;

    try {
      await userDoc.collection('frequent_food_logs').doc(log.name).set(log.toJson());
    } catch (e) {
      print('Error adding frequent food log: $e');
      // Don't rethrow - this is not critical
    }
  }

  Future<void> addFrequentActivityLog(ActivityLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) return;

    try {
      await userDoc.collection('frequent_activity_logs').doc(log.name).set(log.toJson());
    } catch (e) {
      print('Error adding frequent activity log: $e');
      // Don't rethrow - this is not critical
    }
  }

  Future<void> addTip(Tip tip) async {
    try {
      await _firestore.collection('tips').add(tip.toFirestore());
    } catch (e) {
      print('Error adding tip: $e');
      rethrow;
    }
  }

  Future<void> addRecipe(Recipe recipe) async {
    try {
      await _firestore.collection('recipes').add(recipe.toFirestore());
    } catch (e) {
      print('Error adding recipe: $e');
      rethrow;
    }
  }

  Future<void> addAlcoholEntry(AlcoholEntry entry) async {
    final userDoc = _userDocRef;
    if (userDoc == null) throw Exception("User not logged in");

    try {
      await userDoc.collection('alcohol_entries').add(entry.toJson());
      print('Added alcohol entry: ${entry.name}');
    } catch (e) {
      print('Error adding alcohol entry: $e');
      rethrow;
    }
  }

  Future<void> updateAlcoholEntry(AlcoholEntry entry) async {
    final userDoc = _userDocRef;
    if (userDoc == null) throw Exception("User not logged in");

    try {
      await userDoc.collection('alcohol_entries').doc(entry.id).update(entry.toJson());
      print('Updated alcohol entry: ${entry.name}');
    } catch (e) {
      print('Error updating alcohol entry: $e');
      rethrow;
    }
  }

  Future<void> deleteAlcoholEntry(String entryId) async {
    final userDoc = _userDocRef;
    if (userDoc == null) throw Exception("User not logged in");

    try {
      await userDoc.collection('alcohol_entries').doc(entryId).delete();
      print('Deleted alcohol entry: $entryId');
    } catch (e) {
      print('Error deleting alcohol entry: $e');
      rethrow;
    }
  }

  Stream<List<AlcoholEntry>> get alcoholEntriesStream {
    final userDoc = _userDocRef;
    if (userDoc == null) {
      print('FirebaseService: No user document reference for alcohol entries');
      return Stream.value([]);
    }

    print('FirebaseService: Creating alcohol entries stream');

    return userDoc.collection('alcohol_entries')
        .orderBy('date', descending: true)
        .limit(100) // Reasonable limit
        .snapshots()
        .map((snapshot) {
      try {
        print('FirebaseService: Processing ${snapshot.docs.length} alcohol entry documents');
        final entries = snapshot.docs.map((doc) {
          try {
            return AlcoholEntry.fromJson(doc.data(), doc.id);
          } catch (e) {
            print('FirebaseService: Error parsing alcohol entry ${doc.id}: $e');
            return null;
          }
        }).where((entry) => entry != null).cast<AlcoholEntry>().toList();

        print('FirebaseService: Successfully parsed ${entries.length} alcohol entries');
        return entries;
      } catch (e) {
        print('FirebaseService: Error processing alcohol entries: $e');
        return <AlcoholEntry>[];
      }
    })
        .handleError((error) {
      print('FirebaseService: Error in alcohol entries stream: $error');
      return <AlcoholEntry>[];
    });
  }

  Future<List<AlcoholEntry>> getRecentAlcoholEntries({int days = 30}) async {
    final userDoc = _userDocRef;
    if (userDoc == null) {
      print('FirebaseService: No user document for recent alcohol entries');
      return [];
    }

    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      print('FirebaseService: Querying recent alcohol entries from ${cutoffDate.toIso8601String()}');

      final snapshot = await userDoc.collection('alcohol_entries')
          .where('date', isGreaterThanOrEqualTo: cutoffDate.toIso8601String())
          .orderBy('date', descending: true)
          .limit(50)
          .get();

      final entries = snapshot.docs.map((doc) {
        try {
          return AlcoholEntry.fromJson(doc.data(), doc.id);
        } catch (e) {
          print('FirebaseService: Error parsing recent alcohol entry ${doc.id}: $e');
          return null;
        }
      }).where((entry) => entry != null).cast<AlcoholEntry>().toList();

      print('FirebaseService: Retrieved ${entries.length} recent alcohol entries');
      return entries;
    } catch (e) {
      print('Error getting recent alcohol entries: $e');
      return [];
    }
  }

  Future<void> batchUpdateQuantities(List<FoodLog> foodUpdates, List<ActivityLog> activityUpdates) async {
    final batch = _firestore.batch();
    final userDoc = _userDocRef;
    if (userDoc == null) throw Exception("User not logged in");

    try {
      for (final food in foodUpdates) {
        batch.update(userDoc.collection('food_logs').doc(food.id), food.toJson());
      }

      for (final activity in activityUpdates) {
        batch.update(userDoc.collection('activity_logs').doc(activity.id), activity.toJson());
      }

      await batch.commit();
    } catch (e) {
      print('Error batch updating quantities: $e');
      rethrow;
    }
  }
}