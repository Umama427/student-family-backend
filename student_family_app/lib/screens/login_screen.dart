import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';
import 'forgot_password_screen.dart';
import 'main_shell.dart';

enum LoginRole { admin, teacher, parent }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  LoginRole selectedRole = LoginRole.admin;

  final emailCtrl = TextEditingController(text: 'admin@edumanage.com');
  final passCtrl = TextEditingController(text: 'Admin@123');

  final phoneCtrl = TextEditingController();
  final pinCtrl = TextEditingController();

  bool loading = false;
  bool obscure = true;

  Future<void> _login() async {
    setState(() => loading = true);
    try {
      Map<String, dynamic> response;

      switch (selectedRole) {
        case LoginRole.admin:
          if (emailCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
            throw Exception('Email and password are required');
          }
          response = await AuthService.login(emailCtrl.text.trim(), passCtrl.text.trim());
          break;

        case LoginRole.teacher:
          if (emailCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
            throw Exception('Email and password are required');
          }
          response = await AuthService.loginTeacher(emailCtrl.text.trim(), passCtrl.text.trim());
          break;

        case LoginRole.parent:
          if (phoneCtrl.text.trim().isEmpty || pinCtrl.text.trim().isEmpty) {
            throw Exception('Phone number and PIN are required');
          }
          response = await AuthService.loginParent(phoneCtrl.text.trim(), pinCtrl.text.trim());
          break;
      }

      debugPrint("LOGIN SUCCESS: $response");

      if (!mounted) return;
      _toast('Login Successful 👋', success: true);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } catch (e) {
      debugPrint("LOGIN ERROR: $e");
      _toast(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _registerFirstAdmin() async {
    setState(() => loading = true);
    try {
      await AuthService.register(
        name: 'Umama Admin',
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );
      _toast('Admin Account Created! Now click Sign In', success: true);
    } catch (e) {
      _toast(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _toast(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: success ? const Color(0xFF2ED6A1) : const Color(0xFFE63950),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String get _roleLabel {
    switch (selectedRole) {
      case LoginRole.admin:
        return 'Admin Login • Full Access';
      case LoginRole.teacher:
        return 'Teacher Login • Class Management';
      case LoginRole.parent:
        return 'Parent Login • View Your Children';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: SingleChildScrollView(
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
                child: const Icon(Icons.school_rounded, color: AuthColors.accent, size: 34),
              ),
              const SizedBox(height: 16),
              const Text(
                'EduManage',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AuthColors.primary),
              ),
              const SizedBox(height: 6),
              Text(_roleLabel, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _roleTab('Admin', LoginRole.admin, Icons.admin_panel_settings_rounded),
                    _roleTab('Teacher', LoginRole.teacher, Icons.person_rounded),
                    _roleTab('Parent', LoginRole.parent, Icons.family_restroom_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (selectedRole == LoginRole.parent) ...[
                AuthTextField(
                  controller: phoneCtrl,
                  label: 'Phone number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                AuthTextField(
                  controller: pinCtrl,
                  label: '4-digit PIN',
                  icon: Icons.pin_outlined,
                  obscure: obscure,
                  keyboardType: TextInputType.number,
                  suffix: IconButton(
                    onPressed: () => setState(() => obscure = !obscure),
                    icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  ),
                ),
              ] else ...[
                AuthTextField(
                  controller: emailCtrl,
                  label: 'Email address',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                AuthTextField(
                  controller: passCtrl,
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscure: obscure,
                  suffix: IconButton(
                    onPressed: () => setState(() => obscure = !obscure),
                    icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  ),
                ),
              ],

              if (selectedRole == LoginRole.admin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: AuthColors.accent, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              const SizedBox(height: 8),

              AuthButton(text: 'Sign In', loading: loading, onTap: _login),

              const SizedBox(height: 12),

              if (selectedRole == LoginRole.admin)
                TextButton(
                  onPressed: _registerFirstAdmin,
                  child: const Text(
                    'First Time? Register Admin Account',
                    style: TextStyle(color: AuthColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleTab(String label, LoginRole role, IconData icon) {
    final isSelected = selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AuthColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey.shade600),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}