import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exam_model.dart';
import '../providers/result_provider.dart';
import '../providers/student_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/enter_marks_dialog.dart';
import '../widgets/grade_badge.dart';

class ExamResultsScreen extends StatefulWidget {
  final ExamModel exam;

  const ExamResultsScreen({super.key, required this.exam});

  @override
  State<ExamResultsScreen> createState() => _ExamResultsScreenState();
}

class _ExamResultsScreenState extends State<ExamResultsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ResultProvider>(context, listen: false).fetchResultsByExam(widget.exam.id);
      Provider.of<StudentProvider>(context, listen: false).fetchStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgLight,
      appBar: AppBar(
        title: Text(widget.exam.examName),
        backgroundColor: context.cardWhite,
        foregroundColor: context.textDarkColor,
        elevation: 0,
      ),
      body: Consumer2<ResultProvider, StudentProvider>(
        builder: (context, resultProvider, studentProvider, child) {
          final classStudents = studentProvider.students
              .where((s) => s.className == widget.exam.className)
              .toList();

          final resultsMap = {for (var r in resultProvider.examResults) r.studentId: r};
          final summary = resultProvider.classSummary;

          return Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (summary != null) _buildSummaryCards(context, summary),
                const SizedBox(height: 24),
                Text('Class ${widget.exam.className} — ${classStudents.length} Students',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textDarkColor)),
                const SizedBox(height: 16),
                Expanded(
                  child: resultProvider.isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.mintEmerald))
                      : ListView.separated(
                          itemCount: classStudents.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final student = classStudents[index];
                            final result = resultsMap[student.id];

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: context.cardWhite,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: context.cardShadow,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(student.fullName,
                                        style: TextStyle(fontWeight: FontWeight.w600, color: context.textDarkColor)),
                                  ),
                                  if (result != null) ...[
                                    Expanded(
                                      child: Text(
                                          '${result.totalMarksObtained.toInt()}/${result.totalMaxMarks.toInt()}',
                                          style: TextStyle(color: context.textGreyColor)),
                                    ),
                                    Expanded(
                                      child: Text('${result.percentage.toStringAsFixed(1)}%',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: context.textDarkColor)),
                                    ),
                                    GradeBadge(grade: result.overallGrade),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (result.status == 'Pass' ? AppColors.mintEmerald : AppColors.coral)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        result.status,
                                        style: TextStyle(
                                          color: result.status == 'Pass' ? AppColors.mintEmerald : AppColors.coral,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ] else
                                    Expanded(
                                      flex: 3,
                                      child: Text('Not graded yet',
                                          style: TextStyle(color: context.textGreyColor, fontStyle: FontStyle.italic)),
                                    ),
                                  const SizedBox(width: 10),
                                  TextButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => EnterMarksDialog(
                                          exam: widget.exam,
                                          studentId: student.id,
                                          studentName: student.fullName,
                                        ),
                                      );
                                    },
                                    icon: Icon(result != null ? Icons.edit : Icons.add, size: 16),
                                    label: Text(result != null ? 'Edit' : 'Enter Marks'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, Map<String, dynamic> summary) {
    return Row(
      children: [
        _summaryCard(context, 'Total Students', '${summary['totalStudents'] ?? 0}', AppColors.deepNavy),
        const SizedBox(width: 16),
        _summaryCard(context, 'Average %', '${(summary['averagePercentage'] ?? 0).toStringAsFixed(1)}%', AppColors.accentGold),
        const SizedBox(width: 16),
        _summaryCard(context, 'Passed', '${summary['passCount'] ?? 0}', AppColors.mintEmerald),
        const SizedBox(width: 16),
        _summaryCard(context, 'Failed', '${summary['failCount'] ?? 0}', AppColors.coral),
      ],
    );
  }

  Widget _summaryCard(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.cardWhite,
          borderRadius: BorderRadius.circular(14),
          boxShadow: context.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: context.textGreyColor, fontSize: 13)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}