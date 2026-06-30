import 'package:dio/dio.dart';
import '../security/secure_storage.dart';

class DioClient {
  late final Dio dio;
  final SecureStorageService _secureStorage = SecureStorageService();

  // Use 10.0.2.2 for Android Emulator, 127.0.0.1 for desktop/simulators
  static const String baseUrl = 'http://192.168.1.64:8000/api/v1';

  DioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Handle token expiry or connection exceptions globally
          String errorMessage = 'Something went wrong';
          if (e.response != null) {
            final data = e.response?.data;
            if (data is Map && data.containsKey('detail')) {
              errorMessage = data['detail'];
            } else if (data is Map && data.containsKey('non_field_errors')) {
              errorMessage = (data['non_field_errors'] as List).join(', ');
            } else {
              errorMessage = data.toString();
            }
          } else {
            errorMessage = 'Network connection failed. Verify server is running.';
          }
          // Wrap error message into custom Exception
          return handler.next(e.copyWith(message: errorMessage));
        },
      ),
    );
  }
}
