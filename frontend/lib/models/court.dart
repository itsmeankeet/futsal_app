class FutsalCourt {
  final String id;
  final String futsalId;
  final String futsalName;
  final String name;
  final bool isIndoor;
  final double pricePerHour;
  final String description;
  final String status;
  final List<String> images;

  FutsalCourt({
    required this.id,
    required this.futsalId,
    required this.futsalName,
    required this.name,
    required this.isIndoor,
    required this.pricePerHour,
    required this.description,
    required this.status,
    required this.images,
  });

  bool get isActive => status == 'ACTIVE';

  factory FutsalCourt.fromJson(Map<String, dynamic> json) {
    return FutsalCourt(
      id: json['id'] ?? '',
      futsalId: json['futsal'] ?? '',
      futsalName: json['futsal_name'] ?? '',
      name: json['name'] ?? '',
      isIndoor: json['is_indoor'] ?? true,
      pricePerHour: double.parse((json['price_per_hour'] ?? 0.0).toString()),
      description: json['description'] ?? '',
      status: json['status'] ?? 'ACTIVE',
      images: json['images'] != null
          ? (json['images'] as List).map<String>((img) => img['image_url']?.toString() ?? '').toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'futsal': futsalId,
      'name': name,
      'is_indoor': isIndoor,
      'price_per_hour': pricePerHour,
      'description': description,
      'status': status,
    };
  }
}
