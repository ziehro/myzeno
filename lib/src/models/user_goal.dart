class UserGoal {
  double lbsToLose;
  int days;

  UserGoal({
    required this.lbsToLose,
    required this.days,
  });

  // Convert to a Map for Firestore
  Map<String, dynamic> toJson() => {
    'lbsToLose': lbsToLose,
    'days': days,
  };

  // Create from a Firestore document
  static UserGoal fromJson(Map<String, dynamic> json) => UserGoal(
    lbsToLose: (json['lbsToLose'] as num).toDouble(),
    days: json['days'],
  );

  // Calculated properties remain the same
  int get totalCalorieDeficit => (lbsToLose * 3500).round();
  int get dailyCalorieDeficitTarget =>
      days > 0 ? (totalCalorieDeficit / days).round() : 0;
}