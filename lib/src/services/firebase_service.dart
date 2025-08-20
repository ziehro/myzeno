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
    _todayActivityController = null;
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
    _clearCache(); // Clear cache on auth change
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signIn(String email, String password) async {
    _clearCache(); // Clear cache on auth change
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    _clearCache(); // Clear cache on sign out
    await _auth.signOut();
  }

  // --- PROFILE & GOAL METHODS (HEAVILY CACHED) ---

  Future<bool> checkIfUserProfileExists() async {
    final userDoc = _userDocRef;
    if (userDoc == null) return false;

    // Use cache first
    if (_cachedProfile != null && !_shouldRefreshCache()) {
      return true;
    }

    try {
      final doc = await userDoc.get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<void> saveUserProfileAndGoal(UserProfile profile, UserGoal goal) async {
    final userDoc = _userDocRef;
    if (userDoc == null) throw Exception("User not logged in");

    // Save to Firebase
    await userDoc.set(profile.toJson());
    await userDoc.collection('goals').doc('main_goal').set(goal.toJson());

    // Update cache immediately
    _cachedProfile = profile;
    _cachedGoal = goal;
    _lastCacheUpdate = DateTime.now();
  }

  Future<UserProfile?> getUserProfile() async {
    // Return cached version if available and fresh
    if (_cachedProfile != null && !_shouldRefreshCache()) {
      return _cachedProfile;
    }

    final userDoc = _userDocRef;
    if (userDoc == null) return null;

    try {
      final snapshot = await userDoc.get();
      if (snapshot.exists) {
        _cachedProfile = UserProfile.fromJson(snapshot.data()!);
        _lastCacheUpdate = DateTime.now();
        return _cachedProfile;
      }
    } catch (e) {
      print('Error getting user profile: $e');
    }
    return null;
  }

  Future<UserGoal?> getUserGoal() async {
    // Return cached version if available and fresh
    if (_cachedGoal != null && !_shouldRefreshCache()) {
      return _cachedGoal;
    }

    final userDoc = _userDocRef;
    if (userDoc == null) return null;

    try {
      final snapshot = await userDoc.collection('goals').doc('main_goal').get();
      if (snapshot.exists) {
        _cachedGoal = UserGoal.fromJson(snapshot.data()!);
        _lastCacheUpdate = DateTime.now();
        return _cachedGoal;
      }
    } catch (e) {
      print('Error getting user goal: $e');
    }
    return null;
  }

  // --- TODAY'S DATA STREAMS (SINGLE SOURCE OF TRUTH) ---

  Stream<List<FoodLog>> get todaysFoodLogStream {
    // Return existing stream if available
    if (_todayFoodController != null && !_todayFoodController!.isClosed) {
      return _todayFoodController!.stream;
    }

    final userDoc = _userDocRef;
    if (userDoc == null) return Stream.value([]);

    _todayFoodController = StreamController<List<FoodLog>>.broadcast();

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Use single listener and cache aggressively
    userDoc.collection('food_logs')
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('date', isLessThan: endOfDay.toIso8601String())
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      final logs = snapshot.docs.map((doc) => FoodLog.fromJson(doc.data(), doc.id)).toList();
      _cachedTodayFood = logs;
      if (!_todayFoodController!.isClosed) {
        _todayFoodController!.add(logs);
      }
    });

    return _todayFoodController!.stream;
  }

  Stream<List<ActivityLog>> get todaysActivityLogStream {
    // Return existing stream if available
    if (_todayActivityController != null && !_todayActivityController!.isClosed) {
      return _todayActivityController!.stream;
    }

    final userDoc = _userDocRef;
    if (userDoc == null) return Stream.value([]);

    _todayActivityController = StreamController<List<ActivityLog>>.broadcast();

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Use single listener and cache aggressively
    userDoc.collection('activity_logs')
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('date', isLessThan: endOfDay.toIso8601String())
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      final logs = snapshot.docs.map((doc) => ActivityLog.fromJson(doc.data(), doc.id)).toList();
      _cachedTodayActivity = logs;
      if (!_todayActivityController!.isClosed) {
        _todayActivityController!.add(logs);
      }
    });

    return _todayActivityController!.stream;
  }

  // --- WEIGHT LOGS (CACHED & LIMITED) ---

  Stream<List<WeightLog>> get weightLogStream {
    // Return existing stream if available
    if (_weightController != null && !_weightController!.isClosed) {
      return _weightController!.stream;
    }

    final userDoc = _userDocRef;
    if (userDoc == null) return Stream.value([]);

    _weightController = StreamController<List<WeightLog>>.broadcast();

    // Limit to recent weight logs only
    userDoc.collection('weight_logs')
        .orderBy('date', descending: true)
        .limit(30) // Only get last 30 entries
        .snapshots()
        .listen((snapshot) {
      final logs = snapshot.docs.map((doc) => WeightLog.fromJson(doc.data(), doc.id)).toList();
      _cachedWeightLogs = logs;
      if (!_weightController!.isClosed) {
        _weightController!.add(logs);
      }
    });

    return _weightController!.stream;
  }

  // --- PROGRESS DATA (STATIC QUERIES) ---

  Future<List<FoodLog>> getRecentFoodLogs() async {
    final userDoc = _userDocRef;
    if (userDoc == null) return [];

    // Get last 14 days only for progress
    final fourteenDaysAgo = DateTime.now().subtract(const Duration(days: 14));

    final snapshot = await userDoc.collection('food_logs')
        .where('date', isGreaterThanOrEqualTo: fourteenDaysAgo.toIso8601String())
        .orderBy('date', descending: true)
        .limit(100) // Hard limit
        .get();

    return snapshot.docs.map((doc) => FoodLog.fromJson(doc.data(), doc.id)).toList();
  }

  Future<List<ActivityLog>> getRecentActivityLogs() async {
    final userDoc = _userDocRef;
    if (userDoc == null) return [];

    // Get last 14 days only for progress
    final fourteenDaysAgo = DateTime.now().subtract(const Duration(days: 14));

    final snapshot = await userDoc.collection('activity_logs')
        .where('date', isGreaterThanOrEqualTo: fourteenDaysAgo.toIso8601String())
        .orderBy('date', descending: true)
        .limit(100) // Hard limit
        .get();

    return snapshot.docs.map((doc) => ActivityLog.fromJson(doc.data(), doc.id)).toList();
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

    // Only update frequent items occasionally
    return userDoc.collection('frequent_food_logs')
        .limit(8) // Reduced limit
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FoodLog.fromJson(doc.data(), doc.id)).toList());
  }

  Stream<List<ActivityLog>> get frequentActivityLogStream {
    final userDoc = _userDocRef;
    if (userDoc == null) return Stream.value([]);

    // Only update frequent items occasionally
    return userDoc.collection('frequent_activity_logs')
        .limit(8) // Reduced limit
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ActivityLog.fromJson(doc.data(), doc.id)).toList());
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

    final snapshot = await _firestore.collection('tips').limit(15).get();
    _cachedTips = snapshot.docs.map((d) => Tip.fromFirestore(d)).toList();
    _lastGlobalCacheUpdate = DateTime.now();
    yield _cachedTips!;
  }

  Stream<List<Recipe>> get recipesStream async* {
    // Use cache for global data
    if (_cachedRecipes != null && _lastGlobalCacheUpdate != null &&
        DateTime.now().difference(_lastGlobalCacheUpdate!).inHours < 1) {
      yield _cachedRecipes!;
      return;
    }

    final snapshot = await _firestore.collection('recipes').limit(15).get();
    _cachedRecipes = snapshot.docs.map((d) => Recipe.fromFirestore(d)).toList();
    _lastGlobalCacheUpdate = DateTime.now();
    yield _cachedRecipes!;
  }

  // --- CRUD OPERATIONS (OPTIMIZED) ---

  Future<void> addFoodLog(FoodLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) return;

    await userDoc.collection('food_logs').add(log.toJson());

    // Update frequent logs only every 10th addition
    if (DateTime.now().second % 10 == 0) {
      await addFrequentFoodLog(log);
    }
  }

  Future<void> addActivityLog(ActivityLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) return;

    await userDoc.collection('activity_logs').add(log.toJson());

    // Update frequent logs only every 10th addition
    if (DateTime.now().second % 10 == 0) {
      await addFrequentActivityLog(log);
    }
  }

  Future<void> addWeightLog(WeightLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) return;
    await userDoc.collection('weight_logs').add(log.toJson());
  }

  Future<void> updateFoodLog(FoodLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) return;
    await userDoc.collection('food_logs').doc(log.id).update(log.toJson());
  }

  Future<void> updateActivityLog(ActivityLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) return;
    await userDoc.collection('activity_logs').doc(log.id).update(log.toJson());
  }

  Future<void> deleteFoodLog(String logId) async {
    final userDoc = _userDocRef;
    if (userDoc == null) return;
    await userDoc.collection('food_logs').doc(logId).delete();
  }

  Future<void> deleteActivityLog(String logId) async {
    final userDoc = _userDocRef;
    if (userDoc == null) return;
    await userDoc.collection('activity_logs').doc(logId).delete();
  }

  // --- FREQUENT LISTS (MINIMAL UPDATES) ---

  Future<void> addFrequentFoodLog(FoodLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) return;
    await userDoc.collection('frequent_food_logs').doc(log.name).set(log.toJson());
  }

  Future<void> addFrequentActivityLog(ActivityLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) return;
    await userDoc.collection('frequent_activity_logs').doc(log.name).set(log.toJson());
  }

  Future<void> addTip(Tip tip) async => await _firestore.collection('tips').add(tip.toFirestore());
  Future<void> addRecipe(Recipe recipe) async => await _firestore.collection('recipes').add(recipe.toFirestore());

  // --- BATCH OPERATIONS ---

  Future<void> batchUpdateQuantities(List<FoodLog> foodUpdates, List<ActivityLog> activityUpdates) async {
    final batch = _firestore.batch();
    final userDoc = _userDocRef;
    if (userDoc == null) return;

    for (final food in foodUpdates) {
      batch.update(userDoc.collection('food_logs').doc(food.id), food.toJson());
    }

    for (final activity in activityUpdates) {
      batch.update(userDoc.collection('activity_logs').doc(activity.id), activity.toJson());
    }

    await batch.commit();
  }
}