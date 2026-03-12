import 'package:cloud_firestore/cloud_firestore.dart';

class PremiumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Premium plan fiyatları
  static const double monthlyPriceTRY = 49.99;
  static const double yearlyPriceTRY = 399.99;
  static const double monthlyPriceUSD = 4.99;
  static const double yearlyPriceUSD = 39.99;

  // Premium özellikler
  static List<Map<String, String>> getPremiumFeatures(String langCode) {
    final isTr = langCode == 'tr';
    return [
      {
        'icon': '🚫',
        'title': isTr ? 'Reklamsız Deneyim' : 'Ad-Free Experience',
        'description': isTr
            ? 'Tüm reklamları kaldır, kesintisiz yemek keşfet'
            : 'Remove all ads, discover recipes without interruption',
      },
      {
        'icon': '⭐',
        'title': isTr ? 'Özel Tarifler' : 'Exclusive Recipes',
        'description': isTr
            ? 'Sadece premium üyelere özel şef tarifleri'
            : 'Chef recipes exclusive to premium members',
      },
      {
        'icon': '🔍',
        'title': isTr ? 'Gelişmiş Filtreleme' : 'Advanced Filtering',
        'description': isTr
            ? 'Kalori, pişirme süresi, diyet türü ile filtrele'
            : 'Filter by calories, cooking time, diet type',
      },
      {
        'icon': '📋',
        'title': isTr ? 'Diyet Planları' : 'Diet Plans',
        'description': isTr
            ? 'Haftalık kişiselleştirilmiş yemek planları'
            : 'Weekly personalized meal plans',
      },
      {
        'icon': '📊',
        'title': isTr ? 'Besin Değerleri' : 'Nutrition Info',
        'description': isTr
            ? 'Her tarifin detaylı besin değerleri'
            : 'Detailed nutritional info for every recipe',
      },
      {
        'icon': '🏆',
        'title': isTr ? 'Premium Rozet' : 'Premium Badge',
        'description': isTr
            ? 'Profilinde özel premium rozeti göster'
            : 'Show exclusive premium badge on your profile',
      },
    ];
  }

  // Kullanıcı premium durumunu kontrol et
  Future<bool> checkPremiumStatus(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final isPremium = data['isPremium'] ?? false;
        if (isPremium) {
          // Premium bitiş tarihini kontrol et
          final premiumExpiry = data['premiumExpiry'] as Timestamp?;
          if (premiumExpiry != null) {
            return premiumExpiry.toDate().isAfter(DateTime.now());
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Premium satın al (gerçek uygulamada in_app_purchase kullanılacak)
  Future<bool> purchasePremium({
    required String uid,
    required String planType, // 'monthly' or 'yearly'
  }) async {
    try {
      // NOT: Gerçek uygulamada in_app_purchase paketi ile
      // Google Play / App Store üzerinden ödeme alınacak
      // Bu sadece veritabanı tarafının simülasyonu

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
        'premiumExpiry': Timestamp.fromDate(expiryDate),
      });

      // Premium satın alma kaydı oluştur
      await _firestore.collection('premium_purchases').add({
        'uid': uid,
        'planType': planType,
        'purchaseDate': FieldValue.serverTimestamp(),
        'expiryDate': Timestamp.fromDate(expiryDate),
        'status': 'active',
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // Premium iptal et
  Future<bool> cancelPremium(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isPremium': false,
        'premiumPlan': null,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
