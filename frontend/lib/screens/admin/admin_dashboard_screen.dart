import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/user.dart';
import '../../core/utils/image_helper.dart';

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
      ref.read(bookingProvider.notifier).fetchCourts(); // load all courts
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
                                final futsalCourts = state.courts.where((c) => c.futsalId == futsal.id).toList();

                                return Card(
                                    color: const Color(0xFF1E1E1E),
                                    margin: const EdgeInsets.only(bottom: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    clipBehavior: Clip.antiAlias,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        if (futsal.coverImage.isNotEmpty)
                                          Image.network(
                                            getImageUrl(futsal.coverImage),
                                            height: 120,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, err, stack) => Container(
                                              height: 120,
                                              color: Colors.grey[900],
                                            ),
                                          ),
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  if (futsal.logo.isNotEmpty) ...[
                                                    CircleAvatar(
                                                      backgroundImage: NetworkImage(getImageUrl(futsal.logo)),
                                                      radius: 20,
                                                      backgroundColor: Colors.transparent,
                                                    ),
                                                    const SizedBox(width: 12),
                                                  ],
                                                  Expanded(
                                                    child: Text(
                                                      futsal.name,
                                                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Text('Address: ${futsal.address}', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
                                              Text('Coordinates: Lat ${futsal.latitude.toStringAsFixed(4)}, Lng ${futsal.longitude.toStringAsFixed(4)}', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
                                              Text('Phone: ${futsal.contactPhone}', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
                                              if (futsal.description.isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                Text(
                                                  futsal.description,
                                                  style: GoogleFonts.inter(color: Colors.grey[550], fontSize: 12, fontStyle: FontStyle.italic),
                                                ),
                                              ],
                                              const SizedBox(height: 6),
                                              Text('Owner Co: ${futsal.ownerCompany}', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
                                              
                                              if (futsalCourts.isNotEmpty) ...[
                                                const Divider(color: Colors.grey, height: 24),
                                                Text('Registered Courts:', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                                const SizedBox(height: 8),
                                                ...futsalCourts.map((court) {
                                                  return Padding(
                                                    padding: const EdgeInsets.only(bottom: 12.0),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Text(
                                                              court.name,
                                                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                                            ),
                                                            Text(
                                                              'Rs. ${court.pricePerHour.toStringAsFixed(0)}/hr • ${court.isIndoor ? "Indoor" : "Outdoor"}',
                                                              style: GoogleFonts.inter(color: themeColor, fontSize: 12, fontWeight: FontWeight.bold),
                                                            ),
                                                          ],
                                                        ),
                                                        if (court.description.isNotEmpty)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 2.0),
                                                            child: Text(court.description, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11)),
                                                          ),
                                                        if (court.images.isNotEmpty) ...[
                                                          const SizedBox(height: 6),
                                                          SizedBox(
                                                            height: 60,
                                                            child: ListView.builder(
                                                              scrollDirection: Axis.horizontal,
                                                              itemCount: court.images.length,
                                                              itemBuilder: (context, cImgIndex) {
                                                                return Padding(
                                                                  padding: const EdgeInsets.only(right: 8),
                                                                  child: ClipRRect(
                                                                    borderRadius: BorderRadius.circular(6),
                                                                    child: Image.network(
                                                                      getImageUrl(court.images[cImgIndex]),
                                                                      width: 60,
                                                                      height: 60,
                                                                      fit: BoxFit.cover,
                                                                      errorBuilder: (context, error, stackTrace) => Container(
                                                                        width: 60,
                                                                        height: 60,
                                                                        color: Colors.grey[950],
                                                                        child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ],

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
                                      ],
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
