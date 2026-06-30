class OwnerProfile {
  final String id;
  final String username;
  final String email;
  final String companyName;
  final String panNumber;
  final String businessAddress;
  final bool isVerified;

  OwnerProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.companyName,
    required this.panNumber,
    required this.businessAddress,
    required this.isVerified,
  });

  factory OwnerProfile.fromJson(Map<String, dynamic> json) {
    return OwnerProfile(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      companyName: json['company_name'] ?? '',
      panNumber: json['pan_number'] ?? '',
      businessAddress: json['business_address'] ?? '',
      isVerified: json['is_verified'] ?? false,
    );
  }
}

class CustomerProfile {
  final String phone;
  final String avatarUrl;

  CustomerProfile({
    required this.phone,
    required this.avatarUrl,
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      phone: json['phone'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
    );
  }
}

class AppUser {
  final String id;
  final String username;
  final String email;
  final String role;
  final OwnerProfile? ownerProfile;
  final CustomerProfile? customerProfile;

  AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.ownerProfile,
    this.customerProfile,
  });

  bool get isAdmin => role == 'ADMIN';
  bool get isOwner => role == 'OWNER';
  bool get isCustomer => role == 'CUSTOMER';

  String get phone => customerProfile?.phone ?? '';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'CUSTOMER',
      ownerProfile: json['owner_profile'] != null ? OwnerProfile.fromJson(json['owner_profile']) : null,
      customerProfile: json['customer_profile'] != null ? CustomerProfile.fromJson(json['customer_profile']) : null,
    );
  }
}
