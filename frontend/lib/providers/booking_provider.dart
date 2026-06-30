import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/futsal.dart';
import '../models/court.dart';
import '../models/booking.dart';
import '../models/facility.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class BookingState {
  final List<Futsal> futsals;
  final List<FutsalCourt> courts;
  final List<Booking> bookings;
  final List<Facility> facilities;
  final List<OwnerProfile> owners;
  final bool isLoading;
  final String? error;

  BookingState({
    this.futsals = const [],
    this.courts = const [],
    this.bookings = const [],
    this.facilities = const [],
    this.owners = const [],
    this.isLoading = false,
    this.error,
  });

  BookingState copyWith({
    List<Futsal>? futsals,
    List<FutsalCourt>? courts,
    List<Booking>? bookings,
    List<Facility>? facilities,
    List<OwnerProfile>? owners,
    bool? isLoading,
    String? error,
  }) {
    return BookingState(
      futsals: futsals ?? this.futsals,
      courts: courts ?? this.courts,
      bookings: bookings ?? this.bookings,
      facilities: facilities ?? this.facilities,
      owners: owners ?? this.owners,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BookingNotifier extends StateNotifier<BookingState> {
  final ApiService _apiService;

  BookingNotifier(this._apiService) : super(BookingState());

  // Fetch Futsals
  Future<void> fetchFutsals({bool? isApproved}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiService.getFutsals(isApproved: isApproved);
      final futsalsList = res.map((item) => Futsal.fromJson(item)).toList();
      state = state.copyWith(futsals: futsalsList, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Fetch Courts
  Future<void> fetchCourts({String? futsalId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiService.getCourts(futsalId: futsalId);
      final courtsList = res.map((item) => FutsalCourt.fromJson(item)).toList();
      state = state.copyWith(courts: courtsList, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Fetch Bookings (Filters automatically based on Auth role on backend)
  Future<void> fetchBookings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiService.getBookings();
      final bookingsList = res.map((item) => Booking.fromJson(item)).toList();
      state = state.copyWith(bookings: bookingsList, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Create Booking
  Future<Booking> createBooking({
    required String courtId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiService.createBooking(
        courtId: courtId,
        date: date,
        startTime: startTime,
        endTime: endTime,
      );
      final newBooking = Booking.fromJson(res);
      state = state.copyWith(
        bookings: [newBooking, ...state.bookings],
        isLoading: false,
      );
      return newBooking;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Confirm/Pay Booking
  Future<void> confirmBooking({
    required String bookingId,
    required String paymentMethod,
    String? referenceNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.confirmBooking(
        bookingId: bookingId,
        paymentMethod: paymentMethod,
        referenceNumber: referenceNumber,
      );
      await fetchBookings(); // refresh list to update stats and auto-cancelled slots
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Cancel Booking
  Future<void> cancelBooking(String bookingId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.cancelBooking(bookingId);
      await fetchBookings();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Approve Futsal (Admin only)
  Future<void> approveFutsal(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.approveFutsal(id);
      await fetchFutsals(); // refresh list
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Reject Futsal (Admin only)
  Future<void> rejectFutsal(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.rejectFutsal(id);
      await fetchFutsals(); // refresh list
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Fetch Owners (Admin only)
  Future<void> fetchOwners({bool? isVerified}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiService.getOwners(isVerified: isVerified);
      final ownersList = res.map((item) => OwnerProfile.fromJson(item)).toList();
      state = state.copyWith(owners: ownersList, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Approve Owner (Admin only)
  Future<void> approveOwner(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.approveOwner(id);
      await fetchOwners(); // refresh list
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Reject Owner (Admin only)
  Future<void> rejectOwner(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.rejectOwner(id);
      await fetchOwners(); // refresh list
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Fetch Facilities Options
  Future<void> fetchFacilities() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiService.getFacilities();
      final facList = res.map((item) => Facility.fromJson(item)).toList();
      state = state.copyWith(facilities: facList, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Create Futsal (Owner only)
  Future<void> createFutsal({
    required String name,
    required String address,
    required String contactPhone,
    required String openingHours,
    required String closingHours,
    String? logo,
    String? coverImage,
    List<String>? facilityIds,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiService.createFutsal(
        name: name,
        address: address,
        contactPhone: contactPhone,
        openingHours: openingHours,
        closingHours: closingHours,
        logo: logo,
        coverImage: coverImage,
        facilityIds: facilityIds,
      );
      final newFutsal = Futsal.fromJson(res);
      state = state.copyWith(
        futsals: [newFutsal, ...state.futsals],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Create Court (Owner only)
  Future<void> createCourt({
    required String futsalId,
    required String name,
    required bool isIndoor,
    required double pricePerHour,
    required String description,
    List<String>? imageUrls,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiService.createCourt(
        futsalId: futsalId,
        name: name,
        isIndoor: isIndoor,
        pricePerHour: pricePerHour,
        description: description,
        imageUrls: imageUrls,
      );
      final newCourt = FutsalCourt.fromJson(res);
      state = state.copyWith(
        courts: [newCourt, ...state.courts],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Toggle Futsal Closure (Owner only)
  Future<void> toggleFutsalClosure(String futsalId, bool isClosedToday) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.updateFutsalClosure(futsalId, isClosedToday);
      await fetchFutsals(); // refresh list to get updated status
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return BookingNotifier(apiService);
});
