class WaterUser {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? email;
  final double sharesOfWater;
  final DateTime createdAt;

  WaterUser({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.email,
    required this.sharesOfWater,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'sharesOfWater': sharesOfWater,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WaterUser.fromJson(Map<String, dynamic> json) {
    return WaterUser(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      sharesOfWater: json['sharesOfWater'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  WaterUser copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    double? sharesOfWater,
    DateTime? createdAt,
  }) {
    return WaterUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      sharesOfWater: sharesOfWater ?? this.sharesOfWater,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 