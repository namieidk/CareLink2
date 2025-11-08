class User {
  final String id;
  final String password;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final String? profilePicture;
  final String? fullName;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.password,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.profilePicture,
    this.fullName,
    this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'password': password,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
      'profilePicture': profilePicture,
      'fullName': fullName,
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      password: map['password'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      isActive: map['isActive'] ?? true,
      profilePicture: map['profilePicture'],
      fullName: map['fullName'],
      lastLogin: map['lastLogin'] != null ? DateTime.parse(map['lastLogin']) : null,
    );
  }
}
