class Department {
  final int id;
  final String? code;
  final String name;
  final String? description;
  final DateTime createdAt;
  final bool isActive;

  Department({
    required this.id,
    this.code,
    required this.name,
    this.description,
    required this.createdAt,
    required this.isActive,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? 0,
      code: json['code']?.toString(),
      name: json['name']?.toString() ?? 'Unknown',
      description: json['description']?.toString(),
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      isActive: json['isActive'] ?? false,
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