class User {
  final int id;
  final String username;
  final String? sex;
  final int? age;
  final String? usernameAcc;
  final String? password;
  final String? avatarUrl;
  final String? bio;
  final bool? isInstructor; // <-- Đổi sang bool?
  final String? email;
  final String? phone;
  final bool? isActive;

  User({
    required this.id,
    required this.username,
    this.sex,
    this.age,
    this.usernameAcc,
    this.password,
    this.avatarUrl,
    this.bio,
    this.isInstructor, // <-- Đúng kiểu bool?
    this.email,
    this.phone,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      sex: json['sex'] as String?,
      age: json['age'] as int?,
      usernameAcc: json['username_acc'] as String?,
      password: json['password'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      isInstructor: json['is_instructor'] as bool?, // <-- Sửa lại dòng này!
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'sex': sex,
      'age': age,
      'username_acc': usernameAcc,
      'password': password,
      'avatar_url': avatarUrl,
      'bio': bio,
      'is_instructor': isInstructor, // <-- Giữ nguyên bool?
      'email': email,
      'phone': phone,
      'is_active': isActive,
    };
  }
}
