class Department {
  final int id;
  final String code;
  final String name;
  final String? description;
  final DateTime createdAt;
  final bool isActive;

  Department({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.createdAt,
    required this.isActive,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}