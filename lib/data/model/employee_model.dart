class Employee {
  final int id;
  final String employeeId;
  final String name;
  final String department;
  final double officeLatitude;
  final double officeLongitude;
  final double geofenceRadiusMeters;
  final String timezone;
  final String? avatarUrl;

  const Employee({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.department,
    required this.officeLatitude,
    required this.officeLongitude,
    this.geofenceRadiusMeters = 200.0,
    this.timezone = 'Asia/Kolkata',
    this.avatarUrl,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as int? ?? 1,
      employeeId: json['employee_id'] as String? ?? 'EMP-878',
      name: json['name'] as String? ?? 'Alex Smith',
      department: json['department'] as String? ?? 'Engineering',
      officeLatitude: (json['office_latitude'] as num?)?.toDouble() ?? 12.9716,
      officeLongitude: (json['office_longitude'] as num?)?.toDouble() ?? 77.5946,
      geofenceRadiusMeters:
          (json['geofence_radius_meters'] as num?)?.toDouble() ?? 200.0,
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'name': name,
      'department': department,
      'office_latitude': officeLatitude,
      'office_longitude': officeLongitude,
      'geofence_radius_meters': geofenceRadiusMeters,
      'timezone': timezone,
      'avatar_url': avatarUrl,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  factory Employee.fromMap(Map<String, dynamic> map) => Employee.fromJson(map);

  Employee copyWith({
    int? id,
    String? employeeId,
    String? name,
    String? department,
    double? officeLatitude,
    double? officeLongitude,
    double? geofenceRadiusMeters,
    String? timezone,
    String? avatarUrl,
  }) {
    return Employee(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      name: name ?? this.name,
      department: department ?? this.department,
      officeLatitude: officeLatitude ?? this.officeLatitude,
      officeLongitude: officeLongitude ?? this.officeLongitude,
      geofenceRadiusMeters: geofenceRadiusMeters ?? this.geofenceRadiusMeters,
      timezone: timezone ?? this.timezone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  static const defaultEmployee = Employee(
    id: 1,
    employeeId: 'EMP-878',
    name: 'Alex Smith',
    department: 'Engineering',
    officeLatitude: 12.9716,
    officeLongitude: 77.5946,
    geofenceRadiusMeters: 200.0,
    timezone: 'Asia/Kolkata',
  );
}
