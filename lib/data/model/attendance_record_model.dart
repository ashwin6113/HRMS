class AttendanceRecord {
  final String id;
  final String employeeId;
  final String date; // YYYY-MM-DD
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String status; // 'Not Checked In', 'Checked In', 'Checked Out'
  final int? durationMinutes;
  final String syncStatus; // 'synced', 'pending', 'rejected'
  final String? rejectionReason;

  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
    this.durationMinutes,
    this.syncStatus = 'synced',
    this.rejectionReason,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      date: json['date'] as String? ?? '',
      checkInTime: json['check_in_time'] != null
          ? DateTime.tryParse(json['check_in_time'].toString())
          : null,
      checkOutTime: json['check_out_time'] != null
          ? DateTime.tryParse(json['check_out_time'].toString())
          : null,
      status: json['status'] as String? ?? 'Not Checked In',
      durationMinutes: json['duration_minutes'] as int?,
      syncStatus: json['sync_status'] as String? ?? 'synced',
      rejectionReason: json['rejection_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'date': date,
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'status': status,
      'duration_minutes': durationMinutes,
      'sync_status': syncStatus,
      'rejection_reason': rejectionReason,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) =>
      AttendanceRecord.fromJson(map);

  AttendanceRecord copyWith({
    String? id,
    String? employeeId,
    String? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? status,
    int? durationMinutes,
    String? syncStatus,
    String? rejectionReason,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      status: status ?? this.status,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      syncStatus: syncStatus ?? this.syncStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
