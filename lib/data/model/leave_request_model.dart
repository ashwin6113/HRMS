class LeaveRequest {
  final String id;
  final String clientRequestId;
  final String employeeId;
  final String leaveType; // 'casual' or 'sick'
  final DateTime startDate;
  final DateTime endDate;
  final int daysCount;
  final String reason;
  final String status; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final DateTime createdAt;

  const LeaveRequest({
    required this.id,
    required this.clientRequestId,
    required this.employeeId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.daysCount,
    required this.reason,
    this.status = 'pending',
    this.rejectionReason,
    required this.createdAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id']?.toString() ?? '',
      clientRequestId: json['client_request_id'] as String? ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      leaveType: json['leave_type'] as String? ?? 'casual',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      daysCount: json['days_count'] as int? ?? 1,
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_request_id': clientRequestId,
      'employee_id': employeeId,
      'leave_type': leaveType,
      'start_date': startDate.toIso8601String().substring(0, 10),
      'end_date': endDate.toIso8601String().substring(0, 10),
      'days_count': daysCount,
      'reason': reason,
      'status': status,
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() => toJson();

  factory LeaveRequest.fromMap(Map<String, dynamic> map) =>
      LeaveRequest.fromJson(map);

  LeaveRequest copyWith({
    String? id,
    String? clientRequestId,
    String? employeeId,
    String? leaveType,
    DateTime? startDate,
    DateTime? endDate,
    int? daysCount,
    String? reason,
    String? status,
    String? rejectionReason,
    DateTime? createdAt,
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      clientRequestId: clientRequestId ?? this.clientRequestId,
      employeeId: employeeId ?? this.employeeId,
      leaveType: leaveType ?? this.leaveType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      daysCount: daysCount ?? this.daysCount,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
