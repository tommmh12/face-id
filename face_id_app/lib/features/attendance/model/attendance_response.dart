class AttendanceResponse {
  final bool success;
  final String status; // verified, no_face, no_match, no_users, already_checked_in, error
  final String message;
  final double confidence;
  final MatchedEmployee? matchedEmployee;
  final UserData? userData; // For backward compatibility

  AttendanceResponse({
    required this.success,
    required this.status,
    required this.message,
    required this.confidence,
    this.matchedEmployee,
    this.userData,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceResponse(
      success: json['success'] as bool? ?? false,
      status: json['status'] as String? ?? 'error',
      message: json['message'] as String? ?? 'Unknown error',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      matchedEmployee: json['matchedEmployee'] != null
          ? MatchedEmployee.fromJson(json['matchedEmployee'] as Map<String, dynamic>)
          : null,
      userData: json['userData'] != null
          ? UserData.fromJson(json['userData'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'status': status,
      'message': message,
      'confidence': confidence,
      'matchedEmployee': matchedEmployee?.toJson(),
      'userData': userData?.toJson(),
    };
  }
}

class MatchedEmployee {
  final int employeeId;
  final String employeeCode;
  final String fullName;
  final String? departmentName;
  final String? position;
  final String? avatarUrl;
  final double similarityScore;

  MatchedEmployee({
    required this.employeeId,
    required this.employeeCode,
    required this.fullName,
    this.departmentName,
    this.position,
    this.avatarUrl,
    required this.similarityScore,
  });

  factory MatchedEmployee.fromJson(Map<String, dynamic> json) {
    return MatchedEmployee(
      employeeId: json['employeeId'] as int,
      employeeCode: json['employeeCode'] as String,
      fullName: json['fullName'] as String,
      departmentName: json['departmentName'] as String?,
      position: json['position'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      similarityScore: (json['similarityScore'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'employeeCode': employeeCode,
      'fullName': fullName,
      'departmentName': departmentName,
      'position': position,
      'avatarUrl': avatarUrl,
      'similarityScore': similarityScore,
    };
  }
}

class UserData {
  final int userId;
  final String fullName;
  final double similarityScore;
  final String checkTime;
  final String checkType;

  UserData({
    required this.userId,
    required this.fullName,
    required this.similarityScore,
    required this.checkTime,
    required this.checkType,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      userId: json['userId'] as int,
      fullName: json['fullName'] as String,
      similarityScore: (json['similarityScore'] as num).toDouble(),
      checkTime: json['checkTime'] as String,
      checkType: json['checkType'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'similarityScore': similarityScore,
      'checkTime': checkTime,
      'checkType': checkType,
    };
  }
}
