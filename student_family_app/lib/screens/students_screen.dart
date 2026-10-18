import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../providers/family_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/add_student_dialog.dart';
import '../widgets/role_guard.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false).fetchStudents();
      Provider.of<FamilyProvider>(context, listen: false).fetchFamilies();
    });
  }

  void _openAddDialog() {
    showDialog(context: context, builder: (_) => const AddStudentDialog());
  }

  Color _discountColor(double percentage) {
    if (percentage == 0) return AppColors.deepNavy;
    if (percentage < 20) return AppColors.accentGold;
    return AppColors.coral;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentProvider>(
      builder: (context, provider, child) {
        final filtered = provider.students
            .where((s) => s.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                s.rollNumber.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Students', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${provider.students.length} students enrolled',
                            style: TextStyle(color: context.textGreyColor, fontSize: 14)),
                      ],
                    ),
                    RoleGuard(
                      allowedRoles: const ['admin'],
                      child: ElevatedButton.icon(
                        onPressed: _openAddDialog,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Add Student'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Container(
                  decoration: BoxDecoration(
                    color: context.cardWhite,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: context.cardShadow,
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: TextStyle(color: context.textDarkColor),
                    decoration: InputDecoration(
                      hintText: 'Search by name or roll number...',
                      hintStyle: TextStyle(color: context.textMutedColor),
                      prefixIcon: Icon(Icons.search_rounded, color: context.textGreyColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: context.cardWhite,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.mintEmerald))
                      : filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.school_rounded, size: 70, color: context.textGreyColor.withValues(alpha: 0.3)),
                                  const SizedBox(height: 16),
                                  Text('No students found',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.textDarkColor)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final student = filtered[index];
                                final color = _discountColor(student.discountPercentage);

                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: context.cardWhite,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: context.cardShadow,
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: color.withValues(alpha: 0.12),
                                        child: Icon(
                                          student.gender.toLowerCase() == 'female' ? Icons.girl_rounded : Icons.boy_rounded,
                                          color: color,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(student.fullName,
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.textDarkColor)),
                                            const SizedBox(height: 2),
                                            Text('${student.rollNumber} • Class ${student.className}',
                                                style: TextStyle(fontSize: 12.5, color: context.textGreyColor)),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(student.familyName,
                                            style: TextStyle(fontSize: 13, color: context.textDarkColor)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          student.discountPercentage == 0 ? 'No Discount' : '${student.discountPercentage.toInt()}% OFF',
                                          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text('Rs. ${student.monthlyTuitionFee.toStringAsFixed(0)}',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textDarkColor)),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}