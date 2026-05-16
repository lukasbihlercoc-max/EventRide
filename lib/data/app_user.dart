class CarInfo {
  final String make;
  final String model;
  final String? color;
  final int? seats;

  const CarInfo({
    required this.make,
    required this.model,
    this.color,
    this.seats,
  });

  factory CarInfo.fromMap(Map<String, dynamic> map) => CarInfo(
        make: map['make'] as String? ?? '',
        model: map['model'] as String? ?? '',
        color: map['color'] as String?,
        seats: map['seats'] as int?,
      );

  Map<String, dynamic> toMap() => {
        'make': make,
        'model': model,
        'color': color,
        'seats': seats,
      };
}

class AppUser {
  final String userId;
  final String name;
  final String email;
  final String? photoUrl;
  final bool emailVerified;
  final String? phone;
  final bool phoneVerified;
  // 'none' | 'pending' | 'verified' | 'rejected'
  final String licenseStatus;
  final String? homeTown;
  final double? homeTownLat;
  final double? homeTownLng;
  final CarInfo? car;
  final String? licenseRejectReason;

  final double? ratingAvg;
  final int ratingCount;

  const AppUser({
    required this.userId,
    required this.name,
    required this.email,
    this.photoUrl,
    this.emailVerified = false,
    this.phone,
    this.phoneVerified = false,
    this.licenseStatus = 'none',
    this.homeTown,
    this.homeTownLat,
    this.homeTownLng,
    this.car,
    this.licenseRejectReason,
    this.ratingAvg,
    this.ratingCount = 0,
  });

  int get trustLevel {
    int count = 0;
    if (emailVerified) count++;
    if (phoneVerified) count++;
    if (licenseStatus == 'verified') count++;
    return count;
  }
}
