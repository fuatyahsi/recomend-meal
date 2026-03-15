import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../main_shell.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
    );
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
      return;
    }

    if (auth.error == null) {
      final isTr = AppLocalizations.of(context).languageCode == 'tr';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isTr ? 'Kayit olusturulamadi.' : 'Sign-up failed.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isTr = AppLocalizations.of(context).languageCode == 'tr';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      const Text('👨‍🍳', style: TextStyle(fontSize: 60)),
                      const SizedBox(height: 8),
                      Text(
                        isTr ? 'Yeni Hesap Oluştur' : 'Create New Account',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isTr
                            ? 'Toplulukla tariflerini paylaş!'
                            : 'Share your recipes with the community!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                if (auth.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(auth.error!,
                        style: TextStyle(color: Colors.red.shade800)),
                  ),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: isTr ? 'Ad Soyad' : 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? (isTr ? 'İsim gerekli' : 'Name required')
                      : null,
                ),
                const SizedBox(height: 14),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'E-posta / Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return isTr ? 'E-posta gerekli' : 'Email required';
                    }
                    if (!v.contains('@')) {
                      return isTr ? 'Geçerli e-posta girin' : 'Enter valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: isTr ? 'Şifre' : 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return isTr
                          ? 'Şifre en az 6 karakter olmalı'
                          : 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Confirm Password
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: isTr ? 'Şifre Tekrar' : 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return isTr ? 'Şifreler eşleşmiyor' : 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(
                            isTr ? 'Kayıt Ol' : 'Sign Up',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(isTr ? 'Zaten hesabın var mı?' : 'Already have an account?'),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: Text(isTr ? 'Giriş Yap' : 'Sign In',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
