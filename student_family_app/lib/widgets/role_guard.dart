import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RoleGuard extends StatelessWidget {
  final List<String> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthService.getRole(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final role = snapshot.data ?? 'admin';
        if (allowedRoles.contains(role)) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}