/// User profile entity representing a record from public.profiles.
class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String currencyCode;
  final String currencySymbol;
  final String flightBadge;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.email,
    this.fullName = '',
    this.avatarUrl,
    this.currencyCode = 'LKR',
    this.currencySymbol = 'Rs.',
    this.flightBadge = 'Flight Captain',
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      currencyCode: json['currency_code'] as String? ?? 'LKR',
      currencySymbol: json['currency_symbol'] as String? ?? 'Rs.',
      flightBadge: json['flight_badge'] as String? ?? 'Flight Captain',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'flight_badge': flightBadge,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? currencyCode,
    String? currencySymbol,
    String? flightBadge,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      flightBadge: flightBadge ?? this.flightBadge,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Default mock profile when Supabase is unconfigured or in demo mode.
  static const mock = UserProfile(
    id: 'mock-pilot-001',
    email: 'pilot@moneypilot.com',
    fullName: 'Chief Pilot',
    currencyCode: 'LKR',
    currencySymbol: 'Rs.',
    flightBadge: 'FLIGHT CAPTAIN',
  );
}
