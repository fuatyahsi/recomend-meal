import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'l10n/app_localizations.dart';
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'services/ad_service.dart';
import 'screens/main_shell.dart';
import 'screens/auth/login_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // AdMob başlat
  try {
    await AdService().initialize();
  } catch (_) {}

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
      ],
      child: const FridgeChefApp(),
    ),
  );
}

class FridgeChefApp extends StatelessWidget {
  const FridgeChefApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final authProvider = context.watch<AuthProvider>();

    return MaterialApp(
      title: 'FridgeChef',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: appProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Localization
      locale: appProvider.locale,
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Auth-based routing
      home: _buildHome(appProvider, authProvider),
    );
  }

  Widget _buildHome(AppProvider appProvider, AuthProvider authProvider) {
    // AppProvider yükleniyorsa splash göster
    if (appProvider.isLoading) {
      return const _SplashScreen();
    }

    // AuthProvider yükleniyorsa splash göster
    if (authProvider.isLoading) {
      return const _SplashScreen();
    }

    // Giriş yapmışsa ana ekrana git
    if (authProvider.isAuthenticated) {
      return const MainShell();
    }

    // Giriş yapmamışsa login ekranına git
    return const LoginScreen();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🧑‍🍳',
              style: TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 24),
            Text(
              'FridgeChef',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
