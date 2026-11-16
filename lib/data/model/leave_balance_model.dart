class LeaveBalance {
  final double casualAvailable;
  final double casualTotal;
  final double sickAvailable;
  final double sickTotal;

  const LeaveBalance({
    required this.casualAvailable,
    required this.casualTotal,
    required this.sickAvailable,
    required this.sickTotal,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      casualAvailable:
          (json['casual_available'] as num?)?.toDouble() ?? 12.0,
      casualTotal: (json['casual_total'] as num?)?.toDouble() ?? 15.0,
      sickAvailable: (json['sick_available'] as num?)?.toDouble() ?? 8.0,
      sickTotal: (json['sick_total'] as num?)?.toDouble() ?? 10.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'casual_available': casualAvailable,
      'casual_total': casualTotal,
      'sick_available': sickAvailable,
      'sick_total': sickTotal,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  factory LeaveBalance.fromMap(Map<String, dynamic> map) =>
      LeaveBalance.fromJson(map);

  double get totalAvailable => casualAvailable + sickAvailable;
  double get totalQuota => casualTotal + sickTotal;

  LeaveBalance copyWith({
    double? casualAvailable,
    double? casualTotal,
    double? sickAvailable,
    double? sickTotal,
  }) {
    return LeaveBalance(
      casualAvailable: casualAvailable ?? this.casualAvailable,
      casualTotal: casualTotal ?? this.casualTotal,
      sickAvailable: sickAvailable ?? this.sickAvailable,
      sickTotal: sickTotal ?? this.sickTotal,
    );
  }

  static const defaultBalance = LeaveBalance(
    casualAvailable: 10.0,
    casualTotal: 14.0,
    sickAvailable: 7.0,
    sickTotal: 10.0,
  );
}
