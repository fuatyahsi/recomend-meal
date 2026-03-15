import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/premium_service.dart';
import '../auth/login_screen.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  String _selectedPlan = 'yearly';
  bool _isPurchasing = false;

  List<Map<String, String>> _premiumFeatures(bool isTr) {
    return [
      {
        'icon': 'ads',
        'title': isTr ? 'Reklamsiz Deneyim' : 'Ad-Free Experience',
        'description': isTr
            ? 'Banner reklamlar gizlenir, tarif akisi daha temiz olur.'
            : 'Banner ads are hidden for a cleaner recipe flow.',
      },
      {
        'icon': 'badge',
        'title': isTr ? 'Premium Rozet' : 'Premium Badge',
        'description': isTr
            ? 'Profilinde premium uyelik rozeti gorunur.'
            : 'Your profile shows an active premium badge.',
      },
      {
        'icon': 'chef',
        'title': isTr ? 'Erken Deneyim Erisimi' : 'Early Access',
        'description': isTr
            ? 'Yeni mutfak deneyimleri once premium katmaninda acilir.'
            : 'New cooking experiences appear in the premium layer first.',
      },
      {
        'icon': 'filter',
        'title': isTr ? 'Premium Karar Araclari' : 'Premium Decision Tools',
        'description': isTr
            ? 'Daha zengin filtreleme ve hizli karar akislarina alan ayrildi.'
            : 'A dedicated area is reserved for richer filters and quick decision flows.',
      },
      {
        'icon': 'community',
        'title': isTr ? 'Ozel Challenge Sezonlari' : 'Special Challenge Seasons',
        'description': isTr
            ? 'Topluluk challenge serilerinin ozel sezonlari once burada acilir.'
            : 'Special community challenge seasons appear here first.',
      },
      {
        'icon': 'support',
        'title': isTr ? 'Uygulamayi Destekle' : 'Support the App',
        'description': isTr
            ? 'Premium, reklamsiz deneyimin yaninda uygulamanin gelisimini de destekler.'
            : 'Premium helps fund the app in addition to unlocking an ad-free experience.',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isTr = appProvider.locale.languageCode == 'tr';
    final isPremium = authProvider.currentUser?.isPremium ?? false;
    final isAuthenticated = authProvider.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _PremiumHeader(
              isTr: isTr,
              isPremium: isPremium,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
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
                  ..._premiumFeatures(isTr)
                      .map(
                        (feature) => _FeatureTile(
                          iconKey: feature['icon']!,
                          title: feature['title']!,
                          description: feature['description']!,
                        ),
                      ),
                ],
              ),
            ),
            if (!isPremium) ...[
              if (!isAuthenticated)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.login, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isTr
                                ? 'Premium burada. Planlari inceleyebilirsin, satin alma icin once giris yapman gerekir.'
                                : 'Premium is here. You can browse the plans now and sign in before purchase.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTr ? 'Plan Sec' : 'Choose Plan',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PlanCard(
                      isSelected: _selectedPlan == 'yearly',
                      title: isTr ? 'Yillik Plan' : 'Yearly Plan',
                      price: isTr
                          ? 'TRY ${PremiumService.yearlyPriceTRY.toStringAsFixed(2)}/yil'
                          : '\$${PremiumService.yearlyPriceUSD.toStringAsFixed(2)}/year',
                      subtitle: isTr
                          ? 'Aylik ortalama ile daha avantajli'
                          : 'Best value on a monthly average',
                      badge: isTr ? 'Populer' : 'Popular',
                      onTap: () => setState(() => _selectedPlan = 'yearly'),
                    ),
                    const SizedBox(height: 12),
                    _PlanCard(
                      isSelected: _selectedPlan == 'monthly',
                      title: isTr ? 'Aylik Plan' : 'Monthly Plan',
                      price: isTr
                          ? 'TRY ${PremiumService.monthlyPriceTRY.toStringAsFixed(2)}/ay'
                          : '\$${PremiumService.monthlyPriceUSD.toStringAsFixed(2)}/month',
                      subtitle: isTr ? 'Istedigin zaman iptal et' : 'Cancel anytime',
                      onTap: () => setState(() => _selectedPlan = 'monthly'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isPurchasing ? null : _handlePurchase,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isPurchasing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isAuthenticated
                                ? (isTr ? 'Premiuma Gec' : 'Go Premium')
                                : (isTr ? 'Giris Yap ve Devam Et' : 'Sign In to Continue'),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  isTr
                      ? 'Bu ekran su anda gorunur durumda. Satin alma akisi ise uygulama ici simulasyon olarak calisiyor.'
                      : 'This screen is fully visible now. The purchase flow currently works as an in-app simulation.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
    if (!authProvider.isAuthenticated || authProvider.currentUser == null) {
      if (!mounted) return;
      setState(() => _isPurchasing = false);
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final premiumService = PremiumService();
    final success = await premiumService.purchasePremium(
      uid: authProvider.currentUser!.uid,
      planType: _selectedPlan,
    );

    if (!mounted) return;
    setState(() => _isPurchasing = false);

    if (success) {
      await authProvider.refreshUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isTr ? 'Premium aktif edildi.' : 'Premium activated.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isTr ? 'Bir hata olustu. Lutfen tekrar dene.' : 'An error occurred. Please try again.',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class _PremiumHeader extends StatelessWidget {
  final bool isTr;
  final bool isPremium;

  const _PremiumHeader({
    required this.isTr,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium,
              size: 42,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'FridgeChef Premium',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isTr
                ? 'Reklamsiz, daha guclu ve daha ozel bir mutfak deneyimi.'
                : 'Ad-free, sharper and more premium cooking flows.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          if (isPremium) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    isTr ? 'Premium uyeligin aktif' : 'Your premium membership is active',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final String iconKey;
  final String title;
  final String description;

  const _FeatureTile({
    required this.iconKey,
    required this.title,
    required this.description,
  });

  IconData _resolveIcon() {
    switch (iconKey) {
      case 'ads':
        return Icons.visibility_off;
      case 'chef':
        return Icons.auto_awesome;
      case 'filter':
        return Icons.tune;
      case 'community':
        return Icons.emoji_events;
      case 'support':
        return Icons.favorite;
      case 'badge':
        return Icons.workspace_premium;
      default:
        return Icons.star_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _resolveIcon(),
              color: theme.colorScheme.primary,
            ),
          ),
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

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.35),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
            ),
            const SizedBox(width: 14),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(999),
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
