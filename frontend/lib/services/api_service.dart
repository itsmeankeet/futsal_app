import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';

final dioClientProvider = Provider((ref) => DioClient());

final apiServiceProvider = Provider((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiService(dioClient.dio);
});

class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  // Register
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? companyName,
    String? panNumber,
    String? businessAddress,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'username': username,
        'email': email,
        'password': password,
        'role': role,
      };
      if (phone != null) requestData['phone'] = phone;
      if (companyName != null) requestData['company_name'] = companyName;
      if (panNumber != null) requestData['pan_number'] = panNumber;
      if (businessAddress != null) requestData['business_address'] = businessAddress;

      final response = await _dio.post('/auth/register/', data: requestData);
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  // Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post('/auth/login/', data: {
        'username': username,
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  // Profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('/auth/profile/');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  // Futsals List
  Future<List<dynamic>> getFutsals({bool? isApproved}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (isApproved != null) {
        queryParams['is_approved'] = isApproved;
      }
      final response = await _dio.get('/futsals/', queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  // Approve Futsal (Admin only)
  Future<void> approveFutsal(String id) async {
    try {
      await _dio.post('/futsals/$id/approve/');
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  // Reject Futsal (Admin only)
  Future<void> rejectFutsal(String id) async {
    try {
      await _dio.post('/futsals/$id/reject/');
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  // Owners List (Admin only)
  Future<List<dynamic>> getOwners({bool? isVerified}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (isVerified != null) {
        queryParams['is_verified'] = isVerified;
      }
      final response = await _dio.get('/owners/', queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  // Approve Owner (Admin only)
  Future<void> approveOwner(String id) async {
    try {
      await _dio.post('/owners/$id/approve/');
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  // Reject Owner (Admin only)
  Future<void> rejectOwner(String id) async {
    try {
      await _dio.post('/owners/$id/reject/');
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  // Courts List
  Future<List<dynamic>> getCourts({String? futsalId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (futsalId != null) {
        queryParams['futsal'] = futsalId;
      }
      final response = await _dio.get('/courts/', queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  // Bookings List
  Future<List<dynamic>> getBookings() async {
    try {
      final response = await _dio.get('/bookings/');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  // Create Booking
  Future<Map<String, dynamic>> createBooking({
    required String courtId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final response = await _dio.post('/bookings/', data: {
        'court': courtId,
        'booking_date': date,
        'start_time': startTime,
        'end_time': endTime,
      });
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  // Confirm/Pay Booking
  Future<Map<String, dynamic>> confirmBooking({
    required String bookingId,
    required String paymentMethod,
    String? referenceNumber,
  }) async {
    try {
      final response = await _dio.post('/bookings/$bookingId/confirm/', data: {
        'payment_method': paymentMethod,
        'reference_number': referenceNumber,
      });
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  // Cancel Booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _dio.post('/bookings/$bookingId/cancel/');
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  // Create Futsal (Owner only)
  Future<Map<String, dynamic>> createFutsal({
    required String name,
    required String address,
    required String contactPhone,
    required String openingHours,
    required String closingHours,
    required String description,
    required double latitude,
    required double longitude,
    required List<int>? logoBytes,
    required String? logoName,
    required List<int>? coverImageBytes,
    required String? coverImageName,
    List<String>? facilityIds,
  }) async {
    try {
      final formData = FormData.fromMap({
        'name': name,
        'address': address,
        'contact_phone': contactPhone,
        'opening_hours': openingHours,
        'closing_hours': closingHours,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
      });

      if (facilityIds != null) {
        for (var id in facilityIds) {
          formData.fields.add(MapEntry('facility_ids', id));
        }
      }

      if (logoBytes != null && logoName != null) {
        formData.files.add(MapEntry(
          'logo',
          MultipartFile.fromBytes(logoBytes, filename: logoName),
        ));
      }

      if (coverImageBytes != null && coverImageName != null) {
        formData.files.add(MapEntry(
          'cover_image',
          MultipartFile.fromBytes(coverImageBytes, filename: coverImageName),
        ));
      }

      final response = await _dio.post('/futsals/', data: formData);
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  // Create Court (Owner only)
  Future<Map<String, dynamic>> createCourt({
    required String futsalId,
    required String name,
    required bool isIndoor,
    required double pricePerHour,
    required String description,
    List<Map<String, dynamic>>? imageFiles,
  }) async {
    try {
      final formData = FormData.fromMap({
        'futsal': futsalId,
        'name': name,
        'is_indoor': isIndoor,
        'price_per_hour': pricePerHour,
        'description': description,
        'status': 'ACTIVE',
      });

      if (imageFiles != null) {
        for (var fileData in imageFiles) {
          final bytes = fileData['bytes'] as List<int>;
          final filename = fileData['name'] as String;
          formData.files.add(MapEntry(
            'images',
            MultipartFile.fromBytes(bytes, filename: filename),
          ));
        }
      }

      final response = await _dio.post('/courts/', data: formData);
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  // Toggle Futsal Closure (Owner only)
  Future<Map<String, dynamic>> updateFutsalClosure(String futsalId, bool isClosedToday) async {
    try {
      final response = await _dio.patch('/futsals/$futsalId/', data: {
        'is_closed_today': isClosedToday,
      });
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  // Facilities List
  Future<List<dynamic>> getFacilities() async {
    try {
      final response = await _dio.get('/facilities/');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }
}
