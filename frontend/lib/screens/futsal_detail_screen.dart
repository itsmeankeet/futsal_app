import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/futsal.dart';
import '../providers/booking_provider.dart';
import '../core/utils/image_helper.dart';

class FutsalDetailScreen extends ConsumerStatefulWidget {
  final Futsal futsal;
  const FutsalDetailScreen({super.key, required this.futsal});

  @override
  ConsumerState<FutsalDetailScreen> createState() => _FutsalDetailScreenState();
}

class _FutsalDetailScreenState extends ConsumerState<FutsalDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).fetchCourts(futsalId: widget.futsal.id);
    });
  }

  IconData _getFacilityIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('parking')) return Icons.local_parking;
    if (n.contains('wifi')) return Icons.wifi;
    if (n.contains('shower')) return Icons.shower;
    if (n.contains('cafe')) return Icons.local_cafe;
    if (n.contains('light')) return Icons.lightbulb_outline;
    if (n.contains('locker')) return Icons.lock_outline;
    if (n.contains('water')) return Icons.local_drink;
    return Icons.check_circle_outline;
  }

  void _openGoogleMaps() async {
    final urlStr = 'https://www.google.com/maps/search/?api=1&query=${widget.futsal.latitude},${widget.futsal.longitude}';
    final url = Uri.parse(urlStr);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch maps application.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingProvider);
    const themeColor = Color(0xFF39FF14);
    final String formattedOpening = widget.futsal.openingHours.substring(0, 5);
    final String formattedClosing = widget.futsal.closingHours.substring(0, 5);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Image and Overlay
            Stack(
              clipBehavior: Clip.none,
              children: [
                Hero(
                  tag: 'futsal-cover-${widget.futsal.id}',
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      image: widget.futsal.coverImage.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(getImageUrl(widget.futsal.coverImage)),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: Colors.grey[900],
                    ),
                    child: widget.futsal.coverImage.isEmpty
                        ? const Center(child: Icon(Icons.sports_soccer, size: 80, color: Colors.grey))
                        : null,
                  ),
                ),
                // Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ),
                // Back Button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.6),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),
                // Logo Circular Overlay
                Positioned(
                  bottom: -40,
                  left: 24,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1E1E1E),
                      border: Border.all(color: themeColor, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: widget.futsal.logo.isNotEmpty
                          ? Image.network(
                              getImageUrl(widget.futsal.logo),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.sports_soccer, size: 40, color: Colors.grey),
                            )
                          : const Icon(Icons.sports_soccer, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 52),

            // Futsal Title and Basic Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.futsal.name,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.futsal.isClosedToday
                              ? Colors.redAccent.withOpacity(0.1)
                              : themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.futsal.isClosedToday
                                ? Colors.redAccent.withOpacity(0.3)
                                : themeColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          widget.futsal.isClosedToday ? 'CLOSED TODAY' : 'OPEN',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: widget.futsal.isClosedToday ? Colors.redAccent : themeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        widget.futsal.averageRating.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$formattedOpening - $formattedClosing',
                        style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Phone / Contact Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_outlined, color: themeColor, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Call Arena: ${widget.futsal.contactPhone}',
                          style: GoogleFonts.inter(color: Colors.grey[300], fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // About Section
                  Text(
                    'About Futsal Arena',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.futsal.description.isNotEmpty
                        ? widget.futsal.description
                        : 'No description available for this futsal arena yet. Apex quality sporting experience with premium courts.',
                    style: GoogleFonts.inter(color: Colors.grey[400], height: 1.5, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Facilities Section
                  Text(
                    'Available Facilities',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  widget.futsal.facilities.isEmpty
                      ? Text('No specific facilities listed.', style: GoogleFonts.inter(color: Colors.grey[500]))
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: widget.futsal.facilities.map((fac) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF161616),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey[850]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_getFacilityIcon(fac.name), color: themeColor, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    fac.name,
                                    style: GoogleFonts.inter(color: Colors.grey[350], fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 24),

                  // Location Details Card
                  Text(
                    'Location & Directions',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, color: themeColor, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.futsal.address,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Coordinates: ${widget.futsal.latitude.toStringAsFixed(4)}° N, ${widget.futsal.longitude.toStringAsFixed(4)}° E',
                                      style: GoogleFonts.inter(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _openGoogleMaps,
                            icon: const Icon(Icons.directions_outlined, size: 20),
                            label: const Text('Get Directions via Google Maps'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF262626),
                              foregroundColor: themeColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Court Selection List
                  Text(
                    'Choose a Pitch/Court',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Courts List Builder
            state.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(child: SpinKitRing(color: themeColor, size: 40)),
                  )
                : state.courts.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              'No courts registered on this arena.',
                              style: GoogleFonts.inter(color: Colors.grey[500]),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.courts.length,
                        itemBuilder: (context, index) {
                          final court = state.courts[index];
                          final hasImage = court.images.isNotEmpty;

                          return Card(
                            color: const Color(0xFF1E1E1E),
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                context.push('/customer/court-detail', extra: court);
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (hasImage)
                                    Image.network(
                                      getImageUrl(court.images.first),
                                      height: 150,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        height: 150,
                                        color: Colors.grey[900],
                                        child: const Icon(Icons.sports_soccer, size: 50, color: Colors.grey),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                court.name,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                court.isIndoor ? 'Indoor • Wooden/Rubber floor' : 'Outdoor • Artificial Turf',
                                                style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
                                              ),
                                              if (court.description.isNotEmpty) ...[
                                                const SizedBox(height: 6),
                                                Text(
                                                  court.description,
                                                  style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ]
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Rs. ${court.pricePerHour.toStringAsFixed(0)}',
                                              style: GoogleFonts.outfit(
                                                color: themeColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              '/ hr',
                                              style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10),
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
