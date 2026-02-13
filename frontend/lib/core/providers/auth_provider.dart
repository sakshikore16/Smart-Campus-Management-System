import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  StudentProfile? _studentProfile;
  FacultyProfile? _facultyProfile;
  AdminProfile? _adminProfile;
  String? _token;
  String? _error;
  String? _emailNotFound; // when set, UI should redirect to register with this email
  bool _loading = false;

  UserModel? get user => _user;
  StudentProfile? get studentProfile => _studentProfile;
  FacultyProfile? get facultyProfile => _facultyProfile;
  AdminProfile? get adminProfile => _adminProfile;
  String? get token => _token;
  String? get error => _error;
  String? get emailNotFound => _emailNotFound;
  bool get loading => _loading;
  bool get isLoggedIn => _token != null && _user != null;

  void setToken(String? t) {
    _token = t;
    ApiService.setToken(t);
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      final data = await ApiService.checkEmail(email.trim());
      return (data['exists'] as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    _emailNotFound = null;
    notifyListeners();
    try {
      final data = await ApiService.login(email, password);
      _token = data['token'] as String?;
      if (_token != null) ApiService.setToken(_token);
      _user = data['user'] != null ? UserModel.fromJson(data['user'] as Map<String, dynamic>) : null;
      _studentProfile = null;
      _facultyProfile = null;
      _adminProfile = null;
      if (data['profile'] != null) {
        final p = data['profile'] as Map<String, dynamic>;
        if (_user?.role == 'student') {
          _studentProfile = StudentProfile.fromJson(p);
        } else if (_user?.role == 'faculty') {
          _facultyProfile = FacultyProfile.fromJson(p);
        } else if (_user?.role == 'admin') {
          _adminProfile = AdminProfile.fromJson(p);
        }
      }
      _loading = false;
      notifyListeners();
      return _user != null;
    } on ApiException catch (e) {
      _error = e.message;
      if (e.code == 'EMAIL_NOT_FOUND') _emailNotFound = email.trim();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Admin-only login (separate URL). Use for /admin-login; no registration.
  Future<bool> adminLogin(String email, String password) async {
    _loading = true;
    _error = null;
    _emailNotFound = null;
    notifyListeners();
    try {
      final data = await ApiService.adminLogin(email, password);
      _token = data['token'] as String?;
      if (_token != null) ApiService.setToken(_token);
      _user = data['user'] != null ? UserModel.fromJson(data['user'] as Map<String, dynamic>) : null;
      _studentProfile = null;
      _facultyProfile = null;
      _adminProfile = null;
      if (data['profile'] != null && _user?.role == 'admin') {
        _adminProfile = AdminProfile.fromJson(data['profile'] as Map<String, dynamic>);
      }
      _loading = false;
      notifyListeners();
      return _user != null && _user!.role == 'admin';
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerAndLogin(Map<String, dynamic> body) async {
    _loading = true;
    _error = null;
    _emailNotFound = null;
    notifyListeners();
    try {
      final data = await ApiService.register(body);
      _token = data['token'] as String?;
      if (_token != null) ApiService.setToken(_token);
      _user = data['user'] != null ? UserModel.fromJson(data['user'] as Map<String, dynamic>) : null;
      _studentProfile = null;
      _facultyProfile = null;
      _adminProfile = null;
      if (data['profile'] != null) {
        final p = data['profile'] as Map<String, dynamic>;
        if (_user?.role == 'student') {
          _studentProfile = StudentProfile.fromJson(p);
        } else if (_user?.role == 'faculty') {
          _facultyProfile = FacultyProfile.fromJson(p);
        } else if (_user?.role == 'admin') {
          _adminProfile = AdminProfile.fromJson(p);
        }
      }
      _loading = false;
      notifyListeners();
      return _user != null;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchMe() async {
    if (_token == null) return;
    try {
      final data = await ApiService.me();
      _user = data['user'] != null ? UserModel.fromJson(data['user'] as Map<String, dynamic>) : null;
      _studentProfile = null;
      _facultyProfile = null;
      _adminProfile = null;
      if (data['profile'] != null) {
        final p = data['profile'] as Map<String, dynamic>;
        if (_user?.role == 'student') {
          _studentProfile = StudentProfile.fromJson(p);
        } else if (_user?.role == 'faculty') {
          _facultyProfile = FacultyProfile.fromJson(p);
        } else if (_user?.role == 'admin') {
          _adminProfile = AdminProfile.fromJson(p);
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  void clearEmailNotFound() {
    _emailNotFound = null;
    notifyListeners();
  }

  void logout() {
    _user = null;
    _studentProfile = null;
    _facultyProfile = null;
    _adminProfile = null;
    _token = null;
    _error = null;
    _emailNotFound = null;
    ApiService.setToken(null);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
