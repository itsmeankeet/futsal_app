import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../models/booking.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        Provider.of<BookingProvider>(context, listen: false).fetchBookings(token);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleApprove(Booking booking) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

    try {
      await bookingProvider.approve(token, booking.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking #${booking.id} approved! Overlapping bookings were automatically rejected.'),
            backgroundColor: const Color(0xFF39FF14),
            behavior: SnackBarBehavior.floating,
          ),
        );
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

  void _handleReject(Booking booking) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

    try {
      await bookingProvider.reject(token, booking.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking #${booking.id} rejected.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bookingProvider = Provider.of<BookingProvider>(context);
    final themeColor = const Color(0xFF39FF14);

    final allBookings = bookingProvider.bookings;
    final pendingBookings = allBookings.where((b) => b.isPending).toList();
    final approvedBookings = allBookings.where((b) => b.isApproved).toList();
    final rejectedBookings = allBookings.where((b) => b.isRejected).toList();

    // Stats calculations
    double totalRevenue = approvedBookings.fold(0.0, (sum, item) => sum + item.totalPrice);
    int totalCount = allBookings.length;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Portal',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
            ),
            Text(
              authProvider.user?.username ?? 'Admin',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: themeColor,
          labelColor: themeColor,
          unselectedLabelColor: Colors.grey[500],
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'Pending (${pendingBookings.length})'),
            Tab(text: 'Approved (${approvedBookings.length})'),
            Tab(text: 'Rejected (${rejectedBookings.length})'),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stat Bar Cards
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF161616),
            child: Row(
              children: [
                _buildStatCard('Revenue', 'Rs. ${totalRevenue.toStringAsFixed(0)}', themeColor),
                const SizedBox(width: 12),
                _buildStatCard('Pending', '${pendingBookings.length}', Colors.orangeAccent),
                const SizedBox(width: 12),
                _buildStatCard('Total Bookings', '$totalCount', Colors.lightBlueAccent),
              ],
            ),
          ),

          // Main list showing tabs
          Expanded(
            child: bookingProvider.isLoading
                ? Center(child: SpinKitFadingCircle(color: themeColor, size: 50))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBookingsList(pendingBookings, isPendingTab: true),
                      _buildBookingsList(approvedBookings),
                      _buildBookingsList(rejectedBookings),
                    ],
                  ),
          ),
        ],
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
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
          'No bookings in this category.',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.courtName,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'User: ${booking.user?.username ?? "Unknown"} (${booking.user?.phone ?? "No phone"})',
                            style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rs. ${booking.totalPrice.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.grey, height: 20),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      booking.bookingDate,
                      style: GoogleFonts.inter(color: Colors.grey[300], fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '${booking.startTime.substring(0, 5)} - ${booking.endTime.substring(0, 5)}',
                      style: GoogleFonts.inter(color: Colors.grey[300], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Payment: ',
                          style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12),
                        ),
                        Text(
                          booking.isPaid ? 'PAID' : 'UNPAID',
                          style: GoogleFonts.inter(
                            color: booking.isPaid ? themeColor : Colors.orangeAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (booking.isPaid && booking.paymentReference != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '(${booking.paymentReference})',
                            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 10),
                          ),
                        ]
                      ],
                    ),

                    // Approve/Reject Buttons (Only for Pending tab)
                    if (isPendingTab)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.redAccent),
                            onPressed: () => _handleReject(booking),
                            tooltip: 'Reject Booking',
                          ),
                          IconButton(
                            icon: Icon(Icons.check_circle, color: themeColor),
                            onPressed: () => _handleApprove(booking),
                            tooltip: 'Approve Booking',
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
}
