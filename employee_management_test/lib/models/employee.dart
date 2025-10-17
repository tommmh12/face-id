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
      id: json['id'],
      employeeCode: json['employeeCode'],
      fullName: json['fullName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      departmentId: json['departmentId'],
      position: json['position'],
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth']) : null,
      joinDate: DateTime.parse(json['joinDate']),
      createdAt: DateTime.parse(json['createdAt']),
      isActive: json['isActive'],
      isFaceRegistered: json['isFaceRegistered'],
      faceImageUrl: json['faceImageUrl'],
      faceRegisteredAt: json['faceRegisteredAt'] != null ? DateTime.parse(json['faceRegisteredAt']) : null,
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