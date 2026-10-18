import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/auth_service.dart';
import 'services/payment_export_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'utils/app_theme.dart';
import 'utils/app_dark_theme.dart';

import 'providers/dashboard_provider.dart';
import 'providers/family_provider.dart';
import 'providers/student_provider.dart';
import 'providers/fee_provider.dart';
import 'providers/staff_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/exam_provider.dart';
import 'providers/result_provider.dart';
import 'providers/audit_log_provider.dart';
import 'providers/class_provider.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ FIX: Fonts ko app start hone se PEHLE download/cache kar lo
  GoogleFonts.config.allowRuntimeFetching = true;
  await GoogleFonts.pendingFonts([
    GoogleFonts.poppins(),
    GoogleFonts.poppins(fontWeight: FontWeight.w600),
    GoogleFonts.poppins(fontWeight: FontWeight.w700),
    GoogleFonts.inter(),
    GoogleFonts.inter(fontWeight: FontWeight.w500),
    GoogleFonts.inter(fontWeight: FontWeight.w600),
    GoogleFonts.inter(fontWeight: FontWeight.w700),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => FeeProvider()),
        ChangeNotifierProvider(create: (_) => StaffProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ExamProvider()),
        ChangeNotifierProvider(create: (_) => ResultProvider()),
        ChangeNotifierProvider(create: (_) => AuditLogProvider()),
        ChangeNotifierProvider(create: (_) => ClassProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // ✅ NEW
      ],
      child: const EduManageApp(),
    ),
  );
}

class EduManageApp extends StatelessWidget {
  const EduManageApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduManage',
      theme: AppTheme.themeData,
      darkTheme: AppDarkTheme.themeData, // ✅ NEW
      themeMode: themeProvider.themeMode, // ✅ NEW
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainShell(),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // ✅ NEW: Pehle check karo ke ye page Stripe payment redirect se aaya hai
    // Ye app ke HAR fresh load/reload pe chalega — chahe koi bhi screen
    // default khule (Dashboard ho ya kuch aur), payment hamesha verify ho jayega.
    await _checkPaymentReturnGlobally();

    final loggedIn = await AuthService.isLoggedIn();
    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
        _loading = false;
      });
    }
  }

  Future<void> _checkPaymentReturnGlobally() async {
    try {
      final uri = Uri.base;
      final payment = uri.queryParameters['payment'];
      final sessionId = uri.queryParameters['session_id'];

      if (payment == 'success' && sessionId != null && sessionId.isNotEmpty) {
        await PaymentExportService.verifyStripeSession(sessionId);

        // ✅ URL ko clean kar do taake refresh karne par dobara verify na ho
        html.window.history.replaceState(null, '', '/');
      }
    } catch (e) {
      // Silent fail yahan — Fee Challans screen apna khud ka check/retry
      // karegi aur user ko proper error dikhayegi agar zaroorat padi.
      debugPrint('Global payment verify failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A172B), Color(0xFF0F1C2E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.mintGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.mintEmerald.withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 20),
                const CircularProgressIndicator(color: AppColors.mintEmerald),
              ],
            ),
          ),
        ),
      );
    }
    return _isLoggedIn ? const MainShell() : const LoginScreen();
  }
}