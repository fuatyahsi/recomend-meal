import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isTr = AppLocalizations.of(context).languageCode == 'tr';

    return Scaffold(
      appBar: AppBar(title: Text(isTr ? 'Şifre Sıfırla' : 'Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Center(child: Text('🔑', style: TextStyle(fontSize: 60))),
            const SizedBox(height: 20),
            Text(
              isTr
                  ? 'E-posta adresini gir, şifre sıfırlama bağlantısı gönderelim.'
                  : 'Enter your email and we will send a password reset link.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            if (_sent)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isTr
                      ? 'Şifre sıfırlama bağlantısı gönderildi! E-postanı kontrol et.'
                      : 'Password reset link sent! Check your email.',
                  style: TextStyle(color: Colors.green.shade800),
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-posta / Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          final success = await auth
                              .resetPassword(_emailController.text.trim());
                          if (success) setState(() => _sent = true);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: auth.isLoading
                      ? const CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white)
                      : Text(isTr ? 'Gönder' : 'Send'),
                ),
              ),
            ],

            if (auth.error != null && !_sent)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(auth.error!,
                    style: TextStyle(color: Colors.red.shade700),
                    textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
    );
  }
}
