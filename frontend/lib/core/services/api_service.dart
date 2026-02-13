import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static String? _token;

  static void setToken(String? token) {
    _token = token;
  }

  static Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) headers['Authorization'] = 'Bearer $_token';
    return headers;
  }

  static Future<dynamic> _decodeResponse(http.Response res) async {
    final raw = res.body.trim();
    if (raw.startsWith('<')) {
      throw ApiException(
        message: 'Server returned HTML instead of JSON. Is the backend running at ${ApiConfig.baseUrl.replaceFirst('/api', '')}?',
        statusCode: res.statusCode,
      );
    }
    dynamic body;
    try {
      body = raw.isEmpty ? null : jsonDecode(res.body);
    } catch (e) {
      throw ApiException(
        message: 'Invalid response from server. Check that the API at ${ApiConfig.baseUrl} is the backend, not the app.',
        statusCode: res.statusCode,
      );
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    String message = 'Request failed';
    if (body is Map) {
      message = body['message'] as String? ?? '';
      if (message.isEmpty && body['errors'] is List && (body['errors'] as List).isNotEmpty) {
        final first = (body['errors'] as List).first;
        if (first is Map && first['msg'] != null) message = first['msg'] as String;
      }
      if (message.isEmpty) message = 'Request failed';
    }
    throw ApiException(
      message: message,
      statusCode: res.statusCode,
      code: body is Map ? (body['code'] as String?) : null,
    );
  }

  static Future<Map<String, dynamic>> _handleResponse(http.Response res) async {
    final body = await _decodeResponse(res);
    if (body is Map<String, dynamic>) return body;
    return <String, dynamic>{};
  }

  static Future<List<dynamic>> _handleListResponse(http.Response res) async {
    final body = await _decodeResponse(res);
    if (body is List) return body;
    if (body is Map) {
      if (body['notifications'] is List) return body['notifications'] as List<dynamic>;
      if (body['data'] is List) return body['data'] as List<dynamic>;
      if (body['expenses'] is List) return body['expenses'] as List<dynamic>;
    }
    return [];
  }

  // Auth
  static Future<Map<String, dynamic>> checkEmail(String email) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/auth/check-email').replace(queryParameters: {'email': email}),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> me() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/auth/me'), headers: _headers);
    return _handleResponse(res);
  }

  // Admin-only auth (separate URL; no registration)
  static Future<Map<String, dynamic>> adminLogin(String email, String password) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(res);
  }

  static Future<List<dynamic>> getAdmins() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/admin/admins'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<Map<String, dynamic>> addAdmin(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/admins'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateAdmin(String id, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/admin/admins/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  static Future<void> deleteAdmin(String id) async {
    final res = await http.delete(Uri.parse('${ApiConfig.baseUrl}/admin/admins/$id'), headers: _headers);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      if (res.body.trim().startsWith('<')) {
        throw ApiException(
          message: 'Server returned HTML instead of JSON. Is the backend running at ${ApiConfig.baseUrl.replaceFirst('/api', '')}?',
          statusCode: res.statusCode,
        );
      }
      await _decodeResponse(res); // throws with server message
    }
  }

  // Notifications
  static Future<List<dynamic>> getNotifications() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/notifications'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<Map<String, dynamic>> getUnreadCount() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/notifications/unread-count'), headers: _headers);
    return _handleResponse(res);
  }

  static Future<void> markNotificationRead(String id) async {
    await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/notifications/$id/read'),
      headers: _headers,
    );
  }

  static Future<void> markAllNotificationsRead() async {
    await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/notifications/read-all'),
      headers: _headers,
    );
  }

  // Students (admin + list for faculty)
  static Future<List<dynamic>> getStudents() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/users/students'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<List<dynamic>> getStudentsList() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/users/students-list'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<Map<String, dynamic>> addStudent(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/users/students'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateStudent(String id, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/users/students/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  static Future<void> deleteStudent(String id) async {
    await http.delete(Uri.parse('${ApiConfig.baseUrl}/users/students/$id'), headers: _headers);
  }

  static Future<Map<String, dynamic>> updateMyProfile(Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/users/me/profile'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  // Faculty (admin + list for grievance)
  static Future<List<dynamic>> getFaculty() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/users/faculty'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<List<dynamic>> getFacultyList() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/users/faculty-list'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<Map<String, dynamic>> addFaculty(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/users/faculty'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateFaculty(String id, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/users/faculty/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  static Future<void> deleteFaculty(String id) async {
    await http.delete(Uri.parse('${ApiConfig.baseUrl}/users/faculty/$id'), headers: _headers);
  }

  // Attendance
  static Future<List<dynamic>> getMyAttendance({String? subject, String? from, String? to}) async {
    final q = <String, String>{};
    if (subject != null) q['subject'] = subject;
    if (from != null) q['from'] = from;
    if (to != null) q['to'] = to;
    final uri = Uri.parse('${ApiConfig.baseUrl}/attendance/my').replace(queryParameters: q.isEmpty ? null : q);
    final res = await http.get(uri, headers: _headers);
    return _handleListResponse(res);
  }

  static Future<List<dynamic>> getAttendanceStudents() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/attendance/students'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<List<dynamic>> getAttendanceAdmin({String? studentId, String? subject}) async {
    final q = <String, String>{};
    if (studentId != null) q['studentId'] = studentId;
    if (subject != null) q['subject'] = subject;
    final uri = Uri.parse('${ApiConfig.baseUrl}/attendance').replace(queryParameters: q.isEmpty ? null : q);
    final res = await http.get(uri, headers: _headers);
    return _handleListResponse(res);
  }

  static Future<Map<String, dynamic>> markAttendance(String studentId, String subject, String date, String status) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/attendance/mark'),
      headers: _headers,
      body: jsonEncode({'studentId': studentId, 'subject': subject, 'date': date, 'status': status}),
    );
    return _handleResponse(res);
  }

  static Future<List<dynamic>> bulkMarkAttendance(String subject, String date, List<Map<String, dynamic>> entries) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/attendance/mark/bulk'),
      headers: _headers,
      body: jsonEncode({'subject': subject, 'date': date, 'entries': entries}),
    );
    return _handleListResponse(res);
  }

  // Leaves
  static Future<List<dynamic>> getMyLeaves() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/leaves/my'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<Map<String, dynamic>> applyLeave(String reason, String fromDate, String toDate, {String? medicalCertificateUrl}) async {
    final body = <String, dynamic>{'reason': reason, 'fromDate': fromDate, 'toDate': toDate};
    if (medicalCertificateUrl != null) body['medicalCertificateUrl'] = medicalCertificateUrl;
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/leaves'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  static Future<List<dynamic>> getAllLeaves() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/leaves/all'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<List<dynamic>> getStudentLeavesForFaculty() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/leaves/student-leaves'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<List<dynamic>> getFacultyLeavesForAdmin() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/leaves/faculty-leaves'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<Map<String, dynamic>> reviewLeave(String id, String status) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/leaves/$id/review'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    return _handleResponse(res);
  }

  // Notices
  static Future<List<dynamic>> getNotices({String? type}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/notices').replace(queryParameters: type != null ? {'type': type} : null);
    final res = await http.get(uri, headers: _headers);
    return _handleListResponse(res);
  }

  static Future<Map<String, dynamic>> createNotice(String title, String content, {String type = 'notice'}) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/notices'),
      headers: _headers,
      body: jsonEncode({'title': title, 'content': content, 'type': type}),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateNotice(String id, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/notices/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  static Future<void> deleteNotice(String id) async {
    await http.delete(Uri.parse('${ApiConfig.baseUrl}/notices/$id'), headers: _headers);
  }

  // Fee receipts
  static Future<List<dynamic>> getMyFeeReceipts() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/files/fee-receipts'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<List<dynamic>> getFeeReceiptsAdmin({String? studentId}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/files/fee-receipts/admin').replace(queryParameters: studentId != null ? {'studentId': studentId} : null);
    final res = await http.get(uri, headers: _headers);
    return _handleListResponse(res);
  }

  static Future<Map<String, dynamic>> uploadFeeReceipt(String studentId, List<int> fileBytes, String fileName, {String? title}) async {
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/files/fee-receipts'));
    request.headers['Authorization'] = 'Bearer $_token';
    request.fields['studentId'] = studentId;
    if (title != null) request.fields['title'] = title;
    request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _handleResponse(res);
  }

  // Salary slips
  static Future<List<dynamic>> getMySalarySlips() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/files/salary-slips'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<List<dynamic>> getSalarySlipsAdmin({String? facultyId}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/files/salary-slips/admin').replace(queryParameters: facultyId != null ? {'facultyId': facultyId} : null);
    final res = await http.get(uri, headers: _headers);
    return _handleListResponse(res);
  }

  static Future<Map<String, dynamic>> uploadSalarySlip(String facultyId, List<int> fileBytes, String fileName, {String? title}) async {
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/files/salary-slips'));
    request.headers['Authorization'] = 'Bearer $_token';
    request.fields['facultyId'] = facultyId;
    if (title != null) request.fields['title'] = title;
    request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _handleResponse(res);
  }

  // Certificates
  static Future<List<dynamic>> getMyCertificates() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/files/certificates'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<Map<String, dynamic>> uploadCertificate(List<int> fileBytes, String fileName, {String? title}) async {
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/files/certificates'));
    request.headers['Authorization'] = 'Bearer $_token';
    if (title != null) request.fields['title'] = title;
    request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _handleResponse(res);
  }

  // Timetable
  static Future<Map<String, dynamic>> getTimetable() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/timetable'), headers: _headers);
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> getMyTimetable() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/timetable/my'), headers: _headers);
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> createTimetableEntry(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/timetable'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateTimetableEntry(String id, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/timetable/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  static Future<void> deleteTimetableEntry(String id) async {
    await http.delete(Uri.parse('${ApiConfig.baseUrl}/timetable/$id'), headers: _headers);
  }

  // Complaints
  static Future<List<dynamic>> getMyComplaints() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/complaints/my'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<Map<String, dynamic>> submitComplaint(String subject, String description, {String? attachmentUrl}) async {
    final body = <String, dynamic>{'subject': subject, 'description': description};
    if (attachmentUrl != null && attachmentUrl.isNotEmpty) body['attachmentUrl'] = attachmentUrl;
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/complaints'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  static Future<List<dynamic>> getAllComplaints() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/complaints/all'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<Map<String, dynamic>> updateComplaint(String id, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/complaints/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  // Expenses
  static Future<Map<String, dynamic>> getExpenses() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/expenses'), headers: _headers);
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> addExpense(String description, double amount, {String? category}) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/expenses'),
      headers: _headers,
      body: jsonEncode({'description': description, 'amount': amount, 'category': category ?? ''}),
    );
    return _handleResponse(res);
  }

  static Future<void> deleteExpense(String id) async {
    await http.delete(Uri.parse('${ApiConfig.baseUrl}/expenses/$id'), headers: _headers);
  }

  // Admin notifications
  static Future<Map<String, dynamic>> sendNotificationToAll(String message) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/notifications/admin/send-all'),
      headers: _headers,
      body: jsonEncode({'message': message}),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> sendNotificationToStudents(String message) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/notifications/admin/send-students'),
      headers: _headers,
      body: jsonEncode({'message': message}),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> sendNotificationToFaculty(String message) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/notifications/admin/send-faculty'),
      headers: _headers,
      body: jsonEncode({'message': message}),
    );
    return _handleResponse(res);
  }

  // Stats
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/stats/dashboard'), headers: _headers);
    return _handleResponse(res);
  }

  // Attendance grievances
  static Future<List<dynamic>> getMyGrievances() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/grievances/my'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<List<dynamic>> getGrievancesForFaculty() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/grievances/faculty'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<Map<String, dynamic>> createGrievance(String facultyId, String subject, String date, {String? comments, List<int>? proofFileBytes, String? proofFileName}) async {
    if (proofFileBytes != null && proofFileName != null) {
      final request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/grievances'));
      request.headers['Authorization'] = 'Bearer $_token';
      request.fields['facultyId'] = facultyId;
      request.fields['subject'] = subject;
      request.fields['date'] = date;
      if (comments != null) request.fields['comments'] = comments;
      request.files.add(http.MultipartFile.fromBytes('proof', proofFileBytes, filename: proofFileName));
      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      return _handleResponse(res);
    }
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/grievances'),
      headers: _headers,
      body: jsonEncode({'facultyId': facultyId, 'subject': subject, 'date': date, 'comments': comments ?? ''}),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> reviewGrievance(String id, String status) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/grievances/$id/review'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    return _handleResponse(res);
  }

  // Fee payments (dummy flow)
  static Future<Map<String, dynamic>> createFeePayment(double amount, {String? academicYear}) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/fee-payments'),
      headers: _headers,
      body: jsonEncode({'amount': amount, 'academicYear': academicYear ?? ''}),
    );
    return _handleResponse(res);
  }

  static Future<List<dynamic>> getMyFeePayments() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/fee-payments/my'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<List<dynamic>> getFeePaymentsForAdmin() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/fee-payments/admin'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<Map<String, dynamic>> approveFeePayment(String id, String status) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/fee-payments/$id/approve'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    return _handleResponse(res);
  }

  // Fee receipt requests
  static Future<Map<String, dynamic>> createFeeReceiptRequest({String? reason}) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/fee-receipt-requests'),
      headers: _headers,
      body: jsonEncode({'reason': reason ?? ''}),
    );
    return _handleResponse(res);
  }

  static Future<List<dynamic>> getMyFeeReceiptRequests() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/fee-receipt-requests/my'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<List<dynamic>> getFeeReceiptRequestsForAdmin() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/fee-receipt-requests/admin'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<Map<String, dynamic>> approveFeeReceiptRequest(String id, String status, {String? receiptUrl}) async {
    final body = <String, dynamic>{'status': status};
    if (receiptUrl != null) body['receiptUrl'] = receiptUrl;
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/fee-receipt-requests/$id/approve'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  // Marks
  static Future<List<dynamic>> getMyMarks() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/marks/my'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<Map<String, dynamic>> uploadMarks(String studentId, String subject, num marks, {String? examType, num? maxMarks}) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/marks'),
      headers: _headers,
      body: jsonEncode({'studentId': studentId, 'subject': subject, 'marks': marks, 'examType': examType ?? '', 'maxMarks': maxMarks ?? 100}),
    );
    return _handleResponse(res);
  }

  // ID card requests
  static Future<Map<String, dynamic>> createIdCardRequest(String issueType, {String? description, String? attachmentUrl}) async {
    final body = <String, dynamic>{'issueType': issueType, 'description': description ?? ''};
    if (attachmentUrl != null && attachmentUrl.isNotEmpty) body['attachmentUrl'] = attachmentUrl;
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/id-card-requests'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  static Future<List<dynamic>> getMyIdCardRequests() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/id-card-requests/my'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<List<dynamic>> getIdCardRequestsForAdmin() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/id-card-requests/admin'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<Map<String, dynamic>> resolveIdCardRequest(String id, {String? adminResponse}) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/id-card-requests/$id/resolve'),
      headers: _headers,
      body: jsonEncode({'adminResponse': adminResponse ?? ''}),
    );
    return _handleResponse(res);
  }

  // Budgets
  static Future<List<dynamic>> getBudgets() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/budgets'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<Map<String, dynamic>> createBudget(String department, double amount, {String? purpose, String? documentUrl}) async {
    final body = <String, dynamic>{'department': department, 'amount': amount, 'purpose': purpose ?? ''};
    if (documentUrl != null && documentUrl.isNotEmpty) body['documentUrl'] = documentUrl;
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/budgets'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> approveBudget(String id, String status) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/budgets/$id/approve'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    return _handleResponse(res);
  }

  // Meetings
  static Future<List<dynamic>> getMeetings() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/meetings'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<Map<String, dynamic>> createMeeting(String title, String scheduledAt, {String? description, String? department}) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/meetings'),
      headers: _headers,
      body: jsonEncode({'title': title, 'scheduledAt': scheduledAt, 'description': description ?? '', 'department': department ?? ''}),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateMeeting(String id, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/meetings/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  static Future<void> deleteMeeting(String id) async {
    await http.delete(Uri.parse('${ApiConfig.baseUrl}/meetings/$id'), headers: _headers);
  }

  static Future<String> uploadLeaveMedicalCert(List<int> fileBytes, String fileName) async {
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/files/leave-medical-cert'));
    request.headers['Authorization'] = 'Bearer $_token';
    request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final data = await _handleResponse(res);
    return (data['url'] as String?) ?? '';
  }

  static Future<String> uploadComplaintAttachment(List<int> fileBytes, String fileName) async {
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/files/complaint-attachment'));
    request.headers['Authorization'] = 'Bearer $_token';
    request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final data = await _handleResponse(res);
    return (data['url'] as String?) ?? '';
  }

  static Future<String> uploadBudgetDocument(List<int> fileBytes, String fileName) async {
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/files/budget-document'));
    request.headers['Authorization'] = 'Bearer $_token';
    request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final data = await _handleResponse(res);
    return (data['url'] as String?) ?? '';
  }

  static Future<String> uploadIdCardAttachment(List<int> fileBytes, String fileName) async {
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/files/id-card-attachment'));
    request.headers['Authorization'] = 'Bearer $_token';
    request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final data = await _handleResponse(res);
    return (data['url'] as String?) ?? '';
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String? code;
  ApiException({required this.message, required this.statusCode, this.code});
  @override
  String toString() => message;
}
