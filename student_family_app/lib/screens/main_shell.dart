import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/app_sidebar.dart';
import '../services/auth_service.dart';
import '../config/menu_items.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  String? _role;
  List<MenuItem> _menuItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRoleAndMenu();
  }

  Future<void> _loadRoleAndMenu() async {
    final role = await AuthService.getRole() ?? 'admin';
    setState(() {
      _role = role;
      _menuItems = allMenuItems.where((item) => item.allowedRoles.contains(role)).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Row(
        children: [
          AppSidebar(
            menuItems: _menuItems,
            role: _role ?? 'admin',
            selectedIndex: _selectedIndex,
            onItemSelected: (index) => setState(() => _selectedIndex = index),
          ),
          Expanded(
            child: _menuItems.isNotEmpty
                ? _menuItems[_selectedIndex].screenBuilder()
                : const Center(child: Text('No screens available for your role')),
          ),
        ],
      ),
    );
  }
}