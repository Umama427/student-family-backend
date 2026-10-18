import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import 'child_detail_screen.dart';

class MyChildrenScreen extends StatefulWidget {
  const MyChildrenScreen({super.key});

  @override
  State<MyChildrenScreen> createState() => _MyChildrenScreenState();
}

class _MyChildrenScreenState extends State<MyChildrenScreen> {
  bool isLoading = true;
  String? errorMessage;
  List children = [];

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final data = await ApiService.getMyChildren();
      setState(() {
        children = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load children: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.mintEmerald,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Children'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        errorMessage!,
                        style: AppText.body.copyWith(color: context.textGreyColor),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadChildren,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadChildren,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${children.length} Child(ren)',
                          style: AppText.h1.copyWith(color: context.textDarkColor),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: children.isEmpty
                              ? Center(
                                  child: Text(
                                    'No children found.',
                                    style: TextStyle(color: context.textGreyColor),
                                  ),
                                )
                              : GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1.2,
                                  ),
                                  itemCount: children.length,
                                  itemBuilder: (context, index) {
                                    return _ChildCard(
                                      child: children[index],
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChildDetailScreen(
                                              child: children[index],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final Map child;
  final VoidCallback onTap;
  const _ChildCard({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = child['fullName'] ?? 'Student';
    final className = child['className'] ?? '';
    final rollNumber = child['rollNumber'] ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardWhite,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: context.cardShadow,
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.mintEmerald,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: AppText.bodyBold.copyWith(color: context.textDarkColor),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text('Class: $className', style: AppText.caption.copyWith(color: context.textMutedColor)),
            Text('Roll No: $rollNumber', style: AppText.caption.copyWith(color: context.textMutedColor)),
            const SizedBox(height: 8),
            Text(
              'View Details',
              style: GoogleFonts.inter(
                color: AppColors.mintEmerald,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}