class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }
}

class StudentProfile {
  final String id;
  final String userId;
  final String rollNo;
  final String department;
  final String course;
  final String? userName;
  final String? userEmail;

  StudentProfile({
    required this.id,
    required this.userId,
    required this.rollNo,
    required this.department,
    required this.course,
    this.userName,
    this.userEmail,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    return StudentProfile(
      id: json['_id'] as String,
      userId: (user is Map ? user['_id'] : json['userId']) as String,
      rollNo: json['rollNo'] as String? ?? '',
      department: json['department'] as String? ?? '',
      course: json['course'] as String? ?? '',
      userName: user is Map ? user['name'] as String? : null,
      userEmail: user is Map ? user['email'] as String? : null,
    );
  }
}

class FacultyProfile {
  final String id;
  final String userId;
  final List<String> subjects;
  final String? employeeId;
  final String? department;
  final String? userName;
  final String? userEmail;

  FacultyProfile({
    required this.id,
    required this.userId,
    required this.subjects,
    this.employeeId,
    this.department,
    this.userName,
    this.userEmail,
  });

  factory FacultyProfile.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    return FacultyProfile(
      id: json['_id'] as String,
      userId: (user is Map ? user['_id'] : json['userId']) as String,
      subjects: (json['subjects'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      employeeId: json['employeeId'] as String?,
      department: json['department'] as String?,
      userName: user is Map ? user['name'] as String? : null,
      userEmail: user is Map ? user['email'] as String? : null,
    );
  }
}

class AdminProfile {
  final String id;
  final String userId;
  final String employeeId;
  final String? position;
  final String department;

  AdminProfile({
    required this.id,
    required this.userId,
    required this.employeeId,
    this.position,
    required this.department,
  });

  factory AdminProfile.fromJson(Map<String, dynamic> json) {
    return AdminProfile(
      id: json['_id'] as String,
      userId: (json['userId'] is Map ? (json['userId'] as Map)['_id'] : json['userId']) as String,
      employeeId: json['employeeId'] as String? ?? '',
      position: json['position'] as String?,
      department: json['department'] as String? ?? '',
    );
  }
}
