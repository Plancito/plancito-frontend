class User {
  const User({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.city,
    required this.role,
    required this.membership,
    this.image,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0,
      name: (json['name'] as String?) ?? '',
      lastName: (json['lastName'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      city: (json['city'] as String?) ?? '',
      role: (json['role'] as String?) ?? '',
      membership: (json['membership'] as String?) ?? '',
      image: json['image'] as String?,
    );
  }

  final int id;
  final String name;
  final String lastName;
  final String email;
  final String city;
  final String role;
  final String membership;
  final String? image;
}
