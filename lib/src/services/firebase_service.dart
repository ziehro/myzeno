import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zeno/src/models/activity_log.dart';
import 'package:zeno/src/models/food_log.dart';
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/models/weight_log.dart';
import 'package:zeno/src/models/tip.dart';
import 'package:zeno/src/models/recipe.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for reducing reads
  static final Map<String, List<FoodLog>> _foodLogCache = {};
  static final Map<String, List<ActivityLog>> _activityLogCache = {};
  static final Map<String, List<WeightLog>> _weightLogCache = {};
  static DateTime? _lastCacheUpdate;

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

  // --- AUTH METHODS ---
  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    // Clear cache on sign out
    _clearCache();
    await _auth.signOut();
  }

  // --- CACHE MANAGEMENT ---
  void _clearCache() {
    _foodLogCache.clear();
    _activityLogCache.clear();
    _weightLogCache.clear();
    _lastCacheUpdate = null;
  }

  bool _shouldRefreshCache() {
    if (_lastCacheUpdate == null) return true;
    // Refresh cache every 5 minutes
    return DateTime.now().difference(_lastCacheUpdate!).inMinutes > 5;
  }

  // --- FIRESTORE METHODS ---

  // Check if a user has already created their profile
  Future<bool> checkIfUserProfileExists() async {
    final userDoc = _userDocRef;
    if (userDoc == null) return false;
    try {
      final doc = await userDoc.get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Save the initial user profile and goal
  Future<void> saveUserProfileAndGoal(UserProfile profile, UserGoal goal) async {
    final userDoc = _userDocRef;
    if (userDoc == null) throw Exception("User not logged in");

    await userDoc.set(profile.toJson());
    await userDoc.collection('goals').doc('main_goal').set(goal.toJson());
  }

  // Get UserProfile
  Future<UserProfile?> getUserProfile() async {
    final userDoc = _userDocRef;
    if (userDoc == null) return null;
    final snapshot = await userDoc.get();
    if (snapshot.exists) {
      return UserProfile.fromJson(snapshot.data()!);
    }
    return null;
  }

  // Get UserGoal
  Future<UserGoal?> getUserGoal() async {
    final userDoc = _userDocRef;
    if (userDoc == null) return null;
    final snapshot = await userDoc.collection('goals').doc('main_goal').get();
    if (snapshot.exists) {
      return UserGoal.fromJson(snapshot.data()!);
    }
    return null;
  }

  // OPTIMIZED: Get today's data only (much fewer reads)
  Stream<List<FoodLog>> get todaysFoodLogStream {
    final userDoc = _userDocRef;
    if (userDoc == null) return Stream.value([]);

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return userDoc.collection('food_logs')
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('date', isLessThan: endOfDay.toIso8601String())
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FoodLog.fromJson(doc.data(), doc.id)).toList());
  }

  Stream<List<ActivityLog>> get todaysActivityLogStream {
    final userDoc = _userDocRef;
    if (userDoc == null) return Stream.value([]);

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return userDoc.collection('activity_logs')
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('date', isLessThan: endOfDay.toIso8601String())
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ActivityLog.fromJson(doc.data(), doc.id)).toList());
  }

  // OPTIMIZED: Get recent data with limits (for progress screen)
  Stream<List<FoodLog>> get recentFoodLogStream {
    final userDoc = _userDocRef;
    if (userDoc == null) return Stream.value([]);

    // Only get last 30 days of data
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    return userDoc.collection('food_logs')
        .where('date', isGreaterThanOrEqualTo: thirtyDaysAgo.toIso8601String())
        .orderBy('date', descending: true)
        .limit(200) // Reasonable limit
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FoodLog.fromJson(doc.data(), doc.id)).toList());
  }

  Stream<List<ActivityLog>> get recentActivityLogStream {
    final userDoc = _userDocRef;
    if (userDoc == null) return Stream.value([]);

    // Only get last 30 days of data
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    return userDoc.collection('activity_logs')
        .where('date', isGreaterThanOrEqualTo: thirtyDaysAgo.toIso8601String())
        .orderBy('date', descending: true)
        .limit(200) // Reasonable limit
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ActivityLog.fromJson(doc.data(), doc.id)).toList());
  }

  // Keep the old streams for backward compatibility (but mark as deprecated)
  @Deprecated('Use todaysFoodLogStream or recentFoodLogStream instead')
  Stream<List<FoodLog>> get foodLogStream => recentFoodLogStream;

  @Deprecated('Use todaysActivityLogStream or recentActivityLogStream instead')
  Stream<List<ActivityLog>> get activityLogStream => recentActivityLogStream;

  Stream<List<WeightLog>> get weightLogStream {
    final userDoc = _userDocRef;
    if (userDoc == null) return Stream.value([]);
    return userDoc.collection('weight_logs')
        .orderBy('date', descending: true)
        .limit(50) // Reasonable limit for weight logs
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => WeightLog.fromJson(doc.data(), doc.id)).toList());
  }

  // --- Tip & Recipe Methods (add caching) ---
  Stream<List<Tip>> get tipsStream => _firestore.collection('tips').limit(20).snapshots().map((s) => s.docs.map((d) => Tip.fromFirestore(d)).toList());
  Future<void> addTip(Tip tip) async => await _firestore.collection('tips').add(tip.toFirestore());
  Stream<List<Recipe>> get recipesStream => _firestore.collection('recipes').limit(20).snapshots().map((s) => s.docs.map((d) => Recipe.fromFirestore(d)).toList());
  Future<void> addRecipe(Recipe recipe) async => await _firestore.collection('recipes').add(recipe.toFirestore());

  // OPTIMIZED: Use cached frequent items with periodic refresh
  Stream<List<FoodLog>> get frequentFoodLogStream {
    final userDoc = _userDocRef;
    if (userDoc == null) return Stream.value([]);

    return userDoc.collection('frequent_food_logs')
        .limit(10) // Only get top 10 frequent items
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FoodLog.fromJson(doc.data(), doc.id)).toList());
  }

  Stream<List<ActivityLog>> get frequentActivityLogStream {
    final userDoc = _userDocRef;
    if (userDoc == null) return Stream.value([]);

    return userDoc.collection('frequent_activity_logs')
        .limit(10) // Only get top 10 frequent items
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ActivityLog.fromJson(doc.data(), doc.id)).toList());
  }

  // --- LOGGING METHODS (ADD) ---
  Future<void> addFoodLog(FoodLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) return;
    await userDoc.collection('food_logs').add(log.toJson());
    // Only update frequent logs occasionally to reduce writes
    if (DateTime.now().minute % 5 == 0) {
      await addFrequentFoodLog(log);
    }
  }

  Future<void> addActivityLog(ActivityLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) return;
    await userDoc.collection('activity_logs').add(log.toJson());
    // Only update frequent logs occasionally to reduce writes
    if (DateTime.now().minute % 5 == 0) {
      await addFrequentActivityLog(log);
    }
  }

  Future<void> addWeightLog(WeightLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) return;
    await userDoc.collection('weight_logs').add(log.toJson());
  }

  // --- LOGGING METHODS (UPDATE) ---
  Future<void> updateFoodLog(FoodLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) return;
    await userDoc.collection('food_logs').doc(log.id).update(log.toJson());
    // Update frequent log less often
    if (DateTime.now().second % 10 == 0) {
      await addFrequentFoodLog(log);
    }
  }

  Future<void> updateActivityLog(ActivityLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) return;
    await userDoc.collection('activity_logs').doc(log.id).update(log.toJson());
    // Update frequent log less often
    if (DateTime.now().second % 10 == 0) {
      await addFrequentActivityLog(log);
    }
  }

  // --- LOGGING METHODS (DELETE) ---
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

  // --- METHODS TO MANAGE FREQUENT LISTS ---
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

  // --- BATCH OPERATIONS FOR EFFICIENCY ---
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