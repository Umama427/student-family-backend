import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import 'child_detail_screen.dart';

class ParentChildrenScreen extends StatefulWidget {
  const ParentChildrenScreen({super.key});
  @override
  State<ParentChildrenScreen> createState() => _ParentChildrenScreenState();
}

class _ParentChildrenScreenState extends State<ParentChildrenScreen> {
  List<dynamic> children = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final response = await ApiService.getMyChildren();
      setState(() {
        children = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Text('Error: $error', style: TextStyle(color: context.textGreyColor)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChildren,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Children',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.textDarkColor),
            ),
            const SizedBox(height: 4),
            Text(
              '${children.length} child(ren) linked to your account',
              style: TextStyle(color: context.textGreyColor),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: children.isEmpty
                  ? Center(
                      child: Text('No children found', style: TextStyle(color: context.textGreyColor)),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.3,
                      ),
                      itemCount: children.length,
                      itemBuilder: (context, index) => _ChildCard(
                        child: children[index],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ChildDetailScreen(child: children[index])),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final dynamic child;
  final VoidCallback onTap;
  const _ChildCard({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = child['fullName'] ?? 'Unknown';
    final className = child['className'] ?? '-';
    final rollNumber = child['rollNumber'] ?? '-';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: context.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.mintEmerald.withValues(alpha: 0.15),
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.mintEmerald)),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textDarkColor),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text('Class: $className', style: TextStyle(color: context.textGreyColor, fontSize: 13)),
            Text('Roll No: $rollNumber', style: TextStyle(color: context.textGreyColor, fontSize: 13)),
            const Spacer(),
            Row(children: const [
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.mintEmerald),
              SizedBox(width: 4),
              Text('View Details', style: TextStyle(color: AppColors.mintEmerald, fontSize: 13, fontWeight: FontWeight.w600)),
            ])
          ],
        ),
      ),
    );
  }
}