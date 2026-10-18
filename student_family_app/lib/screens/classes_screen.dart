import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  bool isLoading = true;
  String? errorMessage;
  List classes = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final data = await ApiService.getClasses();
      setState(() {
        classes = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load classes: $e';
        isLoading = false;
      });
    }
  }

  String _teacherLabel(dynamic classTeacher) {
    if (classTeacher == null) return 'Not Assigned';
    if (classTeacher is Map) {
      return classTeacher['fullName'] ?? 'Not Assigned';
    }
    return classTeacher.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.mintEmerald,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Classes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadClasses,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(errorMessage!, style: AppText.body.copyWith(color: context.textGreyColor)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadClasses,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadClasses,
                  child: classes.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 120),
                            Center(
                              child: Text('No classes found.',
                                  style: TextStyle(color: context.textGreyColor)),
                            ),
                          ],
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(24),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 18,
                            mainAxisSpacing: 18,
                            childAspectRatio: 1.4,
                          ),
                          itemCount: classes.length,
                          itemBuilder: (context, index) {
                            final c = classes[index];
                            return Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: context.cardWhite,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                boxShadow: context.cardShadow,
                                border: Border.all(color: context.borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: AppColors.mintGradient,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.class_rounded,
                                            color: Colors.white, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '${c['className'] ?? ''} - ${c['section'] ?? ''}',
                                          style: AppText.bodyBold.copyWith(color: context.textDarkColor),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text('Class Teacher:',
                                      style: AppText.caption.copyWith(color: context.textGreyColor)),
                                  Text(_teacherLabel(c['classTeacher']),
                                      style: AppText.body.copyWith(color: context.textDarkColor)),
                                  const SizedBox(height: 10),
                                  Text('Total Students:',
                                      style: AppText.caption.copyWith(color: context.textGreyColor)),
                                  Text('${c['totalStudents'] ?? 0}',
                                      style: AppText.body.copyWith(color: context.textDarkColor)),
                                  const Spacer(),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.mintEmerald.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        (c['status'] ?? 'active').toString(),
                                        style: const TextStyle(
                                          color: AppColors.mintEmerald,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}