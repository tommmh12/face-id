class Department {
  final int id;
  final String code;
  final String name;
  final String? description;
  final int employeeCount;

  Department({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.employeeCount = 0,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      description: json['description'] as String?,
      employeeCount: json['employeeCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'employeeCount': employeeCount,
    };
  }
}

