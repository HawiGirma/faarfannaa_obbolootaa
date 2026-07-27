class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? phoneNumber;
  final String? photoUrl;
  final bool isAdmin;
  final List<String> favoriteIds;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.phoneNumber,
    this.photoUrl,
    this.isAdmin = false,
    this.favoriteIds = const [],
    required this.createdAt,
  });

  /// Construct from a Supabase row
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['id'] as String? ?? map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['display_name'] as String? ?? '',
      phoneNumber: map['phone_number'] as String?,
      photoUrl: map['photo_url'] as String?,
      isAdmin: map['is_admin'] as bool? ?? false,
      favoriteIds: (map['favorite_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'email': email,
      'display_name': displayName,
      'phone_number': phoneNumber,
      'photo_url': photoUrl,
      'is_admin': isAdmin,
      'favorite_ids': favoriteIds,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
    bool? isAdmin,
    List<String>? favoriteIds,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      isAdmin: isAdmin ?? this.isAdmin,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      createdAt: createdAt,
    );
  }
}
