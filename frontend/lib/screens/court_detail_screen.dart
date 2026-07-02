import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import '../models/court.dart';
import '../models/futsal.dart';
import '../models/booking.dart';
import '../providers/booking_provider.dart';
import '../core/utils/image_helper.dart';

class CourtDetailScreen extends ConsumerStatefulWidget {
  final FutsalCourt court;
  const CourtDetailScreen({super.key, required this.court});

  @override
  ConsumerState<CourtDetailScreen> createState() => _CourtDetailScreenState();
}

class _CourtDetailScreenState extends ConsumerState<CourtDetailScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;

  final List<String> _timeSlots = [
    "06:00 - 07:00",
    "07:00 - 08:00",
    "08:00 - 09:00",
    "09:00 - 10:00",
    "10:00 - 11:00",
    "11:00 - 12:00",
    "12:00 - 13:00",
    "13:00 - 14:00",
    "14:00 - 15:00",
    "15:00 - 16:00",
    "16:00 - 17:00",
    "17:00 - 18:00",
    "18:00 - 19:00",
    "19:00 - 20:00",
    "20:00 - 21:00",
    "21:00 - 22:00",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).fetchBookings();
      ref.read(bookingProvider.notifier).fetchFutsals();
    });
  }

  bool get _isClosedAndToday {
    final bookingState = ref.read(bookingProvider);
    final futsal = bookingState.futsals.firstWhere(
      (f) => f.id == widget.court.futsalId,
      orElse: () => Futsal(
        id: '', owner: '', ownerCompany: '', name: '', address: '', contactPhone: '',
        latitude: 0, longitude: 0, openingHours: '', closingHours: '',
        isApproved: false, isClosedToday: false, logo: '', coverImage: '',
        facilities: [], averageRating: 0, description: ''
      ),
    );
    final isSelectedDateToday = DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now());
    return futsal.isClosedToday && isSelectedDateToday;
  }

  void _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF39FF14),
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
      });
    }
  }

  void _bookSlot() async {
    if (_selectedSlot == null || _isClosedAndToday) return;

    final parts = _selectedSlot!.split(' - ');
    final startTime = '${parts[0]}:00';
    final endTime = '${parts[1]}:00';
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    try {
      final booking = await ref.read(bookingProvider.notifier).createBooking(
            courtId: widget.court.id,
            date: dateStr,
            startTime: startTime,
            endTime: endTime,
          );
      if (mounted) {
        _showPaymentBottomSheet(booking);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showPaymentBottomSheet(Booking booking) {
    const themeColor = Color(0xFF39FF14);
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Confirm Booking & Pay',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your booking is pending payment. Select a payment method below.',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
                ),
                const Divider(color: Colors.grey, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Amount:', style: GoogleFonts.inter(color: Colors.white, fontSize: 16)),
                    Text(
                      'Rs. ${booking.totalPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(color: themeColor, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _processPayment(booking, 'ESEWA'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF60BB46),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('eSewa'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _processPayment(booking, 'KHALTI'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C2D91),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Khalti'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _processPayment(booking, 'CASH'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cash (Counter)'),
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

  void _processPayment(Booking booking, String method) async {
    Navigator.of(context).pop(); // dismiss sheet
    try {
      await ref.read(bookingProvider.notifier).confirmBooking(
            bookingId: booking.id,
            paymentMethod: method,
            referenceNumber: 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          );
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: Text('Booking Confirmed!', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Text(
              method == 'CASH'
                  ? 'Your slot is reserved! Please pay Rs. ${booking.totalPrice.toStringAsFixed(0)} at the counter.'
                  : 'Payment processed successfully! Your booking is fully confirmed.',
              style: GoogleFonts.inter(color: Colors.grey[300]),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // dismiss dialog
                  context.go('/customer/bookings'); // go to bookings tab
                },
                child: const Text('View Bookings', style: TextStyle(color: Color(0xFF39FF14))),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment verification failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingProvider);
    const themeColor = Color(0xFF39FF14);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final bookingState = ref.watch(bookingProvider);
    final futsal = bookingState.futsals.firstWhere(
      (f) => f.id == widget.court.futsalId,
      orElse: () => Futsal(
        id: '', owner: '', ownerCompany: '', name: '', address: '', contactPhone: '',
        latitude: 0, longitude: 0, openingHours: '', closingHours: '',
        isApproved: false, isClosedToday: false, logo: '', coverImage: '',
        facilities: [], averageRating: 0, description: ''
      ),
    );

    final isClosedAndToday = _isClosedAndToday;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(widget.court.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Court Image Gallery / Carousel
                  widget.court.images.isEmpty
                      ? Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(16),
                            image: const DecorationImage(
                              image: NetworkImage('https://images.unsplash.com/photo-1579952363873-27f3bade9f55?q=80&w=600&auto=format&fit=crop'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : Container(
                          height: 200,
                          width: double.infinity,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                PageView.builder(
                                  itemCount: widget.court.images.length,
                                  itemBuilder: (context, index) {
                                    return Image.network(
                                      getImageUrl(widget.court.images[index]),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey[900],
                                        child: const Icon(Icons.broken_image, color: Colors.grey),
                                      ),
                                    );
                                  },
                                ),
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Gallery (${widget.court.images.length})',
                                      style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.court.futsalName, style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[400], fontWeight: FontWeight.bold)),
                          Text(
                            widget.court.isIndoor ? 'Indoor Pitch' : 'Outdoor Turf',
                            style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13),
                          ),
                        ],
                      ),
                      Text('Rs. ${widget.court.pricePerHour.toStringAsFixed(0)} / hr',
                          style: GoogleFonts.outfit(color: themeColor, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(widget.court.description, style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
                  const SizedBox(height: 24),

                  // Futsal Closed Warning Banner
                  if (isClosedAndToday) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This futsal arena is closed today. You cannot book any slots for today.',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Schedule Slots', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: _showDatePicker,
                        icon: const Icon(Icons.calendar_month, color: themeColor),
                        label: Text(DateFormat('MMM dd, yyyy').format(_selectedDate),
                            style: GoogleFonts.inter(color: themeColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: _timeSlots.length,
                    itemBuilder: (context, index) {
                      final slot = _timeSlots[index];
                      final startFormatted = '${slot.split(' - ')[0]}:00';

                      final matchingBookings = state.bookings.where((b) =>
                          b.courtId == widget.court.id &&
                          b.bookingDate == dateStr &&
                          b.startTime == startFormatted).toList();

                      bool isConfirmed = matchingBookings.any((b) => b.isConfirmed);
                      bool isPending = matchingBookings.any((b) => b.isPending);

                      bool isSelected = _selectedSlot == slot;
                      Color cardBg = const Color(0xFF1E1E1E);
                      Color textColor = Colors.white;
                      Border? border;

                      if (isConfirmed) {
                        cardBg = Colors.redAccent.withOpacity(0.1);
                        textColor = Colors.redAccent;
                        border = Border.all(color: Colors.redAccent.withOpacity(0.4));
                      } else if (isPending) {
                        cardBg = Colors.orangeAccent.withOpacity(0.1);
                        textColor = Colors.orangeAccent;
                        border = Border.all(color: Colors.orangeAccent.withOpacity(0.4));
                      } else if (isClosedAndToday) {
                        cardBg = Colors.grey[900]!;
                        textColor = Colors.grey[600]!;
                        border = Border.all(color: Colors.grey[850]!);
                      } else if (isSelected) {
                        cardBg = themeColor.withOpacity(0.2);
                        textColor = themeColor;
                        border = Border.all(color: themeColor, width: 1.5);
                      }

                      return InkWell(
                        onTap: isConfirmed || isClosedAndToday
                            ? null
                            : () => setState(() => _selectedSlot = slot),
                        child: Container(
                          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: border),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  slot,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isConfirmed
                                      ? 'Booked'
                                      : isPending
                                          ? 'Pending'
                                          : isClosedAndToday
                                              ? 'Closed'
                                              : 'Available',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color: isConfirmed
                                        ? Colors.redAccent
                                        : isPending
                                            ? Colors.orangeAccent
                                            : isClosedAndToday
                                                ? Colors.grey[600]
                                                : themeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Book Now bottom button bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedSlot == null || isClosedAndToday ? null : _bookSlot,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      isClosedAndToday
                          ? 'Futsal Closed'
                          : _selectedSlot == null
                              ? 'Select a Time Slot'
                              : 'Book Selected Slot',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
