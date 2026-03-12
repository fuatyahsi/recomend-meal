import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String photoURL;
  final String bio;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final int totalRecipesShared;
  final int totalLikesReceived;
  final int totalRatingsGiven;
  final List<String> badges;
  final String language;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL = '',
    this.bio = '',
    required this.createdAt,
    required this.updatedAt,
    this.isPremium = false,
    this.premiumExpiresAt,
    this.totalRecipesShared = 0,
    this.totalLikesReceived = 0,
    this.totalRatingsGiven = 0,
    this.badges = const [],
    this.language = 'tr',
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'] ?? '',
      bio: data['bio'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPremium: data['isPremium'] ?? false,
      premiumExpiresAt: (data['premiumExpiresAt'] as Timestamp?)?.toDate(),
      totalRecipesShared: data['totalRecipesShared'] ?? 0,
      totalLikesReceived: data['totalLikesReceived'] ?? 0,
      totalRatingsGiven: data['totalRatingsGiven'] ?? 0,
      badges: List<String>.from(data['badges'] ?? []),
      language: data['language'] ?? 'tr',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'displayName': displayName,
        'photoURL': photoURL,
        'bio': bio,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'isPremium': isPremium,
        'premiumExpiresAt': premiumExpiresAt != null
            ? Timestamp.fromDate(premiumExpiresAt!)
            : null,
        'totalRecipesShared': totalRecipesShared,
        'totalLikesReceived': totalLikesReceived,
        'totalRatingsGiven': totalRatingsGiven,
        'badges': badges,
        'language': language,
      };

  AppUser copyWith({
    String? displayName,
    String? photoURL,
    String? bio,
    bool? isPremium,
    int? totalRecipesShared,
    int? totalLikesReceived,
    int? totalRatingsGiven,
    List<String>? badges,
    String? language,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isPremium: isPremium ?? this.isPremium,
      premiumExpiresAt: premiumExpiresAt,
      totalRecipesShared: totalRecipesShared ?? this.totalRecipesShared,
      totalLikesReceived: totalLikesReceived ?? this.totalLikesReceived,
      totalRatingsGiven: totalRatingsGiven ?? this.totalRatingsGiven,
      badges: badges ?? this.badges,
      language: language ?? this.language,
    );
  }
}
