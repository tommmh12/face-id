class AttendanceResponse {
  final bool success;
  final String message;
  final UserData? userData;

  AttendanceResponse({
    required this.success,
    required this.message,
    this.userData,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      userData: json['userData'] != null
          ? UserData.fromJson(json['userData'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'userData': userData?.toJson(),
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
