class AttendanceEvent {
  final int? id;
  final String clientEventId;
  final String employeeId;
  final String eventType; // 'check_in' or 'check_out'
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String syncStatus; // 'pending', 'synced', 'rejected'
  final String? rejectionReason;
  final int retryCount;
  final DateTime createdAt;

  AttendanceEvent({
    this.id,
    required this.clientEventId,
    required this.employeeId,
    required this.eventType,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.syncStatus = 'pending',
    this.rejectionReason,
    this.retryCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AttendanceEvent.fromJson(Map<String, dynamic> json) {
    return AttendanceEvent(
      id: json['id'] as int?,
      clientEventId: json['client_event_id'] as String? ?? '',
      employeeId: json['employee_id'] as String? ?? '',
      eventType: json['event_type'] as String? ?? 'check_in',
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      syncStatus: json['sync_status'] as String? ?? 'pending',
      rejectionReason: json['rejection_reason'] as String?,
      retryCount: json['retry_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'client_event_id': clientEventId,
      'employee_id': employeeId,
      'event_type': eventType,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'sync_status': syncStatus,
      'rejection_reason': rejectionReason,
      'retry_count': retryCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() => toJson();

  factory AttendanceEvent.fromMap(Map<String, dynamic> map) =>
      AttendanceEvent.fromJson(map);

  AttendanceEvent copyWith({
    int? id,
    String? clientEventId,
    String? employeeId,
    String? eventType,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    String? syncStatus,
    String? rejectionReason,
    int? retryCount,
    DateTime? createdAt,
  }) {
    return AttendanceEvent(
      id: id ?? this.id,
      clientEventId: clientEventId ?? this.clientEventId,
      employeeId: employeeId ?? this.employeeId,
      eventType: eventType ?? this.eventType,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      syncStatus: syncStatus ?? this.syncStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
