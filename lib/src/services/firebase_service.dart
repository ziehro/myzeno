import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zeno/src/models/activity_log.dart';
import 'package:zeno/src/models/food_log.dart';
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/models/weight_log.dart';

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

  // --- NEW DATA FETCHING METHODS ---

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

  // Add a food log
  Future<void> addFoodLog(FoodLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) return;
    await userDoc.collection('food_logs').add(log.toJson());
  }

  // Add an activity log
  Future<void> addActivityLog(ActivityLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) return;
    await userDoc.collection('activity_logs').add(log.toJson());
  }

  // Add a weight log
  Future<void> addWeightLog(WeightLog log) async {
    final userDoc = _userDocRef;
    if (userDoc == null) return;
    await userDoc.collection('weight_logs').add(log.toJson());
  }
}