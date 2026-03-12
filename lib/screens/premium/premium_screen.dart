import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/premium_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  String _selectedPlan = 'yearly'; // yearly varsayılan
  bool _isPurchasing = false;

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isTr = appProvider.locale.languageCode == 'tr';
    final theme = Theme.of(context);
    final isPremium = authProvider.currentUser?.isPremium ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(isTr ? 'Premium' : 'Premium'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
              ),
              child: Column(
                children: [
                  const Text('👑', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    isTr
                        ? 'FridgeChef Premium'
                        : 'FridgeChef Premium',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isTr
                        ? 'Yemek deneyimini bir üst seviyeye taşı!'
                        : 'Take your cooking experience to the next level!',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isPremium) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isTr ? 'Premium Üyesin!' : 'You\'re Premium!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Özellik listesi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTr ? 'Premium Avantajlar' : 'Premium Benefits',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...PremiumService.getPremiumFeatures(
                          appProvider.locale.languageCode)
                      .map((feature) => _FeatureTile(
                            icon: feature['icon']!,
                            title: feature['title']!,
                            description: feature['description']!,
                          )),
                ],
              ),
            ),

            if (!isPremium) ...[
              const SizedBox(height: 32),

              // Plan seçimi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTr ? 'Plan Seç' : 'Choose Plan',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Yıllık Plan
                    _PlanCard(
                      isSelected: _selectedPlan == 'yearly',
                      title: isTr ? 'Yıllık Plan' : 'Yearly Plan',
                      price: isTr
                          ? '₺${PremiumService.yearlyPriceTRY.toStringAsFixed(2)}/yıl'
                          : '\$${PremiumService.yearlyPriceUSD.toStringAsFixed(2)}/year',
                      subtitle: isTr
                          ? '₺${(PremiumService.yearlyPriceTRY / 12).toStringAsFixed(2)}/ay - %33 tasarruf'
                          : '\$${(PremiumService.yearlyPriceUSD / 12).toStringAsFixed(2)}/mo - 33% savings',
                      badge: isTr ? 'En Popüler' : 'Most Popular',
                      onTap: () => setState(() => _selectedPlan = 'yearly'),
                    ),
                    const SizedBox(height: 12),

                    // Aylık Plan
                    _PlanCard(
                      isSelected: _selectedPlan == 'monthly',
                      title: isTr ? 'Aylık Plan' : 'Monthly Plan',
                      price: isTr
                          ? '₺${PremiumService.monthlyPriceTRY.toStringAsFixed(2)}/ay'
                          : '\$${PremiumService.monthlyPriceUSD.toStringAsFixed(2)}/month',
                      subtitle: isTr
                          ? 'İstediğin zaman iptal et'
                          : 'Cancel anytime',
                      onTap: () => setState(() => _selectedPlan = 'monthly'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Satın al butonu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isPurchasing ? null : _handlePurchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isPurchasing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isTr ? 'Premium\'a Geç' : 'Go Premium',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Küçük yazı
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  isTr
                      ? 'Abonelik, seçilen süre sonunda otomatik yenilenir. İstediğiniz zaman iptal edebilirsiniz.'
                      : 'Subscription auto-renews at the end of the selected period. You can cancel anytime.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePurchase() async {
    setState(() => _isPurchasing = true);

    final authProvider = context.read<AuthProvider>();
    final isTr = context.read<AppProvider>().locale.languageCode == 'tr';

    // NOT: Gerçek uygulamada burada in_app_purchase paketi kullanılacak
    // Şimdilik Firestore'a kayıt yapıyoruz
    final premiumService = PremiumService();
    final success = await premiumService.purchasePremium(
      uid: authProvider.currentUser!.uid,
      planType: _selectedPlan,
    );

    setState(() => _isPurchasing = false);

    if (mounted) {
      if (success) {
        await authProvider.refreshUser();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isTr
                  ? 'Premium\'a hoş geldin! 🎉'
                  : 'Welcome to Premium! 🎉',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isTr
                  ? 'Bir hata oluştu. Lütfen tekrar deneyin.'
                  : 'An error occurred. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _FeatureTile extends StatelessWidget {
  final String icon;
  final String title;
  final String description;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final bool isSelected;
  final String title;
  final String price;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _PlanCard({
    required this.isSelected,
    required this.title,
    required this.price,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
