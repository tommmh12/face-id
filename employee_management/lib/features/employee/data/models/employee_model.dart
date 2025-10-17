class Employee {
  final int id;
  final String employeeCode;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final int departmentId;
  final String? departmentCode;
  final String? departmentName;
  final String? position;
  final DateTime? dateOfBirth;
  final DateTime? joinDate;
  final String? faceImageUrl;
  final bool isActive;
  final bool isFaceRegistered;
  final DateTime? faceRegisteredAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Employee({
    required this.id,
    required this.employeeCode,
    required this.fullName,
    this.email,
    this.phoneNumber,
    required this.departmentId,
    this.departmentCode,
    this.departmentName,
    this.position,
    this.dateOfBirth,
    this.joinDate,
    this.faceImageUrl,
    this.isActive = true,
    this.isFaceRegistered = false,
    this.faceRegisteredAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as int? ?? 0,
      employeeCode: json['employeeCode'] as String? ?? '',
      fullName: json['fullName'] as String? ?? 'Unknown',
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      departmentId: json['departmentId'] as int? ?? 0,
      departmentCode: json['departmentCode'] as String?,
      departmentName: json['departmentName'] as String?,
      position: json['position'] as String?,
      dateOfBirth: json['dateOfBirth'] != null 
          ? _parseDateTime(json['dateOfBirth'])
          : null,
      joinDate: json['joinDate'] != null
          ? _parseDateTime(json['joinDate'])
          : null,
      faceImageUrl: json['faceImageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isFaceRegistered: json['isFaceRegistered'] as bool? ?? false,
      faceRegisteredAt: json['faceRegisteredAt'] != null
          ? _parseDateTime(json['faceRegisteredAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? _parseDateTime(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? _parseDateTime(json['updatedAt'])
          : null,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      if (value is String) {
        return DateTime.parse(value);
      }
      return null;
    } catch (e) {
      print('Error parsing date: $value - $e');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeCode': employeeCode,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'departmentId': departmentId,
      'departmentCode': departmentCode,
      'departmentName': departmentName,
      'position': position,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'joinDate': joinDate?.toIso8601String(),
      'faceImageUrl': faceImageUrl,
      'isActive': isActive,
      'isFaceRegistered': isFaceRegistered,
      'faceRegisteredAt': faceRegisteredAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class CreateEmployeeRequest {
  final String fullName;
  final String email;
  final String? phoneNumber;
  final int departmentId;
  final String? position;
  final DateTime? dateOfBirth;
  final DateTime? joinDate;

  CreateEmployeeRequest({
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.departmentId,
    this.position,
    this.dateOfBirth,
    this.joinDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'FullName': fullName,                              // PascalCase
      'Email': email,                                    // PascalCase
      'PhoneNumber': phoneNumber,                        // PascalCase
      'DepartmentId': departmentId,                      // PascalCase
      'Position': position,                              // PascalCase
      'DateOfBirth': dateOfBirth?.toIso8601String(),    // PascalCase
      'JoinDate': joinDate?.toIso8601String(),          // PascalCase
    };
  }
}

class RegisterFaceRequest {
  final int employeeId;
  final String faceImageBase64;

  RegisterFaceRequest({
    required this.employeeId,
    required this.faceImageBase64,
  });

  Map<String, dynamic> toJson() {
    return {
      'EmployeeId': employeeId,              // PascalCase
      'FaceImageBase64': faceImageBase64,    // PascalCase
    };
  }
}

class VerifyFaceRequest {
  final String imageBase64;

  VerifyFaceRequest({
    required this.imageBase64,
  });

  Map<String, dynamic> toJson() {
    return {
      'ImageBase64': imageBase64,  // PascalCase theo API docs
    };
  }
}
