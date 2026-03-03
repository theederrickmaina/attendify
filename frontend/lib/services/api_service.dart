import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decode/jwt_decode.dart';

class ApiService {
  static String _baseUrl = 'http://localhost:5000';
  static const String _tokenKey = 'attendify_token';

  /// Override the backend URL (e.g., for Android device testing).
  static void setBaseUrl(String url) => _baseUrl = url;

  String? _token;
  Map<String, dynamic>? _userData;

  // ── Token management ──────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    if (_token != null) {
      try {
        _userData = Jwt.parseJwt(_token!);
      } catch (_) {
        _token = null;
      }
    }
  }

  bool get isLoggedIn => _token != null;
  String? get token => _token;
  String get role => _userData?['role'] ?? '';
  String get username => _userData?['username'] ?? '';
  String get fullName => _userData?['name'] ?? '';
  int get userId => int.tryParse(_userData?['sub']?.toString() ?? '') ?? 0;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<void> _saveToken(String token) async {
    _token = token;
    _userData = Jwt.parseJwt(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    _userData = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ── Kiosk session persistence ──────────────────────────────────────
  static const String _kioskModeKey = 'attendify_kiosk_mode';
  static const String _kioskUserKey = 'attendify_kiosk_user';
  static const String _kioskPassKey = 'attendify_kiosk_pass';

  /// Check if this device is in persistent kiosk mode.
  Future<bool> isKioskMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kioskModeKey) ?? false;
  }

  /// Activate kiosk mode — login with admin creds, persist session.
  Future<Map<String, dynamic>> activateKioskMode(String username, String password) async {
    final r = await login(username, password);
    if (r['_ok'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kioskModeKey, true);
      await prefs.setString(_kioskUserKey, username);
      await prefs.setString(_kioskPassKey, password);
    }
    return r;
  }

  /// Re-authenticate kiosk session (e.g., after token expiry).
  Future<bool> refreshKioskSession() async {
    final prefs = await SharedPreferences.getInstance();
    final u = prefs.getString(_kioskUserKey);
    final p = prefs.getString(_kioskPassKey);
    if (u == null || p == null) return false;
    final r = await login(u, p);
    return r['_ok'] == true;
  }

  /// Verify the kiosk admin password for protected logout.
  Future<bool> verifyKioskPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPass = prefs.getString(_kioskPassKey);
    return storedPass == password;
  }

  /// Deactivate kiosk mode — clears kiosk persistence + token.
  Future<void> deactivateKioskMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kioskModeKey);
    await prefs.remove(_kioskUserKey);
    await prefs.remove(_kioskPassKey);
    await clearToken();
  }

  // ── HTTP helpers ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _get(String path) async {
    final r = await http.get(Uri.parse('$_baseUrl$path'), headers: _headers);
    return _parse(r);
  }

  Future<Map<String, dynamic>> _post(String path, [Map<String, dynamic>? body]) async {
    final r = await http.post(Uri.parse('$_baseUrl$path'),
        headers: _headers, body: body != null ? jsonEncode(body) : null);
    return _parse(r);
  }

  Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) async {
    final r = await http.put(Uri.parse('$_baseUrl$path'),
        headers: _headers, body: jsonEncode(body));
    return _parse(r);
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final r = await http.delete(Uri.parse('$_baseUrl$path'), headers: _headers);
    return _parse(r);
  }

  Map<String, dynamic> _parse(http.Response r) {
    final body = r.body.isNotEmpty ? jsonDecode(r.body) as Map<String, dynamic> : <String, dynamic>{};
    body['_statusCode'] = r.statusCode;
    body['_ok'] = r.statusCode >= 200 && r.statusCode < 300;
    return body;
  }

  // ── Auth ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String username, String password) async {
    final r = await _post('/api/auth/login', {'username': username, 'password': password});
    if (r['_ok'] == true && r['access_token'] != null) {
      await _saveToken(r['access_token']);
    }
    return r;
  }

  Future<Map<String, dynamic>> changePassword(String currentPw, String newPw) =>
      _post('/api/auth/change-password', {'current_password': currentPw, 'new_password': newPw});

  Future<Map<String, dynamic>> getMe() => _get('/api/auth/me');

  // ── Admin ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getAdminDashboard() => _get('/api/admin/dashboard');
  Future<Map<String, dynamic>> getUsers({String? role, String? q}) {
    final params = <String>[];
    if (role != null) params.add('role=$role');
    if (q != null && q.isNotEmpty) params.add('q=$q');
    final qs = params.isNotEmpty ? '?${params.join('&')}' : '';
    return _get('/api/admin/users$qs');
  }
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) => _post('/api/admin/users', data);
  Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> data) => _put('/api/admin/users/$id', data);
  Future<Map<String, dynamic>> deleteUser(int id) => _delete('/api/admin/users/$id');

  Future<Map<String, dynamic>> getDepartments() => _get('/api/admin/departments');
  Future<Map<String, dynamic>> createDepartment(Map<String, dynamic> data) => _post('/api/admin/departments', data);
  Future<Map<String, dynamic>> updateDepartment(int id, Map<String, dynamic> data) => _put('/api/admin/departments/$id', data);
  Future<Map<String, dynamic>> deleteDepartment(int id) => _delete('/api/admin/departments/$id');

  Future<Map<String, dynamic>> getCourses() => _get('/api/admin/courses');
  Future<Map<String, dynamic>> createCourse(Map<String, dynamic> data) => _post('/api/admin/courses', data);
  Future<Map<String, dynamic>> updateCourse(int id, Map<String, dynamic> data) => _put('/api/admin/courses/$id', data);
  Future<Map<String, dynamic>> deleteCourse(int id) => _delete('/api/admin/courses/$id');

  Future<Map<String, dynamic>> getUnits({int? courseId}) {
    final qs = courseId != null ? '?course_id=$courseId' : '';
    return _get('/api/admin/units$qs');
  }
  Future<Map<String, dynamic>> createUnit(Map<String, dynamic> data) => _post('/api/admin/units', data);
  Future<Map<String, dynamic>> updateUnit(int id, Map<String, dynamic> data) => _put('/api/admin/units/$id', data);
  Future<Map<String, dynamic>> deleteUnit(int id) => _delete('/api/admin/units/$id');

  Future<Map<String, dynamic>> getCourseUnits({int? courseId, int? unitId}) {
    final params = <String>[];
    if (courseId != null) params.add('course_id=$courseId');
    if (unitId != null) params.add('unit_id=$unitId');
    final qs = params.isNotEmpty ? '?${params.join('&')}' : '';
    return _get('/api/admin/course-units$qs');
  }
  Future<Map<String, dynamic>> addCourseUnit(Map<String, dynamic> data) =>
      _post('/api/admin/course-units', data);
  Future<Map<String, dynamic>> deleteCourseUnit(int id) => _delete('/api/admin/course-units/$id');

  Future<Map<String, dynamic>> getStudents({String? q, int? courseId, bool? unregistered}) {
    final params = <String>[];
    if (q != null && q.isNotEmpty) params.add('q=$q');
    if (courseId != null) params.add('course_id=$courseId');
    if (unregistered == true) params.add('unregistered=true');
    final qs = params.isNotEmpty ? '?${params.join('&')}' : '';
    return _get('/api/admin/students$qs');
  }

  Future<Map<String, dynamic>> enrollFace(int studentId, String imageBase64) =>
      _post('/api/admin/students/$studentId/face', {'image': imageBase64});

  Future<Map<String, dynamic>> getLecturerUnits() => _get('/api/admin/lecturer-units');
  Future<Map<String, dynamic>> assignLecturerUnit(Map<String, dynamic> data) =>
      _post('/api/admin/lecturer-units', data);
  Future<Map<String, dynamic>> deleteLecturerUnit(int id) => _delete('/api/admin/lecturer-units/$id');

  Future<Map<String, dynamic>> getDevices() => _get('/api/admin/devices');
  Future<Map<String, dynamic>> createDevice(Map<String, dynamic> data) => _post('/api/admin/devices', data);

  Future<Map<String, dynamic>> getReports() => _get('/api/admin/reports');
  Future<Map<String, dynamic>> getAuditLog({int limit = 50}) => _get('/api/admin/audit-log?limit=$limit');
  Future<Map<String, dynamic>> getAnnouncements() => _get('/api/announcements');
  Future<Map<String, dynamic>> createAnnouncement(Map<String, dynamic> data) =>
      _post('/api/admin/announcements', data);

  // ── Lecturer ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getLecturerDashboard() => _get('/api/lecturer/dashboard');
  Future<Map<String, dynamic>> getLecturerMyUnits() => _get('/api/lecturer/units');
  Future<Map<String, dynamic>> getLecturerSessions() => _get('/api/lecturer/sessions');
  Future<Map<String, dynamic>> createSession(Map<String, dynamic> data) =>
      _post('/api/lecturer/sessions', data);
  Future<Map<String, dynamic>> updateSession(int id, Map<String, dynamic> data) =>
      _put('/api/lecturer/sessions/$id', data);
  Future<Map<String, dynamic>> deleteSession(int id) => _delete('/api/lecturer/sessions/$id');
  Future<Map<String, dynamic>> getSessionAttendance(int sessionId) =>
      _get('/api/lecturer/sessions/$sessionId/attendance');
  Future<Map<String, dynamic>> getUnitStudents(int unitId) =>
      _get('/api/lecturer/unit/$unitId/students');

  // ── Student ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getStudentDashboard() => _get('/api/student/dashboard');
  Future<Map<String, dynamic>> getStudentAttendance() => _get('/api/student/attendance');
  Future<Map<String, dynamic>> updateConsent(bool consent) =>
      _post('/api/student/consent', {'consent': consent});

  // ── Student unit enrollment ─────────────────────────────────────────
  Future<Map<String, dynamic>> getAvailableUnits() => _get('/api/student/available-units');
  Future<Map<String, dynamic>> getMyUnits() => _get('/api/student/my-units');
  Future<Map<String, dynamic>> enrollUnit(int unitId) =>
      _post('/api/student/enroll-unit', {'unit_id': unitId});
  Future<Map<String, dynamic>> dropUnit(int enrollmentId) =>
      _delete('/api/student/drop-unit/$enrollmentId');

  // ── Shared ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> recognize(String imageBase64, {bool autoMark = false}) =>
      _post('/api/recognize', {'image': imageBase64, 'auto_mark': autoMark});
}
