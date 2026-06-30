import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/user.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).fetchFutsals(); // load all futsals
      ref.read(bookingProvider.notifier).fetchBookings(); // load all bookings
      ref.read(bookingProvider.notifier).fetchOwners(isVerified: false); // load all unverified owners
    });
  }

  void _approveFutsal(String id) async {
    try {
      await ref.read(bookingProvider.notifier).approveFutsal(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Futsal listing approved successfully!'), backgroundColor: Color(0xFF39FF14)),
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

  void _rejectFutsal(String id) async {
    try {
      await ref.read(bookingProvider.notifier).rejectFutsal(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Futsal listing rejected.'), backgroundColor: Colors.redAccent),
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

  void _approveOwner(String id) async {
    try {
      await ref.read(bookingProvider.notifier).approveOwner(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Owner account approved successfully!'), backgroundColor: Color(0xFF39FF14)),
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

  void _rejectOwner(String id) async {
    try {
      await ref.read(bookingProvider.notifier).rejectOwner(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Owner account rejected and deleted.'), backgroundColor: Colors.redAccent),
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

    final unapprovedFutsals = state.futsals.where((f) => !f.isApproved).toList();
    final pendingOwners = state.owners.where((o) => !o.isVerified).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          title: Text('Admin Control Panel', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
              Tab(text: 'Pending Owners (${pendingOwners.length})'),
              Tab(text: 'Pending Futsals (${unapprovedFutsals.length})'),
            ],
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Admin Stats Row
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF161616),
              child: Row(
                children: [
                  _buildStatCard('Pending Owners', '${pendingOwners.length}', Colors.orangeAccent),
                  const SizedBox(width: 12),
                  _buildStatCard('Pending Futsals', '${unapprovedFutsals.length}', themeColor),
                  const SizedBox(width: 12),
                  _buildStatCard('Total Bookings', '${state.bookings.length}', Colors.lightBlueAccent),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Pending Owners
                  state.isLoading
                      ? const Center(child: SpinKitFadingCircle(color: themeColor, size: 50))
                      : pendingOwners.isEmpty
                          ? Center(
                              child: Text(
                                'No pending owners.',
                                style: GoogleFonts.inter(color: Colors.grey[500]),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              itemCount: pendingOwners.length,
                              itemBuilder: (context, index) {
                                final owner = pendingOwners[index];
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
                                            Text(
                                              owner.companyName,
                                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                            if (owner.panNumber.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[800],
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'PAN: ${owner.panNumber}',
                                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text('User Name: ${owner.username}', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
                                        Text('Email: ${owner.email}', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
                                        Text('Business Address: ${owner.businessAddress}', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
                                        const Divider(color: Colors.grey, height: 24),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () => _rejectOwner(owner.id),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.redAccent.withOpacity(0.1),
                                                foregroundColor: Colors.redAccent,
                                                side: const BorderSide(color: Colors.redAccent),
                                              ),
                                              child: const Text('Reject'),
                                            ),
                                            const SizedBox(width: 12),
                                            ElevatedButton(
                                              onPressed: () => _approveOwner(owner.id),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: themeColor,
                                                foregroundColor: Colors.black,
                                              ),
                                              child: const Text('Approve'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                  // Tab 2: Pending Futsals
                  state.isLoading
                      ? const Center(child: SpinKitFadingCircle(color: themeColor, size: 50))
                      : unapprovedFutsals.isEmpty
                          ? Center(
                              child: Text(
                                'No pending registrations.',
                                style: GoogleFonts.inter(color: Colors.grey[500]),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              itemCount: unapprovedFutsals.length,
                              itemBuilder: (context, index) {
                                final futsal = unapprovedFutsals[index];
                                return Card(
                                  color: const Color(0xFF1E1E1E),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          futsal.name,
                                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Address: ${futsal.address}', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
                                        Text('Owner Co: ${futsal.ownerCompany}', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
                                        const Divider(color: Colors.grey, height: 24),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () => _rejectFutsal(futsal.id),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.redAccent.withOpacity(0.1),
                                                foregroundColor: Colors.redAccent,
                                                side: const BorderSide(color: Colors.redAccent),
                                              ),
                                              child: const Text('Reject'),
                                            ),
                                            const SizedBox(width: 12),
                                            ElevatedButton(
                                              onPressed: () => _approveFutsal(futsal.id),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: themeColor,
                                                foregroundColor: Colors.black,
                                              ),
                                              child: const Text('Approve'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
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
}
