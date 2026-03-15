import 'package:dio/dio.dart';
import '../config/constants.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 300),
    ));
  }

  /// Parse an Excel file via the backend (supports both path and bytes for web)
  Future<Map<String, dynamic>> parseExcelFromBytes(
      List<int> bytes, String fileName) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final response = await _dio.post('/parse', data: formData);
    return Map<String, dynamic>.from(response.data);
  }

  /// Submit optimization with JSON payload (same as web's submitOptimization)
  Future<Map<String, dynamic>> submitOptimization(
      Map<String, dynamic> payload) async {
    final response = await _dio.post('/optimize/json', data: payload);
    return Map<String, dynamic>.from(response.data);
  }

  /// Get job status for polling
  Future<Map<String, dynamic>> getJobStatus(String jobId) async {
    final response = await _dio.get('/optimize/$jobId/status');
    return Map<String, dynamic>.from(response.data);
  }

  /// Get results for a completed job
  Future<Map<String, dynamic>> getResults(String jobId) async {
    final response = await _dio.get('/results/$jobId');
    return Map<String, dynamic>.from(response.data);
  }

  /// Health check
  Future<Map<String, dynamic>> healthCheck() async {
    final response = await _dio.get('/health');
    return Map<String, dynamic>.from(response.data);
  }
}
