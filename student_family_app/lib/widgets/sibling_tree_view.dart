import 'package:flutter/material.dart';
import '../models/family_model.dart';
import '../models/student_model.dart';
import '../utils/app_theme.dart';

class SiblingTreeView extends StatelessWidget {
  final FamilyModel family;
  final List<StudentModel> students;

  const SiblingTreeView({super.key, required this.family, required this.students});

  Color _discountColor(double percentage) {
    if (percentage == 0) return AppColors.deepNavy;
    if (percentage < 20) return AppColors.accentGold;
    return AppColors.coral;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.cardWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 650,
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Family Sibling Tree',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textDarkColor),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: context.textGreyColor),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ===== PARENT NODE =====
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.deepNavy.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.home_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                family.familyName,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${family.fatherName}  •  ${family.primaryPhone}',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ===== CONNECTOR LINE =====
                    if (students.isNotEmpty)
                      Container(
                        width: 2,
                        height: 30,
                        color: AppColors.mintEmerald.withValues(alpha: 0.4),
                      ),

                    // ===== CHILDREN NODES =====
                    if (students.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: context.textGreyColor.withValues(alpha: 0.5), size: 40),
                            const SizedBox(height: 10),
                            Text('No students are linked to this family yet.',
                                style: TextStyle(color: context.textGreyColor)),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          if (students.length > 1)
                            Container(
                              height: 2,
                              width: (students.length * 170.0).clamp(0, 580),
                              color: AppColors.mintEmerald.withValues(alpha: 0.4),
                            ),
                          const SizedBox(height: 0),
                          Wrap(
                            spacing: 20,
                            runSpacing: 24,
                            alignment: WrapAlignment.center,
                            children: students.map((student) {
                              final color = _discountColor(student.discountPercentage);
                              return Column(
                                children: [
                                  Container(width: 2, height: 20, color: AppColors.mintEmerald.withValues(alpha: 0.4)),
                                  Container(
                                    width: 150,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: context.cardWhite,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: color.withValues(alpha: 0.25)),
                                      boxShadow: context.cardShadow,
                                    ),
                                    child: Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: color.withValues(alpha: 0.12),
                                          child: Icon(
                                            student.gender.toLowerCase() == 'female'
                                                ? Icons.girl_rounded
                                                : Icons.boy_rounded,
                                            color: color,
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          student.fullName,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: context.textDarkColor),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Class ${student.className} • ${student.rollNumber}',
                                          style: TextStyle(fontSize: 10.5, color: context.textGreyColor),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            student.discountPercentage == 0
                                                ? 'No Discount'
                                                : '${student.discountPercentage.toInt()}% OFF',
                                            style: TextStyle(
                                                color: color, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}