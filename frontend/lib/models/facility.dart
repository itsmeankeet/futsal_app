class Facility {
  final String id;
  final String name;

  Facility({required this.id, required this.name});

  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}
