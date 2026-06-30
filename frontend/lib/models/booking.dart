import 'user.dart';
import 'court.dart';

class Payment {
  final String id;
  final double amount;
  final String status;
  final String method;
  final String? referenceNumber;

  Payment({
    required this.id,
    required this.amount,
    required this.status,
    required this.method,
    this.referenceNumber,
  });

  bool get isPaid => status == 'PAID';

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? '',
      amount: double.parse((json['amount'] ?? 0.0).toString()),
      status: json['status'] ?? 'PENDING',
      method: json['method'] ?? '',
      referenceNumber: json['reference_number'],
    );
  }
}

class Booking {
  final String id;
  final AppUser? user;
  final String courtId;
  final FutsalCourt? courtDetails;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final String status;
  final double totalPrice;
  final Payment? payment;
  final String createdAt;

  Booking({
    required this.id,
    this.user,
    required this.courtId,
    this.courtDetails,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.totalPrice,
    this.payment,
    required this.createdAt,
  });

  bool get isConfirmed => status == 'CONFIRMED';
  bool get isPending => status == 'PENDING';
  bool get isCancelled => status == 'CANCELLED';

  bool get isPaid => payment?.isPaid ?? false;

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? '',
      user: json['user'] != null ? AppUser.fromJson(json['user']) : null,
      courtId: json['court'] ?? '',
      courtDetails: json['court_details'] != null ? FutsalCourt.fromJson(json['court_details']) : null,
      bookingDate: json['booking_date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      status: json['status'] ?? 'PENDING',
      totalPrice: double.parse((json['total_price'] ?? 0.0).toString()),
      payment: json['payment'] != null ? Payment.fromJson(json['payment']) : null,
      createdAt: json['created_at'] ?? '',
    );
  }
}
