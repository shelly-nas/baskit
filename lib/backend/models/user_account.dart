/// A signed-in Baskit account.
class UserAccount {
  final String id;
  final String email;
  final String displayName;
  final String role;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  /// Number of lists the user owns (admin overview only).
  final int? listCount;

  const UserAccount({
    required this.id,
    required this.email,
    required this.displayName,
    this.role = 'user',
    this.isActive = true,
    this.createdAt,
    this.lastLoginAt,
    this.listCount,
  });

  bool get isAdmin => role == 'admin';

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    DateTime? date(Object? value) =>
        value is String ? DateTime.tryParse(value)?.toLocal() : null;
    return UserAccount(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      role: json['role'] as String? ?? 'user',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: date(json['created_at']),
      lastLoginAt: date(json['last_login_at']),
      listCount: (json['list_count'] as num?)?.toInt(),
    );
  }
}
