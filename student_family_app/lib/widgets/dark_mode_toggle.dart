import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class DarkModeToggle extends StatelessWidget {
  const DarkModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          size: 20,
          color: themeProvider.isDarkMode ? Colors.amberAccent : Colors.orange,
        ),
        const SizedBox(width: 6),
        Switch(
          value: themeProvider.isDarkMode,
          activeThumbColor: const Color(0xFF2ECC9A),
          onChanged: (_) => themeProvider.toggleTheme(),
        ),
      ],
    );
  }
}