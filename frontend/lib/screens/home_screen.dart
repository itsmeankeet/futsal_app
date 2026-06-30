import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../models/futsal.dart';
import '../models/court.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).fetchFutsals(isApproved: true);
    });
  }

  void _showFutsalCourts(Futsal futsal) async {
    final themeColor = const Color(0xFF39FF14);
    
    // Fetch courts for this futsal
    ref.read(bookingProvider.notifier).fetchCourts(futsalId: futsal.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(bookingProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      futsal.name,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Select a Court to Book',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
                    ),
                    const Divider(color: Colors.grey, height: 24),
                    
                    state.isLoading
                        ? Center(child: SpinKitRing(color: themeColor, size: 40))
                        : state.courts.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Text(
                                    'No courts available.',
                                    style: GoogleFonts.inter(color: Colors.grey[500]),
                                  ),
                                ),
                              )
                            : Flexible(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: state.courts.length,
                                  itemBuilder: (context, index) {
                                    final court = state.courts[index];
                                    return Card(
                                      color: const Color(0xFF2D2D2D),
                                      margin: const EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        title: Text(
                                          court.name,
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          court.isIndoor ? 'Indoor • Standard' : 'Outdoor • Turf',
                                          style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
                                        ),
                                        trailing: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Rs. ${court.pricePerHour.toStringAsFixed(0)}',
                                              style: GoogleFonts.outfit(
                                                color: themeColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              '/ hr',
                                              style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10),
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          Navigator.of(context).pop(); // close sheet
                                          context.push('/customer/court-detail', extra: court);
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final state = ref.watch(bookingProvider);
    const themeColor = Color(0xFF39FF14);

    final filteredFutsals = state.futsals.where((f) {
      return f.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          f.address.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kickoff Arena',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
            ),
            Text(
              authState.user?.username ?? 'Customer',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: themeColor),
            onPressed: () => context.push('/customer/bookings'),
          ),
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
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: GoogleFonts.inter(color: Colors.white),
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Search arenas or location...',
                prefixIcon: Icon(Icons.search, color: themeColor),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Popular Arenas',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Futsal list
          Expanded(
            child: state.isLoading
                ? const Center(child: SpinKitFadingCircle(color: themeColor, size: 50))
                : filteredFutsals.isEmpty
                    ? Center(
                        child: Text(
                          'No futsal arenas found.',
                          style: GoogleFonts.inter(color: Colors.grey[500]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredFutsals.length,
                        itemBuilder: (context, index) {
                          final futsal = filteredFutsals[index];
                          return Card(
                            color: const Color(0xFF1E1E1E),
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => _showFutsalCourts(futsal),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  futsal.coverImage.isNotEmpty
                                      ? Image.network(
                                          futsal.coverImage,
                                          height: 160,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            height: 160,
                                            color: Colors.grey[900],
                                            child: const Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
                                          ),
                                        )
                                      : Container(
                                          height: 160,
                                          color: Colors.grey[900],
                                          child: const Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
                                        ),
                                  Padding(
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
                                                style: GoogleFonts.outfit(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                                const SizedBox(width: 4),
                                                Text(
                                                  futsal.averageRating.toStringAsFixed(1),
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, size: 16, color: themeColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              futsal.address,
                                              style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
