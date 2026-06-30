import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking.dart';
import '../../models/futsal.dart';
import '../../models/court.dart';

class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).fetchBookings();
      ref.read(bookingProvider.notifier).fetchFutsals();
      ref.read(bookingProvider.notifier).fetchCourts();
    });
  }

  void _handleConfirm(Booking booking) async {
    try {
      await ref.read(bookingProvider.notifier).confirmBooking(
            bookingId: booking.id,
            paymentMethod: 'CASH',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking confirmed! Payment set to Cash (Pending).'), backgroundColor: Color(0xFF39FF14)),
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

  void _handleCancel(Booking booking) async {
    try {
      await ref.read(bookingProvider.notifier).cancelBooking(booking.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully.'), backgroundColor: Colors.redAccent),
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
    final authState = ref.watch(authProvider);
    final state = ref.watch(bookingProvider);
    const themeColor = Color(0xFF39FF14);

    final pendingBookings = state.bookings.where((b) => b.isPending).toList();
    final confirmedBookings = state.bookings.where((b) => b.isConfirmed).toList();
    final cancelledBookings = state.bookings.where((b) => b.isCancelled).toList();

    double revenue = confirmedBookings.fold(0.0, (sum, b) => sum + b.totalPrice);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          title: Text(
            authState.user?.ownerProfile?.companyName ?? 'Owner Portal',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: themeColor,
            labelColor: themeColor,
            unselectedLabelColor: Colors.grey[500],
            tabs: [
              Tab(text: 'Pending (${pendingBookings.length})'),
              Tab(text: 'Confirmed (${confirmedBookings.length})'),
              Tab(text: 'Cancelled (${cancelledBookings.length})'),
              const Tab(text: 'My Business'),
            ],
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stats Section
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF161616),
              child: Row(
                children: [
                  _buildStatCard('Revenue Generated', 'Rs. ${revenue.toStringAsFixed(0)}', themeColor),
                  const SizedBox(width: 12),
                  _buildStatCard('Total Bookings', '${state.bookings.length}', Colors.lightBlueAccent),
                ],
              ),
            ),

            // Tab contents
            Expanded(
              child: state.isLoading
                  ? const Center(child: SpinKitFadingCircle(color: themeColor, size: 50))
                  : TabBarView(
                      children: [
                        _buildBookingsList(pendingBookings, isPendingTab: true),
                        _buildBookingsList(confirmedBookings),
                        _buildBookingsList(cancelledBookings),
                        _buildBusinessTab(state, themeColor),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(color: color, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList(List<Booking> list, {bool isPendingTab = false}) {
    final themeColor = const Color(0xFF39FF14);
    if (list.isEmpty) {
      return Center(
        child: Text(
          'No bookings found.',
          style: GoogleFonts.inter(color: Colors.grey[500]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final booking = list[index];

        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.courtDetails?.name ?? 'Standard Court',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            'User: ${booking.user?.username ?? "Customer"} (${booking.user?.phone ?? "No phone"})',
                            style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rs. ${booking.totalPrice.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(color: themeColor, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const Divider(color: Colors.grey, height: 20),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(booking.bookingDate, style: GoogleFonts.inter(color: Colors.grey[300], fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('${booking.startTime.substring(0, 5)} - ${booking.endTime.substring(0, 5)}',
                        style: GoogleFonts.inter(color: Colors.grey[300], fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('Payment: ', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
                        Text(
                          booking.isPaid ? 'PAID' : 'UNPAID',
                          style: GoogleFonts.inter(
                            color: booking.isPaid ? themeColor : Colors.orangeAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (isPendingTab)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.redAccent),
                            onPressed: () => _handleCancel(booking),
                            tooltip: 'Cancel booking',
                          ),
                          IconButton(
                            icon: Icon(Icons.check_circle, color: themeColor),
                            onPressed: () => _handleConfirm(booking),
                            tooltip: 'Confirm Booking',
                          ),
                        ],
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

  Widget _buildBusinessTab(BookingState state, Color themeColor) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Action Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/owner/register-futsal'),
                icon: const Icon(Icons.add_business, size: 18),
                label: const Text('Add Futsal'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: themeColor,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/owner/add-court'),
                icon: const Icon(Icons.add_box_outlined, size: 18),
                label: const Text('Add Court'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.grey[850],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Text(
          'My Registered Futsal Arenas',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),

        state.futsals.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      Icon(Icons.storefront, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      Text('No futsal arenas registered yet.', style: GoogleFonts.inter(color: Colors.grey[500])),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.futsals.length,
                itemBuilder: (context, index) {
                  final futsal = state.futsals[index];
                  final futsalCourts = state.courts.where((court) => court.futsalId == futsal.id).toList();

                  return Card(
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.only(bottom: 20),
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
                                  futsal.name,
                                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: futsal.isApproved ? themeColor.withOpacity(0.1) : Colors.orangeAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: futsal.isApproved ? themeColor.withOpacity(0.4) : Colors.orangeAccent.withOpacity(0.4)),
                                ),
                                child: Text(
                                  futsal.isApproved ? 'Approved' : 'Pending Verification',
                                  style: GoogleFonts.inter(
                                    color: futsal.isApproved ? themeColor : Colors.orangeAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(futsal.address, style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Closed Today:',
                                    style: GoogleFonts.inter(
                                      color: futsal.isClosedToday ? Colors.redAccent : Colors.grey[400],
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    height: 24,
                                    child: Transform.scale(
                                      scale: 0.8,
                                      child: Switch(
                                        value: futsal.isClosedToday,
                                        activeColor: Colors.redAccent,
                                        activeTrackColor: Colors.redAccent.withOpacity(0.3),
                                        inactiveThumbColor: Colors.grey,
                                        inactiveTrackColor: Colors.grey[800],
                                        onChanged: (value) async {
                                          try {
                                            await ref.read(bookingProvider.notifier).toggleFutsalClosure(futsal.id, value);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(value ? 'Futsal closed for today!' : 'Futsal is now open!'),
                                                  backgroundColor: value ? Colors.redAccent : const Color(0xFF39FF14),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error updating status: $e'),
                                                  backgroundColor: Colors.redAccent,
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(color: Colors.grey, height: 24),
                          
                          // Courts List
                          Text('Courts List (${futsalCourts.length})', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 8),

                          futsalCourts.isEmpty
                              ? Text('No courts registered on this arena. Click Add Court above.', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12))
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: futsalCourts.length,
                                  itemBuilder: (context, cIndex) {
                                    final court = futsalCourts[cIndex];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(court.name, style: GoogleFonts.inter(color: Colors.grey[300])),
                                          Text('Rs. ${court.pricePerHour.toStringAsFixed(0)} / hr', style: GoogleFonts.inter(color: themeColor, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}
