class Employee {
  final int id;
  final String employeeCode;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final int departmentId;
  final String? position;
  final DateTime? dateOfBirth;
  final DateTime joinDate;
  final DateTime createdAt;
  final bool isActive;
  final bool isFaceRegistered;
  final String? faceImageUrl;
  final DateTime? faceRegisteredAt;

  Employee({
    required this.id,
    required this.employeeCode,
    required this.fullName,
    this.email,
    this.phoneNumber,
    required this.departmentId,
    this.position,
    this.dateOfBirth,
    required this.joinDate,
    required this.createdAt,
    required this.isActive,
    required this.isFaceRegistered,
    this.faceImageUrl,
    this.faceRegisteredAt,
  });

factory Employee.fromJson(Map<String, dynamic> json) {
  return Employee(
    id: json['id'] ?? 0,
    employeeCode: json['employeeCode']?.toString() ?? '',
    fullName: json['fullName']?.toString() ?? 'Chưa có tên',
    email: json['email']?.toString(),
    phoneNumber: json['phoneNumber']?.toString(),
    departmentId: json['departmentId'] ?? -1,
    position: json['position']?.toString(),
    dateOfBirth: json['dateOfBirth'] != null
        ? DateTime.tryParse(json['dateOfBirth'])
        : null,
    joinDate: json['joinDate'] != null
        ? DateTime.tryParse(json['joinDate']) ?? DateTime.now()
        : DateTime.now(),
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
        : DateTime.now(),
    isActive: json['isActive'] ?? false,
    isFaceRegistered: json['isFaceRegistered'] ?? false,
    faceImageUrl: json['faceImageUrl']?.toString(),
    faceRegisteredAt: json['faceRegisteredAt'] != null
        ? DateTime.tryParse(json['faceRegisteredAt'])
        : null,
  );
}


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeCode': employeeCode,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'departmentId': departmentId,
      'position': position,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'joinDate': joinDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'isFaceRegistered': isFaceRegistered,
      'faceImageUrl': faceImageUrl,
      'faceRegisteredAt': faceRegisteredAt?.toIso8601String(),
    };
  }
}