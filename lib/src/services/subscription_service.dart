import 'package:flutter/foundation.dart';

enum SubscriptionTier {
  free,
  premium,
}

class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  SubscriptionTier _currentTier = SubscriptionTier.free;
  bool _isPremiumUser = false;

  SubscriptionTier get currentTier => _currentTier;
  bool get isPremium => _isPremiumUser;
  bool get isFree => !_isPremiumUser;

  // Feature gates
  bool get canAccessTips => _isPremiumUser;
  bool get canAccessAllCalculators => _isPremiumUser;
  bool get canAccessCloudSync => _isPremiumUser;
  bool get canAccessAdvancedCharts => _isPremiumUser;
  bool get canExportData => _isPremiumUser;
  bool get hasUnlimitedHistory => _isPremiumUser;

  // Free version limits
  int get maxHistoryDays => _isPremiumUser ? -1 : 30; // -1 = unlimited
  int get maxWeightLogs => _isPremiumUser ? -1 : 50;
  bool get canAccessProgressCharts => _isPremiumUser ? true : false; // Basic charts only for free

  void upgradeToPremium() {
    _isPremiumUser = true;
    _currentTier = SubscriptionTier.premium;
    notifyListeners();
  }

  void downgradeToFree() {
    _isPremiumUser = false;
    _currentTier = SubscriptionTier.free;
    notifyListeners();
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
}