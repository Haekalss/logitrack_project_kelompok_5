/// Model untuk User Profile data
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final int totalDeliveries;
  final int completedDeliveries;
  final double rating;
  final DateTime joinDate;
  final DateTime lastUpdated;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    this.totalDeliveries = 0,
    this.completedDeliveries = 0,
    this.rating = 0.0,
    required this.joinDate,
    required this.lastUpdated,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      totalDeliveries: json['totalDeliveries'] as int? ?? 0,
      completedDeliveries: json['completedDeliveries'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      joinDate: DateTime.parse(json['joinDate'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'totalDeliveries': totalDeliveries,
      'completedDeliveries': completedDeliveries,
      'rating': rating,
      'joinDate': joinDate.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    int? totalDeliveries,
    int? completedDeliveries,
    double? rating,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      rating: rating ?? this.rating,
      joinDate: joinDate,
      lastUpdated: DateTime.now(),
    );
  }

  double get completionRate {
    if (totalDeliveries == 0) return 0.0;
    return (completedDeliveries / totalDeliveries) * 100;
  }

  String get experienceLevel {
    if (totalDeliveries >= 100) return 'Expert Driver';
    if (totalDeliveries >= 50) return 'Experienced Driver';
    if (totalDeliveries >= 20) return 'Regular Driver';
    if (totalDeliveries >= 5) return 'New Driver';
    return 'Rookie Driver';
  }
}