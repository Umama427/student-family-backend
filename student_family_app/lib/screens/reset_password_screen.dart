import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  bool loading = false;
  bool obscure1 = true;
  bool obscure2 = true;

  Future<void> _reset() async {
    if (passCtrl.text.length < 6) {
      _toast('Password must be at least 6 characters');
      return;
    }
    if (passCtrl.text != confirmCtrl.text) {
      _toast('Passwords do not match');
      return;
    }

    setState(() => loading = true);
    try {
      await AuthService.resetPassword(
        token: widget.token,
        password: passCtrl.text.trim(),
      );
      if (!mounted) return;
      _toast('Password updated successfully', success: true);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
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
                color: AuthColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.verified_user_rounded, color: AuthColors.accent, size: 34),
            ),
            const SizedBox(height: 16),
            const Text(
              'Reset Password',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AuthColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a strong new password for your admin account.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 24),
            AuthTextField(
              controller: passCtrl,
              label: 'New password',
              icon: Icons.lock_outline_rounded,
              obscure: obscure1,
              suffix: IconButton(
                onPressed: () => setState(() => obscure1 = !obscure1),
                icon: Icon(obscure1 ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
            ),
            AuthTextField(
              controller: confirmCtrl,
              label: 'Confirm password',
              icon: Icons.lock_person_outlined,
              obscure: obscure2,
              suffix: IconButton(
                onPressed: () => setState(() => obscure2 = !obscure2),
                icon: Icon(obscure2 ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
            ),
            AuthButton(text: 'Update Password', loading: loading, onTap: _reset),
          ],
        ),
      ),
    );
  }
}