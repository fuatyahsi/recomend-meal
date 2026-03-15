import 'package:cloud_firestore/cloud_firestore.dart';

class PremiumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime? _readPremiumExpiry(Map<String, dynamic> data) {
    final expiryTimestamp = data['premiumExpiresAt'] as Timestamp? ??
        data['premiumExpiry'] as Timestamp?;
    return expiryTimestamp?.toDate();
  }

  static const double monthlyPriceTRY = 49.99;
  static const double yearlyPriceTRY = 399.99;
  static const double monthlyPriceUSD = 4.99;
  static const double yearlyPriceUSD = 39.99;

  static List<Map<String, String>> getPremiumFeatures(String langCode) {
    final isTr = langCode == 'tr';
    return [
      {
        'icon': 'mute',
        'title': isTr ? 'Reklamsiz Deneyim' : 'Ad-Free Experience',
        'description': isTr
            ? 'Tarif akisini reklam kesintisi olmadan kullan.'
            : 'Use the recipe flow without ad interruptions.',
      },
      {
        'icon': 'star',
        'title': isTr ? 'Ozel Tarifler' : 'Exclusive Recipes',
        'description': isTr
            ? 'Sadece premium katmanda acilan secili tarifler.'
            : 'Selected recipes unlocked only in the premium layer.',
      },
      {
        'icon': 'filter',
        'title': isTr ? 'Gelismis Filtreleme' : 'Advanced Filtering',
        'description': isTr
            ? 'Sure, zorluk ve mutfak akisina gore daha iyi filtrele.'
            : 'Filter better by time, difficulty and cooking flow.',
      },
      {
        'icon': 'community',
        'title': isTr ? 'Ozel Challenge Sezonlari' : 'Special Challenge Seasons',
        'description': isTr
            ? 'Topluluk challenge sezonlarinda erken erisim ve ozel akislar.'
            : 'Early access and special flows for community challenge seasons.',
      },
      {
        'icon': 'support',
        'title': isTr ? 'Uygulamaya Destek' : 'Support the App',
        'description': isTr
            ? 'Premium, reklamsiz deneyimin yaninda uygulamanin gelisimini destekler.'
            : 'Premium supports the app in addition to unlocking an ad-free experience.',
      },
      {
        'icon': 'badge',
        'title': isTr ? 'Premium Rozet' : 'Premium Badge',
        'description': isTr
            ? 'Profilinde premium uyelik rozeti gorunur.'
            : 'Your profile shows an active premium badge.',
      },
    ];
  }

  Future<bool> checkPremiumStatus(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final isPremium = data['isPremium'] ?? false;
        if (isPremium) {
          final premiumExpiry = _readPremiumExpiry(data);
          if (premiumExpiry != null) {
            return premiumExpiry.isAfter(DateTime.now());
          }
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> purchasePremium({
    required String uid,
    required String planType,
  }) async {
    try {
      DateTime expiryDate;
      if (planType == 'monthly') {
        expiryDate = DateTime.now().add(const Duration(days: 30));
      } else {
        expiryDate = DateTime.now().add(const Duration(days: 365));
      }

      await _firestore.collection('users').doc(uid).update({
        'isPremium': true,
        'premiumPlan': planType,
        'premiumStartDate': FieldValue.serverTimestamp(),
        'premiumExpiresAt': Timestamp.fromDate(expiryDate),
        'premiumExpiry': FieldValue.delete(),
      });

      await _firestore.collection('premium_purchases').add({
        'uid': uid,
        'planType': planType,
        'purchaseDate': FieldValue.serverTimestamp(),
        'expiryDate': Timestamp.fromDate(expiryDate),
        'status': 'active',
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelPremium(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isPremium': false,
        'premiumPlan': null,
        'premiumStartDate': FieldValue.delete(),
        'premiumExpiresAt': FieldValue.delete(),
        'premiumExpiry': FieldValue.delete(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
