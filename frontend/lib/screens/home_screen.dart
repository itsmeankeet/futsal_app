import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../models/futsal.dart';
import '../core/utils/image_helper.dart';

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
                              onTap: () => context.push('/customer/futsal-detail', extra: futsal),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  futsal.coverImage.isNotEmpty
                                      ? Hero(
                                          tag: 'futsal-cover-${futsal.id}',
                                          child: Image.network(
                                            getImageUrl(futsal.coverImage),
                                            height: 160,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              height: 160,
                                              color: Colors.grey[900],
                                              child: const Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
                                            ),
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
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    futsal.name,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  if (futsal.isClosedToday) ...[
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.redAccent.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                                                      ),
                                                      child: Text(
                                                        'CLOSED TODAY',
                                                        style: GoogleFonts.inter(
                                                          color: Colors.redAccent,
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
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
