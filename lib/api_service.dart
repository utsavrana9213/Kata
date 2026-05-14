import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:servekeen/service_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // TODO: Replace with your actual website URL
  // We assume your domain is servekeen.com based on your folder structure
  static const String _baseUrl = 'https://servekeen.com/api/get_app_data.php';

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _sellerKey = 'seller_onboarded';

  // Store authentication token and current user
  static String? _authToken;
  static Map<String, dynamic>? _currentUser;
  static bool _sellerOnboarded = false;

  static bool _isTestCredential(String value) =>
      value.trim().toLowerCase() == 'test';

  Future<Map<String, dynamic>> _signInTestUser() async {
    _authToken = 'test_token';
    _currentUser = {
      'id': 'test',
      'name': 'Test User',
      'username': 'test',
      'email': 'test',
      'mobile': 'test',
      'role': 'user',
    };
    if (_sellerOnboarded) {
      _currentUser!['role'] = 'seller';
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _authToken!);
    await prefs.setString(_userKey, json.encode(_currentUser));

    return {'status': 'success', 'token': _authToken, 'user': _currentUser};
  }

  static void _debug(String message) {
    if (kDebugMode) debugPrint(message);
  }

  static const List<String> _apiCandidates = [
    'https://servekeen.com/api',
    'https://www.servekeen.com/api',
    'http://servekeen.com/api',
    'http://www.servekeen.com/api',
    'http://10.0.2.2:8000/api',
    'http://localhost:8000/api',
  ];

  Future<http.Response> _postJsonResilient(
    String path,
    Map<String, dynamic> payload,
  ) async {
    http.Response? lastResponse;
    for (final base in _apiCandidates) {
      final url = Uri.parse('$base/$path');
      try {
        final resp = await http
            .post(
              url,
              body: json.encode(payload),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 12));
        if ((resp.statusCode == 200 && resp.body.trim().isNotEmpty) ||
            resp.body.trim().isNotEmpty) {
          return resp;
        }
        lastResponse = resp;
      } catch (e) {
        _debug('POST $url failed: $e');
      }
    }
    if (lastResponse != null) return lastResponse;
    throw Exception('All API endpoints unreachable');
  }

  // Initialize session
  static Future<void> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString(_tokenKey);
      final userStr = prefs.getString(_userKey);
      if (userStr != null) {
        _currentUser = json.decode(userStr);
      }
      _sellerOnboarded = prefs.getBool(_sellerKey) ?? false;
      if (_sellerOnboarded && _currentUser != null) {
        _currentUser!['role'] = 'seller';
      }
      _debug(
        'Session loaded: Token=${_authToken != null}, User=${_currentUser != null}',
      );
    } catch (e) {
      _debug('Error loading session: $e');
    }
  }

  // Authentication methods - Using final working APIs
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      if (_isTestCredential(email) && _isTestCredential(password)) {
        return await _signInTestUser();
      }

      _debug('Attempting login with email: $email');
      final response = await _postJsonResilient('auth_final.php', {
        'email': email,
        'password': password,
      });

      _debug('Login response status: ${response.statusCode}');
      _debug('Login response body: ${response.body}');

      final body = response.body.trim();
      if (body.isEmpty) {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode} (empty response)',
        };
      }
      if (body.startsWith('<')) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        final cleanSnippet = snippet.replaceAll(RegExp(r'<[^>]*>'), '');
        return {'status': 'error', 'message': 'Backend Error: $cleanSnippet'};
      }

      Map<String, dynamic> data;
      try {
        data = json.decode(body) as Map<String, dynamic>;
      } catch (e) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}. Response: $snippet',
        };
      }

      if (response.statusCode != 200) {
        final rawMsg = data['message'] ?? data['error'];
        if (rawMsg == null || rawMsg.toString().trim().isEmpty) {
          final snippet = body.length > 200
              ? '${body.substring(0, 200)}...'
              : body;
          return {
            'status': 'error',
            'message':
                'Server error: ${response.statusCode}. Response: $snippet',
          };
        }
        return {'status': 'error', 'message': rawMsg.toString()};
      }
      if (data['status'] == 'success' && data['user'] != null) {
        _authToken = data['token'] ?? 'demo_token';
        _currentUser = data['user'];
        if (_sellerOnboarded) {
          _currentUser!['role'] = 'seller';
        }

        // Persist session
        final prefs = await SharedPreferences.getInstance();
        if (_authToken != null) {
          await prefs.setString(_tokenKey, _authToken!);
        }
        if (_currentUser != null) {
          await prefs.setString(_userKey, json.encode(_currentUser));
        }
      }

      return data;
    } catch (e) {
      _debug('Login error: $e');
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> vendorLogin(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('https://servekeen.com/api/vendor_login.php'),
        body: json.encode({'email': email, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      );
      final body = response.body.trim();
      if (body.isEmpty) {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode} (empty response)',
        };
      }
      if (body.startsWith('<')) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        final cleanSnippet = snippet.replaceAll(RegExp(r'<[^>]*>'), '');
        return {'status': 'error', 'message': 'Backend Error: $cleanSnippet'};
      }

      Map<String, dynamic> data;
      try {
        final decoded = json.decode(body);
        data = decoded is Map<String, dynamic>
            ? decoded
            : {'status': 'error', 'message': 'Invalid response'};
      } catch (_) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}. Response: $snippet',
        };
      }

      if (data['status'] == 'success' && data['user'] != null) {
        _authToken = data['token'];
        _currentUser = data['user'];
        _sellerOnboarded = true;
        _currentUser!['role'] = 'seller';
        final prefs = await SharedPreferences.getInstance();
        if (_authToken != null) await prefs.setString(_tokenKey, _authToken!);
        if (_currentUser != null)
          await prefs.setString(_userKey, json.encode(_currentUser));
        await prefs.setBool(_sellerKey, true);
      }

      return data;
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> adminLogin(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('https://servekeen.com/api/admin_login.php'),
        body: json.encode({'email': email, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      );
      final body = response.body.trim();
      if (body.isEmpty) {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode} (empty response)',
        };
      }
      if (body.startsWith('<')) {
        final snippet = body.length > 250
            ? '${body.substring(0, 250)}...'
            : body;
        final cleanSnippet = snippet.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        final lower = cleanSnippet.toLowerCase();
        if (response.statusCode == 404 ||
            lower.contains('not found') ||
            lower.contains('no backend')) {
          return {
            'status': 'error',
            'message':
                'Admin login API not found on server. Upload admin_login.php to /api/admin_login.php (HTTP ${response.statusCode}).',
          };
        }
        return {
          'status': 'error',
          'message':
              'Backend Error (HTTP ${response.statusCode}): $cleanSnippet',
        };
      }

      Map<String, dynamic> data;
      try {
        final decoded = json.decode(body);
        data = decoded is Map<String, dynamic>
            ? decoded
            : {'status': 'error', 'message': 'Invalid response'};
      } catch (_) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}. Response: $snippet',
        };
      }

      final userPayload = data['user'] ?? data['admin'] ?? data['data'];
      if (data['status'] == 'success' && userPayload is Map) {
        _authToken = data['token'];
        _currentUser = userPayload.cast<String, dynamic>();
        _sellerOnboarded = false;
        _currentUser!['role'] = 'admin';
        final prefs = await SharedPreferences.getInstance();
        if (_authToken != null) await prefs.setString(_tokenKey, _authToken!);
        if (_currentUser != null)
          await prefs.setString(_userKey, json.encode(_currentUser));
        await prefs.setBool(_sellerKey, false);
      }

      return data;
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> adminSignup(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('https://servekeen.com/api/admin_signup.php'),
        body: json.encode({'name': name, 'email': email, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      );
      final body = response.body.trim();
      if (body.isEmpty) {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode} (empty response)',
        };
      }
      if (body.startsWith('<')) {
        final snippet = body.length > 250
            ? '${body.substring(0, 250)}...'
            : body;
        final cleanSnippet = snippet.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        final lower = cleanSnippet.toLowerCase();
        if (response.statusCode == 404 ||
            lower.contains('not found') ||
            lower.contains('no backend')) {
          return {
            'status': 'error',
            'message':
                'Admin signup API not found on server. Upload admin_signup.php to /api/admin_signup.php (HTTP ${response.statusCode}).',
          };
        }
        return {
          'status': 'error',
          'message':
              'Backend Error (HTTP ${response.statusCode}): $cleanSnippet',
        };
      }

      if (!(body.startsWith('{') || body.startsWith('['))) {
        final snippet = body.length > 160
            ? '${body.substring(0, 160)}...'
            : body;
        return {
          'status': 'error',
          'message':
              'Admin signup API is not returning JSON. Make sure /api/admin_signup.php contains PHP code and starts with "<?php". Response: $snippet',
        };
      }

      Map<String, dynamic> data;
      try {
        final decoded = json.decode(body);
        data = decoded is Map<String, dynamic>
            ? decoded
            : {'status': 'error', 'message': 'Invalid response'};
      } catch (_) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}. Response: $snippet',
        };
      }

      final userPayload = data['user'] ?? data['admin'] ?? data['data'];
      if (data['status'] == 'success' && userPayload is Map) {
        _authToken = data['token'];
        _currentUser = userPayload.cast<String, dynamic>();
        _sellerOnboarded = false;
        _currentUser!['role'] = 'admin';
        final prefs = await SharedPreferences.getInstance();
        if (_authToken != null) await prefs.setString(_tokenKey, _authToken!);
        if (_currentUser != null)
          await prefs.setString(_userKey, json.encode(_currentUser));
        await prefs.setBool(_sellerKey, false);
      }

      return data;
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> fetchPendingVendorSignupRequests() async {
    if (_authToken == null || _currentUser == null) {
      return {'status': 'error', 'message': 'No active session'};
    }
    if ((_currentUser?['role'] ?? '').toString() != 'admin') {
      return {'status': 'error', 'message': 'Unauthorized'};
    }

    try {
      final payload = <String, dynamic>{
        'token': _authToken,
        'admin_id': _currentUser?['id']?.toString() ?? '',
      };

      final response = await http.post(
        Uri.parse('https://servekeen.com/api/admin_vendor_signup_requests.php'),
        body: json.encode(payload),
        headers: {'Content-Type': 'application/json'},
      );

      final body = response.body.trim();
      if (body.isEmpty) {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode} (empty response)',
        };
      }
      if (body.startsWith('<')) {
        final snippet = body.length > 250
            ? '${body.substring(0, 250)}...'
            : body;
        final cleanSnippet = snippet.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        return {
          'status': 'error',
          'message':
              'Backend Error (HTTP ${response.statusCode}): $cleanSnippet',
        };
      }
      try {
        final decoded = json.decode(body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {'status': 'error', 'message': 'Invalid response'};
      } catch (_) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}. Response: $snippet',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> approveVendorSignupRequest({
    required String vendorId,
  }) async {
    if (_authToken == null || _currentUser == null) {
      return {'status': 'error', 'message': 'No active session'};
    }
    if ((_currentUser?['role'] ?? '').toString() != 'admin') {
      return {'status': 'error', 'message': 'Unauthorized'};
    }
    if (vendorId.trim().isEmpty) {
      return {'status': 'error', 'message': 'Invalid vendor id'};
    }

    try {
      final payload = <String, dynamic>{
        'token': _authToken,
        'admin_id': _currentUser?['id']?.toString() ?? '',
        'vendor_id': vendorId.trim(),
        'action': 'approve',
      };

      final response = await http.post(
        Uri.parse('https://servekeen.com/api/admin_vendor_signup_action.php'),
        body: json.encode(payload),
        headers: {'Content-Type': 'application/json'},
      );

      final body = response.body.trim();
      if (body.isEmpty) {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode} (empty response)',
        };
      }
      if (body.startsWith('<')) {
        final snippet = body.length > 250
            ? '${body.substring(0, 250)}...'
            : body;
        final cleanSnippet = snippet.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        return {
          'status': 'error',
          'message':
              'Backend Error (HTTP ${response.statusCode}): $cleanSnippet',
        };
      }
      try {
        final decoded = json.decode(body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {'status': 'error', 'message': 'Invalid response'};
      } catch (_) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}. Response: $snippet',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> rejectVendorSignupRequest({
    required String vendorId,
  }) async {
    if (_authToken == null || _currentUser == null) {
      return {'status': 'error', 'message': 'No active session'};
    }
    if ((_currentUser?['role'] ?? '').toString() != 'admin') {
      return {'status': 'error', 'message': 'Unauthorized'};
    }
    if (vendorId.trim().isEmpty) {
      return {'status': 'error', 'message': 'Invalid vendor id'};
    }

    try {
      final payload = <String, dynamic>{
        'token': _authToken,
        'admin_id': _currentUser?['id']?.toString() ?? '',
        'vendor_id': vendorId.trim(),
        'action': 'reject',
      };

      final response = await http.post(
        Uri.parse('https://servekeen.com/api/admin_vendor_signup_action.php'),
        body: json.encode(payload),
        headers: {'Content-Type': 'application/json'},
      );

      final body = response.body.trim();
      if (body.isEmpty) {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode} (empty response)',
        };
      }
      if (body.startsWith('<')) {
        final snippet = body.length > 250
            ? '${body.substring(0, 250)}...'
            : body;
        final cleanSnippet = snippet.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        return {
          'status': 'error',
          'message':
              'Backend Error (HTTP ${response.statusCode}): $cleanSnippet',
        };
      }
      try {
        final decoded = json.decode(body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {'status': 'error', 'message': 'Invalid response'};
      } catch (_) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}. Response: $snippet',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> sendSupportTicket({
    required String subject,
    required String message,
    String? userId,
    String? userEmail,
    String? userMobile,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://servekeen.com/api/support_ticket.php'),
        body: json.encode({
          'subject': subject,
          'message': message,
          if (userId != null && userId.trim().isNotEmpty) 'user_id': userId,
          if (userEmail != null && userEmail.trim().isNotEmpty)
            'user_email': userEmail,
          if (userMobile != null && userMobile.trim().isNotEmpty)
            'user_mobile': userMobile,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      final body = response.body.trim();
      if (body.isEmpty) {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode} (empty response)',
        };
      }
      if (body.startsWith('<')) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        final cleanSnippet = snippet.replaceAll(RegExp(r'<[^>]*>'), '');
        return {'status': 'error', 'message': 'Backend Error: $cleanSnippet'};
      }
      try {
        final decoded = json.decode(body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {'status': 'error', 'message': 'Invalid response'};
      } catch (_) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}. Response: $snippet',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> createService(
    Map<String, dynamic> serviceData,
  ) async {
    try {
      final payload = Map<String, dynamic>.from(serviceData);
      payload['token'] = _authToken;
      if (_currentUser != null &&
          (_currentUser!['id'] ?? '').toString().isNotEmpty) {
        payload['user_id'] = _currentUser!['id'].toString();
      }
      if (_currentUser != null &&
          (_currentUser!['email'] ?? '').toString().isNotEmpty) {
        payload['email'] = _currentUser!['email'].toString();
      }
      if (!payload.containsKey('is_active')) payload['is_active'] = 1;

      final response = await http.post(
        Uri.parse('https://servekeen.com/api/services_create.php'),
        body: json.encode(payload),
        headers: {'Content-Type': 'application/json'},
      );
      final body = response.body.trim();
      if (body.isEmpty) {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode} (empty response)',
        };
      }
      if (body.startsWith('<')) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        final cleanSnippet = snippet.replaceAll(RegExp(r'<[^>]*>'), '');
        return {'status': 'error', 'message': 'Backend Error: $cleanSnippet'};
      }
      try {
        final decoded = json.decode(body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {'status': 'error', 'message': 'Invalid response'};
      } catch (_) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}. Response: $snippet',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> fetchMyServices() async {
    try {
      final payload = <String, dynamic>{
        'token': _authToken,
        'user_id': _currentUser?['id']?.toString() ?? '',
      };
      final response = await http.post(
        Uri.parse('https://servekeen.com/api/get_my_services.php'),
        body: json.encode(payload),
        headers: {'Content-Type': 'application/json'},
      );
      final body = response.body.trim();
      if (body.isEmpty) {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode} (empty response)',
        };
      }
      if (body.startsWith('<')) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        final cleanSnippet = snippet.replaceAll(RegExp(r'<[^>]*>'), '');
        return {'status': 'error', 'message': 'Backend Error: $cleanSnippet'};
      }
      try {
        final decoded = json.decode(body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {'status': 'error', 'message': 'Invalid response'};
      } catch (_) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}. Response: $snippet',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateService(
    String serviceId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final payload = Map<String, dynamic>.from(updateData);
      payload['token'] = _authToken;
      payload['service_id'] = serviceId;
      if (_currentUser != null &&
          (_currentUser!['id'] ?? '').toString().isNotEmpty) {
        payload['user_id'] = _currentUser!['id'].toString();
      }
      final response = await http.post(
        Uri.parse('https://servekeen.com/api/services_update.php'),
        body: json.encode(payload),
        headers: {'Content-Type': 'application/json'},
      );
      final body = response.body.trim();
      if (body.isEmpty) {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode} (empty response)',
        };
      }
      if (body.startsWith('<')) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        final cleanSnippet = snippet.replaceAll(RegExp(r'<[^>]*>'), '');
        return {'status': 'error', 'message': 'Backend Error: $cleanSnippet'};
      }
      try {
        final decoded = json.decode(body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {'status': 'error', 'message': 'Invalid response'};
      } catch (_) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}. Response: $snippet',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> uploadServiceImages({
    required String serviceId,
    required List<Uint8List> images,
    List<String>? filenames,
  }) async {
    try {
      final uri = Uri.parse(
        'https://servekeen.com/api/services_upload_images.php',
      );
      final req = http.MultipartRequest('POST', uri);
      req.fields['token'] = _authToken ?? '';
      req.fields['user_id'] = _currentUser?['id']?.toString() ?? '';
      req.fields['service_id'] = serviceId;
      for (int i = 0; i < images.length; i++) {
        final name = (filenames != null && i < filenames.length)
            ? filenames[i]
            : 'image_$i.jpg';
        req.files.add(
          http.MultipartFile.fromBytes('images[]', images[i], filename: name),
        );
      }
      final streamed = await req.send();
      final body = (await http.Response.fromStream(streamed)).body.trim();
      if (body.isEmpty) {
        return {
          'status': 'error',
          'message': 'Server error: ${streamed.statusCode} (empty response)',
        };
      }
      if (body.startsWith('<')) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        final cleanSnippet = snippet.replaceAll(RegExp(r'<[^>]*>'), '');
        return {'status': 'error', 'message': 'Backend Error: $cleanSnippet'};
      }
      try {
        final decoded = json.decode(body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {'status': 'error', 'message': 'Invalid response'};
      } catch (_) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        return {
          'status': 'error',
          'message': 'Server error: ${streamed.statusCode}. Response: $snippet',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> signup(Map<String, dynamic> userData) async {
    try {
      _debug('Attempting signup with data: $userData');
      final response = await _postJsonResilient('signup_final.php', userData);

      _debug('Signup response status: ${response.statusCode}');
      _debug('Signup response body: ${response.body}');

      return json.decode(response.body);
    } catch (e) {
      _debug('Signup error: $e');
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> logout() async {
    // Clear local session immediately
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);

    if (_authToken == null) {
      _currentUser = null;
      return {'status': 'success', 'message': 'Logged out locally'};
    }

    final tokenToLogout = _authToken;
    _authToken = null;
    _currentUser = null;

    try {
      final response = await http.delete(
        Uri.parse('https://servekeen.com/api/auth_api_updated.php'),
        body: json.encode({'token': tokenToLogout}),
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> requestOtp({
    required String channel,
    required String phone,
  }) async {
    try {
      if (['sms', 'whatsapp'].contains(channel.toLowerCase()) &&
          _isTestCredential(phone)) {
        return {'status': 'success', 'message': 'otp_sent'};
      }

      final response = await http.post(
        Uri.parse('https://servekeen.com/api/auth_request_otp.php'),
        body: json.encode({'channel': channel, 'phone': phone}),
        headers: {'Content-Type': 'application/json'},
      );
      final body = response.body.trim();
      if (body.isEmpty) {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode} (empty response)',
        };
      }
      if (body.startsWith('<')) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        final cleanSnippet = snippet.replaceAll(RegExp(r'<[^>]*>'), '');
        return {'status': 'error', 'message': 'Backend Error: $cleanSnippet'};
      }
      try {
        final decoded = json.decode(body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {'status': 'error', 'message': 'Invalid response'};
      } catch (_) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}. Response: $snippet',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String channel,
    required String phone,
    required String otp,
  }) async {
    try {
      if (['sms', 'whatsapp'].contains(channel.toLowerCase()) &&
          _isTestCredential(phone) &&
          _isTestCredential(otp)) {
        return await _signInTestUser();
      }

      final response = await http.post(
        Uri.parse('https://servekeen.com/api/auth_verify_otp.php'),
        body: json.encode({'channel': channel, 'phone': phone, 'otp': otp}),
        headers: {'Content-Type': 'application/json'},
      );
      final body = response.body.trim();
      if (body.isEmpty) {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode} (empty response)',
        };
      }
      if (body.startsWith('<')) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        final cleanSnippet = snippet.replaceAll(RegExp(r'<[^>]*>'), '');
        return {'status': 'error', 'message': 'Backend Error: $cleanSnippet'};
      }

      Map<String, dynamic> data;
      try {
        final decoded = json.decode(body);
        data = decoded is Map<String, dynamic>
            ? decoded
            : {'status': 'error', 'message': 'Invalid response'};
      } catch (_) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}. Response: $snippet',
        };
      }
      if (data['status'] == 'success' && data['user'] != null) {
        _authToken = data['token'];
        _currentUser = data['user'];
        if (_sellerOnboarded) {
          _currentUser!['role'] = 'seller';
        }
        final prefs = await SharedPreferences.getInstance();
        if (_authToken != null) {
          await prefs.setString(_tokenKey, _authToken!);
        }
        if (_currentUser != null) {
          await prefs.setString(_userKey, json.encode(_currentUser));
        }
      }
      return data;
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  bool get isSellerOnboarded => _sellerOnboarded;

  Future<void> markSellerOnboarded() async {
    _sellerOnboarded = true;
    if (_currentUser != null) {
      _currentUser!['role'] = 'seller';
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sellerKey, true);
    if (_currentUser != null) {
      await prefs.setString(_userKey, json.encode(_currentUser));
    }
  }

  Future<Map<String, dynamic>> upsertVendor(
    Map<String, dynamic> vendorData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('https://servekeen.com/api/vendor_upsert.php'),
        body: json.encode(vendorData),
        headers: {'Content-Type': 'application/json'},
      );
      final body = response.body.trim();
      if (body.isEmpty) {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode} (empty response)',
        };
      }
      if (body.startsWith('<')) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        final cleanSnippet = snippet.replaceAll(RegExp(r'<[^>]*>'), '');
        return {'status': 'error', 'message': 'Backend Error: $cleanSnippet'};
      }
      final data = json.decode(body);
      return data is Map<String, dynamic>
          ? data
          : {'status': 'error', 'message': 'Invalid response'};
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  // Get current user profile
  Future<Map<String, dynamic>> getCurrentUser() async {
    // Ensure session is loaded
    if (_authToken == null) {
      await loadSession();
      if (_authToken == null) {
        return {'status': 'error', 'message': 'No active session'};
      }
    }

    // Return cached user data immediately if available
    // This avoids calling a potentially non-existent or broken API endpoint
    if (_currentUser != null) {
      return {'status': 'success', 'user': _currentUser};
    }

    // If we have a token but no user data (rare case), we could try to fetch it.
    // But since auth_final.php doesn't support GET, we'll return an error or try to re-login.
    // For now, let's assume if _currentUser is null despite having a token, the session is invalid.
    return {
      'status': 'error',
      'message': 'User data not found. Please log in again.',
    };
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> updateData,
  ) async {
    if (_authToken == null) {
      return {'status': 'error', 'message': 'No active session'};
    }

    try {
      updateData['token'] = _authToken;
      // Pass the email so the backend knows which user to update
      if (_currentUser != null && _currentUser!.containsKey('email')) {
        updateData['email'] = _currentUser!['email'];
      }

      final response = await http.post(
        Uri.parse('https://servekeen.com/api/update_profile.php'),
        body: json.encode(updateData),
        headers: {'Content-Type': 'application/json'},
      );

      final decoded = json.decode(response.body);
      final data = decoded is Map<String, dynamic>
          ? decoded
          : {'status': 'error', 'message': 'Invalid response'};

      if (data['status'] == 'success') {
        final sanitizedUpdate = Map<String, dynamic>.from(updateData);
        sanitizedUpdate.remove('token');

        final base = _currentUser != null
            ? Map<String, dynamic>.from(_currentUser!)
            : <String, dynamic>{};
        final serverUser = data['user'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['user'])
            : <String, dynamic>{};

        _currentUser = <String, dynamic>{
          ...base,
          ...sanitizedUpdate,
          ...serverUser,
        };

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, json.encode(_currentUser));
      }

      return data;
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  // Helper methods
  String? get authToken => _authToken;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Keep existing fetchAppData method unchanged
  Future<Map<String, dynamic>> fetchAppData() async {
    try {
      _debug('Fetching data from: $_baseUrl');
      final response = await http.get(Uri.parse(_baseUrl));
      _debug('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = decoded is Map<String, dynamic>
            ? decoded
            : decoded is Map
            ? decoded.cast<String, dynamic>()
            : <String, dynamic>{};
        _debug('Data received: ${data.keys}');

        // Debug services parsing
        if (data['services'] != null) {
          try {
            _debug('Services found: ${(data['services'] as List).length}');
            // Try to parse first service to catch any errors
            if ((data['services'] as List).isNotEmpty) {
              try {
                final firstServiceRaw = (data['services'] as List)[0];
                final firstService = firstServiceRaw is Map<String, dynamic>
                    ? firstServiceRaw
                    : firstServiceRaw is Map
                    ? firstServiceRaw.cast<String, dynamic>()
                    : null;
                if (firstService != null) {
                  _debug('First service keys: ${firstService.keys}');
                  final testService = Service.fromJson(firstService);
                  _debug(
                    'Successfully parsed first service: ${testService.serviceName}',
                  );
                }
              } catch (e) {
                _debug('Error parsing first service: $e');
                _debug('First service data: ${data['services'][0]}');
                // Continue with other services even if first one fails
              }
            }
          } catch (e) {
            _debug('Error parsing services: $e');
            _debug('First service data: ${data['services'][0]}');
            rethrow;
          }
        }

        return data;
      } else {
        _debug('Server Error: ${response.body}');
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      _debug('Fetch Error: $e');
      throw Exception('Failed to load data: $e');
    }
  }

  Future<List<Service>> fetchServices() async {
    try {
      final data = await fetchAppData();
      if (data['services'] != null) {
        return (data['services'] as List)
            .map((e) => Service.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load services: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchSubcategories(
    String categoryId,
  ) async {
    // Try JSON POST first; if that fails or returns empty, fallback to GET with query params
    try {
      final postResp = await http.post(
        Uri.parse('https://servekeen.com/api/get_subcategories.php'),
        body: json.encode({'category_id': categoryId}),
        headers: {'Content-Type': 'application/json'},
      );
      if (postResp.statusCode == 200 && postResp.body.isNotEmpty) {
        final data = json.decode(postResp.body);
        final list = (data['subcategories'] ?? data['data']) as List?;
        if (data['status'] == 'success' && list != null) {
          return List<Map<String, dynamic>>.from(list);
        }
      }
    } catch (_) {}

    try {
      final getResp = await http.get(
        Uri.parse(
          'https://servekeen.com/api/get_subcategories.php?category_id=$categoryId',
        ),
      );
      if (getResp.statusCode == 200 && getResp.body.isNotEmpty) {
        final data = json.decode(getResp.body);
        final list = (data['subcategories'] ?? data['data']) as List?;
        if (data['status'] == 'success' && list != null) {
          return List<Map<String, dynamic>>.from(list);
        }
      }
    } catch (_) {}

    return [];
  }

  Future<List<Service>> fetchServicesByCategoryId(
    String categoryId, {
    String? subcategoryId,
  }) async {
    // Try JSON POST first; then fallback to GET with query params; support both 'services' and 'data' keys
    try {
      final postResp = await http.post(
        Uri.parse('https://servekeen.com/api/get_services_by_category.php'),
        body: json.encode({
          'category_id': categoryId,
          'subcategory_id': subcategoryId ?? '',
        }),
        headers: {'Content-Type': 'application/json'},
      );
      if (postResp.statusCode == 200 && postResp.body.isNotEmpty) {
        final data = json.decode(postResp.body);
        final list = (data['services'] ?? data['data']) as List?;
        if (data['status'] == 'success' && list != null) {
          return list.map((e) => Service.fromJson(e)).toList();
        }
      }
    } catch (_) {}

    try {
      final uri =
          Uri.parse(
            'https://servekeen.com/api/get_services_by_category.php',
          ).replace(
            queryParameters: {
              'category_id': categoryId,
              if (subcategoryId != null && subcategoryId.isNotEmpty)
                'subcategory_id': subcategoryId,
            },
          );
      final getResp = await http.get(uri);
      if (getResp.statusCode == 200 && getResp.body.isNotEmpty) {
        final data = json.decode(getResp.body);
        final list = (data['services'] ?? data['data']) as List?;
        if (data['status'] == 'success' && list != null) {
          return list.map((e) => Service.fromJson(e)).toList();
        }
      }
    } catch (_) {}

    return [];
  }

  Future<Map<String, dynamic>> fetchServiceRatingSummary(
    String serviceId,
  ) async {
    try {
      final payload = <String, dynamic>{
        if (_authToken != null) 'token': _authToken,
        if (_currentUser?['id'] != null)
          'user_id': _currentUser?['id']?.toString() ?? '',
        'service_id': serviceId,
      };
      final response = await http.post(
        Uri.parse('https://servekeen.com/api/services_get_rating.php'),
        body: json.encode(payload),
        headers: {'Content-Type': 'application/json'},
      );
      final body = response.body.trim();
      if (body.isEmpty) {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode} (empty response)',
        };
      }
      if (body.startsWith('<')) {
        final snippet = body.length > 250
            ? '${body.substring(0, 250)}...'
            : body;
        final cleanSnippet = snippet.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        final lower = cleanSnippet.toLowerCase();
        if (response.statusCode == 404 ||
            lower.contains('not found') ||
            lower.contains('no backend')) {
          return {
            'status': 'error',
            'message':
                'Rating API not found on server. Upload services_get_rating.php to /api/services_get_rating.php (HTTP ${response.statusCode}).',
          };
        }
        return {'status': 'error', 'message': 'Backend Error: $cleanSnippet'};
      }
      try {
        final decoded = json.decode(body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {'status': 'error', 'message': 'Invalid response'};
      } catch (_) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}. Response: $snippet',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> submitServiceRating({
    required String serviceId,
    required int rating,
    String? username,
    String? reviewText,
  }) async {
    if (_currentUser == null) {
      return {
        'status': 'error',
        'message': 'Please login to rate this service.',
      };
    }
    try {
      final usernameTrimmed = (username ?? '').trim();
      final reviewTextTrimmed = (reviewText ?? '').trim();
      final payload = <String, dynamic>{
        if (_authToken != null) 'token': _authToken,
        'user_id': _currentUser?['id']?.toString() ?? '',
        'service_id': serviceId,
        'rating': rating,
        if (usernameTrimmed.isNotEmpty) 'username': usernameTrimmed,
        if (reviewTextTrimmed.isNotEmpty) 'review_text': reviewTextTrimmed,
      };
      final response = await http.post(
        Uri.parse('https://servekeen.com/api/services_rate.php'),
        body: json.encode(payload),
        headers: {'Content-Type': 'application/json'},
      );
      final body = response.body.trim();
      if (body.isEmpty) {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode} (empty response)',
        };
      }
      if (body.startsWith('<')) {
        final snippet = body.length > 250
            ? '${body.substring(0, 250)}...'
            : body;
        final cleanSnippet = snippet.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        final lower = cleanSnippet.toLowerCase();
        if (response.statusCode == 404 ||
            lower.contains('not found') ||
            lower.contains('no backend')) {
          return {
            'status': 'error',
            'message':
                'Rating API not found on server. Upload services_rate.php to /api/services_rate.php (HTTP ${response.statusCode}).',
          };
        }
        return {'status': 'error', 'message': 'Backend Error: $cleanSnippet'};
      }
      try {
        final decoded = json.decode(body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {'status': 'error', 'message': 'Invalid response'};
      } catch (_) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}. Response: $snippet',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<void> trackServiceEvent(String serviceId, String eventType) async {
    try {
      await http.post(
        Uri.parse('https://servekeen.com/api/services_track_event.php'),
        body: json.encode({'service_id': serviceId, 'event_type': eventType}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (_) {}
  }

  Future<Map<String, dynamic>> fetchServiceStats(String serviceId) async {
    try {
      final payload = <String, dynamic>{
        'token': _authToken,
        'user_id': _currentUser?['id']?.toString() ?? '',
        'service_id': serviceId,
      };
      final response = await http.post(
        Uri.parse('https://servekeen.com/api/services_get_stats.php'),
        body: json.encode(payload),
        headers: {'Content-Type': 'application/json'},
      );
      final body = response.body.trim();
      if (body.isEmpty) {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode} (empty response)',
        };
      }
      if (body.startsWith('<')) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        final cleanSnippet = snippet.replaceAll(RegExp(r'<[^>]*>'), '');
        return {'status': 'error', 'message': 'Backend Error: $cleanSnippet'};
      }
      try {
        final decoded = json.decode(body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {'status': 'error', 'message': 'Invalid response'};
      } catch (_) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}. Response: $snippet',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<List<Service>> searchServices(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://servekeen.com/api/search_services.php'),
        body: json.encode({'query': query, 'limit': limit, 'offset': offset}),
        headers: {'Content-Type': 'application/json'},
      );
      final body = response.body.trim();
      if (body.isEmpty) {
        throw Exception(
          'Server error: ${response.statusCode} (empty response)',
        );
      }
      if (body.startsWith('<')) {
        final snippet = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        final cleanSnippet = snippet.replaceAll(RegExp(r'<[^>]*>'), '');
        throw Exception('Backend Error: $cleanSnippet');
      }
      try {
        final decoded = json.decode(body);
        if (decoded is Map<String, dynamic>) {
          if (decoded['status'] == 'success' && decoded['services'] is List) {
            return (decoded['services'] as List)
                .map((e) => Service.fromJson(e))
                .toList();
          }
          if (decoded['status'] == 'error') {
            throw Exception(decoded['message'] ?? 'Search failed');
          }
        }
        throw Exception('Invalid response format');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception(
          'Server error: ${response.statusCode}. Response: ${body.substring(0, 100)}',
        );
      }
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }
}
