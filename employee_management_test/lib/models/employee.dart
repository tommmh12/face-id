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
  final DateTime joinDate;
  final DateTime createdAt;
  final bool isActive;
  final bool isFaceRegistered;
  final String? faceImageUrl;
  final DateTime? faceRegisteredAt;
  final int? roleId;
  final String? roleName;
  final String? roleLevel;
  final bool hasAccount;
  final DateTime? accountProvisionedAt;
  final String? currentStatus;
  final DateTime? statusUpdatedAt;
  final DateTime? lastCheckInToday;

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
    required this.joinDate,
    required this.createdAt,
    required this.isActive,
    required this.isFaceRegistered,
    this.faceImageUrl,
    this.faceRegisteredAt,
    this.roleId,
    this.roleName,
    this.roleLevel,
    this.hasAccount = false,
    this.accountProvisionedAt,
    this.currentStatus,
    this.statusUpdatedAt,
    this.lastCheckInToday,
  });

factory Employee.fromJson(Map<String, dynamic> json) {
  // DEBUG: In ra JSON nhận được
  print(">>> [Employee.fromJson] Raw JSON received: $json");
  print(">>> [Employee.fromJson] JSON keys: ${json.keys.toList()}");
  print(">>> [Employee.fromJson] fullName value: '${json['fullName']}' (type: ${json['fullName'].runtimeType})");
  print(">>> [Employee.fromJson] id value: '${json['id']}' (type: ${json['id'].runtimeType})");
  print(">>> [Employee.fromJson] email value: '${json['email']}' (type: ${json['email'].runtimeType})");
  
  // Tạo Employee object
  final employee = Employee(
    id: json['id'] ?? 0,
    employeeCode: json['employeeCode']?.toString() ?? 'EMP${json['id'] ?? 0}',
    fullName: json['fullName']?.toString() ?? 'Chưa có tên',
    email: json['email']?.toString(),
    phoneNumber: json['phoneNumber']?.toString(),
    departmentId: json['departmentId'] ?? -1,
    departmentCode: json['departmentCode']?.toString(),
    departmentName: json['departmentName']?.toString(),
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
    roleId: json['roleId'],
    roleName: json['roleName']?.toString(),
    roleLevel: json['roleLevel']?.toString(),
    hasAccount: json['hasAccount'] ?? false,
    accountProvisionedAt: json['accountProvisionedAt'] != null
        ? DateTime.tryParse(json['accountProvisionedAt'])
        : null,
    currentStatus: json['currentStatus']?.toString(),
    statusUpdatedAt: json['statusUpdatedAt'] != null
        ? DateTime.tryParse(json['statusUpdatedAt'])
        : null,
    lastCheckInToday: json['lastCheckInToday'] != null
        ? DateTime.tryParse(json['lastCheckInToday'])
        : null,
  );

  // DEBUG: In ra Employee object sau khi tạo
  print(">>> [Employee.fromJson] Created Employee: id=${employee.id}, fullName='${employee.fullName}', email='${employee.email}'");
  print(">>> [Employee.fromJson] Department: departmentId=${employee.departmentId}, departmentName='${employee.departmentName}'");
  
  return employee;
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
      'joinDate': joinDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'isFaceRegistered': isFaceRegistered,
      'faceImageUrl': faceImageUrl,
      'faceRegisteredAt': faceRegisteredAt?.toIso8601String(),
      'roleId': roleId,
      'roleName': roleName,
      'roleLevel': roleLevel,
      'hasAccount': hasAccount,
      'accountProvisionedAt': accountProvisionedAt?.toIso8601String(),
      'currentStatus': currentStatus,
      'statusUpdatedAt': statusUpdatedAt?.toIso8601String(),
      'lastCheckInToday': lastCheckInToday?.toIso8601String(),
    };
  }
}