import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailCtrl = TextEditingController();
  bool loading = false;

  Future<void> _submit() async {
    if (emailCtrl.text.trim().isEmpty) {
      _toast('Please enter your admin email');
      return;
    }

    setState(() => loading = true);
    try {
      final data = await AuthService.forgotPassword(emailCtrl.text.trim());
      if (!mounted) return;

      _toast('Reset link generated', success: true);

      // Development flow: seedha reset screen par le jayein
      final token = data['resetToken'] as String?;
      if (token != null && token.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(token: token),
          ),
        );
      }
    } catch (e) {
      _toast(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _toast(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AuthColors.accent : AuthColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: AuthCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.lock_reset_rounded, color: Color(0xFFF4B740), size: 34),
            ),
            const SizedBox(height: 16),
            const Text(
              'Forgot Password',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AuthColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your admin email and we will generate a secure reset link.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 24),
            AuthTextField(
              controller: emailCtrl,
              label: 'Admin email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            AuthButton(text: 'Send Reset Link', loading: loading, onTap: _submit),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}