import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../providers/booking_provider.dart';
import '../models/booking.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).fetchBookings();
    });
  }

  void _showPaymentModal(Booking booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Settle Payment', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Settle Rs. ${booking.totalPrice.toStringAsFixed(2)} balance immediately.', style: GoogleFonts.inter(color: Colors.grey[400])),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _pay(booking, 'ESEWA'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF60BB46)),
                        child: const Text('eSewa'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _pay(booking, 'KHALTI'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C2D91)),
                        child: const Text('Khalti'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pay(Booking booking, String method) async {
    Navigator.of(context).pop();
    final refNum = 'MOCK-${method.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}';

    try {
      await ref.read(bookingProvider.notifier).confirmBooking(
            bookingId: booking.id,
            paymentMethod: method,
            referenceNumber: refNum,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment registered! Reference: $refNum'), backgroundColor: const Color(0xFF39FF14)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _cancel(Booking booking) async {
    try {
      await ref.read(bookingProvider.notifier).cancelBooking(booking.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking request cancelled.'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingProvider);
    const themeColor = Color(0xFF39FF14);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('My Reservations', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: state.isLoading
          ? const Center(child: SpinKitFadingCircle(color: themeColor, size: 50))
          : state.bookings.isEmpty
              ? Center(child: Text('No reservations found.', style: GoogleFonts.inter(color: Colors.grey[500])))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.bookings.length,
                  itemBuilder: (context, index) {
                    final booking = state.bookings[index];
                    Color statusColor = Colors.orangeAccent;
                    if (booking.isConfirmed) statusColor = themeColor;
                    if (booking.isCancelled) statusColor = Colors.redAccent;

                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    booking.courtDetails?.name ?? 'Court Pitch',
                                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: statusColor.withOpacity(0.4)),
                                  ),
                                  child: Text(
                                    booking.status,
                                    style: GoogleFonts.inter(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.grey, height: 24),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(booking.bookingDate, style: GoogleFonts.inter(color: Colors.grey[300], fontSize: 13)),
                                const SizedBox(width: 16),
                                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text('${booking.startTime.substring(0, 5)} - ${booking.endTime.substring(0, 5)}',
                                    style: GoogleFonts.inter(color: Colors.grey[300], fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Total price', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11)),
                                    Text('Rs. ${booking.totalPrice.toStringAsFixed(0)}',
                                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: booking.isPaid ? themeColor.withOpacity(0.1) : Colors.orangeAccent.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        booking.isPaid ? 'PAID' : 'UNPAID',
                                        style: GoogleFonts.inter(color: booking.isPaid ? themeColor : Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (!booking.isPaid && !booking.isCancelled)
                                      ElevatedButton(
                                        onPressed: () => _showPaymentModal(booking),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: const Text('Pay Now', style: TextStyle(fontSize: 12)),
                                      ),
                                    if (booking.isPending) ...[
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () => _cancel(booking),
                                        style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                                        child: const Text('Cancel'),
                                      )
                                    ]
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
