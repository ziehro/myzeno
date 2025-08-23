import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionTier {
  free,
  premium,
}

class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal() {
    _loadSubscriptionStatus();
    // Listen to auth changes to reload subscription
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  SubscriptionTier _currentTier = SubscriptionTier.free;
  bool _isPremiumUser = false;
  bool _isLoading = false;

  // Debug mode - shows in development only
  bool _debugMode = kDebugMode;
  bool _debugPremiumOverride = false;

  SubscriptionTier get currentTier => _currentTier;
  bool get isPremium => _isPremiumUser || (_debugMode && _debugPremiumOverride);
  bool get isFree => !isPremium;
  bool get isDebugMode => _debugMode;
  bool get debugPremiumOverride => _debugPremiumOverride;
  bool get isLoading => _isLoading;

  // Feature gates
  bool get canAccessTips => isPremium;
  bool get canAccessAllCalculators => isPremium;
  bool get canAccessCloudSync => isPremium;
  bool get canAccessAdvancedCharts => isPremium;
  bool get canExportData => isPremium;
  bool get hasUnlimitedHistory => isPremium;

  // Free version limits
  int get maxHistoryDays => isPremium ? -1 : 30; // -1 = unlimited
  int get maxWeightLogs => isPremium ? -1 : 50;
  bool get canAccessProgressCharts => isPremium ? true : false;

  void _onAuthStateChanged(User? user) {
    print('SubscriptionService: Auth state changed - User: ${user?.email ?? 'null'}');
    _loadSubscriptionStatus();
  }

  // Load subscription status from Firebase and local storage
  Future<void> _loadSubscriptionStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Load from Firebase
        print('SubscriptionService: Loading subscription from Firebase for ${user.email}');
        await _loadFromFirebase(user.uid);
      } else {
        // Load from local storage (for offline users)
        print('SubscriptionService: Loading subscription from local storage');
        await _loadFromLocalStorage();
      }

      // Load debug override
      if (_debugMode) {
        final prefs = await SharedPreferences.getInstance();
        _debugPremiumOverride = prefs.getBool('debug_premium_override') ?? false;
      }

      print('SubscriptionService: Loaded - Premium: $_isPremiumUser, Debug Override: $_debugPremiumOverride');

    } catch (e) {
      print('SubscriptionService: Error loading subscription status: $e');
      // Default to free on error
      _isPremiumUser = false;
      _currentTier = SubscriptionTier.free;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromFirebase(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _isPremiumUser = data['isPremiumUser'] ?? false;
        _currentTier = _isPremiumUser ? SubscriptionTier.premium : SubscriptionTier.free;

        // Also save to local storage as backup
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_premium_user', _isPremiumUser);

        print('SubscriptionService: Loaded from Firebase - Premium: $_isPremiumUser');
      } else {
        // No subscription data in Firebase, default to free
        _isPremiumUser = false;
        _currentTier = SubscriptionTier.free;

        // Create the subscription document
        await _saveToFirebase(userId);
      }
    } catch (e) {
      print('SubscriptionService: Error loading from Firebase: $e');
      // Fallback to local storage
      await _loadFromLocalStorage();
    }
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremiumUser = prefs.getBool('is_premium_user') ?? false;
      _currentTier = _isPremiumUser ? SubscriptionTier.premium : SubscriptionTier.free;

      print('SubscriptionService: Loaded from local storage - Premium: $_isPremiumUser');
    } catch (e) {
      print('SubscriptionService: Error loading from local storage: $e');
      _isPremiumUser = false;
      _currentTier = SubscriptionTier.free;
    }
  }

  Future<void> _saveToFirebase(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'isPremiumUser': _isPremiumUser,
        'subscriptionTier': _currentTier.toString(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('SubscriptionService: Saved to Firebase - Premium: $_isPremiumUser');
    } catch (e) {
      print('SubscriptionService: Error saving to Firebase: $e');
    }
  }

  Future<void> upgradeToPremium() async {
    final wasFreeBefore = _currentTier == SubscriptionTier.free;
    _isPremiumUser = true;
    _currentTier = SubscriptionTier.premium;

    // Save to Firebase and local storage
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _saveToFirebase(user.uid);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium_user', true);

    print('SubscriptionService: Upgraded to Premium');
    notifyListeners();

    // Trigger data migration if this was an upgrade
    if (wasFreeBefore) {
      _triggerDataMigration();
    }
  }

  Future<void> downgradeToFree() async {
    final wasPremiumBefore = _currentTier == SubscriptionTier.premium;
    _isPremiumUser = false;
    _currentTier = SubscriptionTier.free;

    // Save to Firebase and local storage
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _saveToFirebase(user.uid);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium_user', false);

    print('SubscriptionService: Downgraded to Free');
    notifyListeners();

    // Trigger data migration if this was a downgrade
    if (wasPremiumBefore) {
      _triggerDataMigration();
    }
  }

  // Debug methods - only work in debug mode
  Future<void> toggleDebugPremium() async {
    if (!_debugMode) return;

    _debugPremiumOverride = !_debugPremiumOverride;

    // Save to storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('debug_premium_override', _debugPremiumOverride);

    print('SubscriptionService: Debug Premium Override set to $_debugPremiumOverride');
    notifyListeners();
  }

  Future<void> setDebugPremium(bool enabled) async {
    if (!_debugMode) return;

    _debugPremiumOverride = enabled;

    // Save to storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('debug_premium_override', enabled);

    print('SubscriptionService: Debug Premium Override set to $enabled');
    notifyListeners();
  }

  // Helper to trigger data migration in the hybrid service
  void _triggerDataMigration() {
    // This would be called by the main app to trigger migration
    // The HybridDataService listens to subscription changes
    print('SubscriptionService: Triggering data migration due to subscription change');
  }

  // Check if feature is available
  bool isFeatureAvailable(String feature) {
    switch (feature) {
      case 'tips':
        return canAccessTips;
      case 'advanced_calculators':
        return canAccessAllCalculators;
      case 'cloud_sync':
        return canAccessCloudSync;
      case 'export_data':
        return canExportData;
      case 'advanced_charts':
        return canAccessAdvancedCharts;
      default:
        return true; // Default to available
    }
  }

  // Get feature description for paywall
  String getFeatureDescription(String feature) {
    switch (feature) {
      case 'tips':
        return 'Access health tips and recipes from nutrition experts';
      case 'advanced_calculators':
        return 'Unlock all calculators including alcohol, BMR, BMI, and water intake';
      case 'cloud_sync':
        return 'Sync your data across devices and never lose your progress';
      case 'export_data':
        return 'Export your data to CSV for detailed analysis';
      case 'advanced_charts':
        return 'View detailed progress charts and weight trends';
      default:
        return 'Premium feature';
    }
  }

  // Premium features list for marketing
  List<String> get premiumFeatures => [
    '🔒 Cloud sync across devices',
    '💡 Expert health tips & recipes',
    '🧮 Advanced calculators (BMR, BMI, Alcohol, Water)',
    '📊 Detailed progress charts & analytics',
    '📥 Export data to CSV',
    '♾️ Unlimited history storage',
    '🔄 Automatic data backup',
    '📱 Priority customer support',
  ];

  // Subscription pricing (would integrate with app store)
  Map<String, dynamic> get pricingInfo => {
    'monthly': {
      'price': 2.99,
      'period': 'month',
      'savings': 0,
    },
    'yearly': {
      'price': 19.99,
      'period': 'year',
      'savings': 44, // percentage saved vs monthly
    },
  };

  // Get subscription status text for UI
  String get subscriptionStatusText {
    if (_isLoading) return 'Loading...';

    if (_debugMode && _debugPremiumOverride) {
      return 'Premium (Debug Mode)';
    } else if (_isPremiumUser) {
      return 'Premium';
    } else {
      return 'Free';
    }
  }

  // Get status color for UI
  Color get subscriptionStatusColor {
    if (_isLoading) return Colors.grey;

    if (isPremium) {
      return _debugMode && _debugPremiumOverride
          ? const Color(0xFFFF6B35) // Orange for debug
          : const Color(0xFFFFD700); // Gold for real premium
    } else {
      return const Color(0xFF9E9E9E); // Grey for free
    }
  }
}