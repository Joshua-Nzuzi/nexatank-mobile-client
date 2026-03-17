import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';
import 'dart:async';

class ApiService {
  final StorageService _storageService = StorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getAuthToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final responseBody = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        return {'success': false, 'message': responseBody['message'] ?? 'Erreur inconnue'};
      }
    } catch (_) {
      return {'success': false, 'message': 'Erreur serveur inattendue'};
    }
  }

  Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}$endpoint'), headers: headers).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(Uri.parse('${ApiConfig.baseUrl}$endpoint'), headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<Map<String, dynamic>> _patch(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(Uri.parse('${ApiConfig.baseUrl}$endpoint'), headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // ----------------- ENDPOINTS -----------------

  Future<Map<String, dynamic>> register(String name, String role, String phone) async {
    return _post('/api/auth/users', {'name': name, 'role': role, 'phone': phone});
  }

  // MODIFIÉ : LOGIN AVEC CODE UNIQUEMENT
  Future<Map<String, dynamic>> loginWithCode(int code) async {
    return _post('/api/auth/login', {'code': code.toString()});
  }

  Future<Map<String, dynamic>> getTanks() async {
    return _get('/api/tanks');
  }

  Future<Map<String, dynamic>> calculateVolume(dynamic tankId, double depthCm) async {
    return _post('/api/tanks/volume', {'tank_id': tankId, 'depth_cm': depthCm});
  }

  Future<Map<String, dynamic>> regenerateCode(String phone) async {
    return _patch('/api/auth/users', {'phone': phone});
  }
}
