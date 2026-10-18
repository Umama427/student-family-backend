import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../providers/dashboard_provider.dart';
import '../utils/app_theme.dart';
import 'bulk_result_entry_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});
  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  String teacherName = 'Teacher';
  int studentCount = 0;
  List upcomingExams = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final name = await AuthService.getUserName();
    try {
      final studentsRes = await ApiService.getStudents();
      final examsRes = await ApiService.getExams();
      setState(() {
        teacherName = name ?? 'Teacher';
        studentCount = studentsRes.length;
        upcomingExams = examsRes;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        teacherName = name ?? 'Teacher';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    final assignedClasses =
        Provider.of<DashboardProvider>(context).assignedClasses;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $teacherName 👋',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.textDarkColor),
          ),
          const SizedBox(height: 4),
          Text('Here is your teaching overview', style: TextStyle(color: context.textGreyColor)),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4,
            children: [
              _StatCard(
                title: 'My Classes',
                value: '${assignedClasses.length}',
                icon: Icons.class_rounded,
                color: Colors.blue,
              ),
              _StatCard(
                title: 'My Students',
                value: '$studentCount',
                icon: Icons.people_rounded,
                color: Colors.green,
              ),
              _StatCard(
                title: 'Upcoming Exams',
                value: '${upcomingExams.length}',
                icon: Icons.assignment_rounded,
                color: Colors.orange,
              ),
              _StatCard(
                title: 'Mark Attendance',
                value: 'Today',
                icon: Icons.fact_check_rounded,
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textDarkColor),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _ActionButton(
                label: 'Bulk Result Entry',
                icon: Icons.table_chart_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BulkResultEntryScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'My Assigned Classes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textDarkColor),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: assignedClasses
                .map<Widget>((c) => Chip(
                      label: Text(c.toString()),
                      backgroundColor: AppColors.mintEmerald.withValues(alpha: 0.1),
                      labelStyle: const TextStyle(
                          color: AppColors.mintEmerald, fontWeight: FontWeight.w600),
                    ))
                .toList(),
          ),
          const SizedBox(height: 28),
          Text(
            'Upcoming Exams',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textDarkColor),
          ),
          const SizedBox(height: 12),
          ...upcomingExams.map((e) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: context.cardWhite,
                child: ListTile(
                  leading: const Icon(Icons.event_note, color: Colors.orange),
                  title: Text(e['examName'] ?? '', style: TextStyle(color: context.textDarkColor)),
                  subtitle: Text(
                    'Class: ${e['className']} | Date: ${e['examDate'] != null ? e['examDate'].toString().split('T')[0] : '-'}',
                    style: TextStyle(color: context.textGreyColor),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.textDarkColor)),
          Text(title, style: TextStyle(color: context.textGreyColor, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.mintEmerald,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}