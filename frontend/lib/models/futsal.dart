import 'facility.dart';

class Futsal {
  final String id;
  final String owner;
  final String ownerCompany;
  final String name;
  final String address;
  final String contactPhone;
  final double latitude;
  final double longitude;
  final String openingHours;
  final String closingHours;
  final bool isApproved;
  final bool isClosedToday;
  final String logo;
  final String coverImage;
  final List<Facility> facilities;
  final double averageRating;
  final String description;

  Futsal({
    required this.id,
    required this.owner,
    required this.ownerCompany,
    required this.name,
    required this.address,
    required this.contactPhone,
    required this.latitude,
    required this.longitude,
    required this.openingHours,
    required this.closingHours,
    required this.isApproved,
    required this.isClosedToday,
    required this.logo,
    required this.coverImage,
    required this.facilities,
    required this.averageRating,
    required this.description,
  });

  factory Futsal.fromJson(Map<String, dynamic> json) {
    return Futsal(
      id: json['id'] ?? '',
      owner: json['owner'] ?? '',
      ownerCompany: json['owner_company'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      contactPhone: json['contact_phone'] ?? '',
      latitude: double.parse((json['latitude'] ?? 0.0).toString()),
      longitude: double.parse((json['longitude'] ?? 0.0).toString()),
      openingHours: json['opening_hours'] ?? '',
      closingHours: json['closing_hours'] ?? '',
      isApproved: json['is_approved'] ?? false,
      isClosedToday: json['is_closed_today'] ?? false,
      logo: json['logo'] ?? '',
      coverImage: json['cover_image'] ?? '',
      facilities: json['facilities'] != null
          ? (json['facilities'] as List).map((f) => Facility.fromJson(f)).toList()
          : [],
      averageRating: double.parse((json['average_rating'] ?? 0.0).toString()),
      description: json['description'] ?? '',
    );
  }
}
