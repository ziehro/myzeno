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
    await _auth.signOut();
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

  // Get streams for real-time updates
  Stream<List<FoodLog>> get foodLogStream {
    final userDoc = _userDocRef;
    if (userDoc == null) return Stream.value([]);
    return userDoc.collection('food_logs').orderBy('date', descending: true).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => FoodLog.fromJson(doc.data(), doc.id)).toList());
  }

  Stream<List<ActivityLog>> get activityLogStream {
    final userDoc = _userDocRef;
    if (userDoc == null) return Stream.value([]);
    return userDoc.collection('activity_logs').orderBy('date', descending: true).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ActivityLog.fromJson(doc.data(), doc.id)).toList());
  }

  Stream<List<WeightLog>> get weightLogStream {
    final userDoc = _userDocRef;
    if (userDoc == null) return Stream.value([]);
    return userDoc.collection('weight_logs').orderBy('date', descending: true).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => WeightLog.fromJson(doc.data(), doc.id)).toList());
  }

  // --- Tip & Recipe Methods ---
  Stream<List<Tip>> get tipsStream => _firestore.collection('tips').snapshots().map((s) => s.docs.map((d) => Tip.fromFirestore(d)).toList());
  Future<void> addTip(Tip tip) async => await _firestore.collection('tips').add(tip.toFirestore());
  Stream<List<Recipe>> get recipesStream => _firestore.collection('recipes').snapshots().map((s) => s.docs.map((d) => Recipe.fromFirestore(d)).toList());
  Future<void> addRecipe(Recipe recipe) async => await _firestore.collection('recipes').add(recipe.toFirestore());

  // --- FREQUENT LOG STREAMS ---
  Stream<List<FoodLog>> get frequentFoodLogStream {
    final userDoc = _userDocRef;
    if (userDoc == null) return Stream.value([]);
    return userDoc.collection('frequent_food_logs').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => FoodLog.fromJson(doc.data(), doc.id)).toList());
  }

  Stream<List<ActivityLog>> get frequentActivityLogStream {
    final userDoc = _userDocRef;
    if (userDoc == null) return Stream.value([]);
    return userDoc.collection('frequent_activity_logs').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ActivityLog.fromJson(doc.data(), doc.id)).toList());
  }

  // --- LOGGING METHODS (ADD) ---
  Future<void> addFoodLog(FoodLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) return;
    await userDoc.collection('food_logs').add(log.toJson());
    await addFrequentFoodLog(log);
  }

  Future<void> addActivityLog(ActivityLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) return;
    await userDoc.collection('activity_logs').add(log.toJson());
    await addFrequentActivityLog(log);
  }

  Future<void> addWeightLog(WeightLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) return;
    await userDoc.collection('weight_logs').add(log.toJson());
  }

  // --- NEW: LOGGING METHODS (UPDATE) ---
  Future<void> updateFoodLog(FoodLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) return;
    await userDoc.collection('food_logs').doc(log.id).update(log.toJson());
    // Also update the frequent log to match
    await addFrequentFoodLog(log);
  }

  Future<void> updateActivityLog(ActivityLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) return;
    await userDoc.collection('activity_logs').doc(log.id).update(log.toJson());
    // Also update the frequent log to match
    await addFrequentActivityLog(log);
  }

  // --- NEW: LOGGING METHODS (DELETE) ---
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
}