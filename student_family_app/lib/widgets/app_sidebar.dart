import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../config/menu_items.dart';
import '../utils/app_theme.dart';

class AppSidebar extends StatelessWidget {
  final List<MenuItem> menuItems;
  final String role;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const AppSidebar({
    super.key,
    required this.menuItems,
    required this.role,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  String get _roleBadgeText {
    switch (role) {
      case 'admin':
        return 'ADMINISTRATOR';
      case 'teacher':
        return 'TEACHER';
      case 'parent':
        return 'PARENT';
      default:
        return role.toUpperCase();
    }
  }

  Color get _roleBadgeColor {
    switch (role) {
      case 'admin':
        return const Color(0xFF2ECC9A);
      case 'teacher':
        return const Color(0xFF4FACFE);
      case 'parent':
        return const Color(0xFFF5A623);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A172B), Color(0xFF0F1C2E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.mintGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.mintEmerald.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Text(
                  'EduManage',
                  style: GoogleFonts.poppins(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),

          Divider(color: Colors.white.withOpacity(0.08), height: 1, indent: 24, endIndent: 24),

          const SizedBox(height: 16),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _roleBadgeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _roleBadgeColor.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: _roleBadgeColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  _roleBadgeText,
                  style: GoogleFonts.inter(
                    color: _roleBadgeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MENU',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.3),
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final active = selectedIndex == index;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    gradient: active
                        ? LinearGradient(
                            colors: [
                              AppColors.mintEmerald.withOpacity(0.18),
                              AppColors.mintEmerald.withOpacity(0.05),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    border: active
                        ? Border.all(color: AppColors.mintEmerald.withOpacity(0.25), width: 1)
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onItemSelected(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              color: active ? AppColors.mintEmerald : const Color(0xFF8495AD),
                              size: 20,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                item.title,
                                style: GoogleFonts.inter(
                                  color: active ? Colors.white : const Color(0xFF8495AD),
                                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                            if (active)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppColors.mintEmerald,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.mintEmerald.withOpacity(0.6),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    await AuthService.logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout_rounded, size: 17, color: Color(0xFFFF6B6B)),
                        const SizedBox(width: 10),
                        Text(
                          'Logout',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFF6B6B),
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}