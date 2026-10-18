import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/family_provider.dart';
import '../providers/student_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/add_family_dialog.dart';
import '../widgets/sibling_tree_view.dart';
import '../widgets/set_family_pin_dialog.dart';

class FamiliesScreen extends StatefulWidget {
  const FamiliesScreen({super.key});

  @override
  State<FamiliesScreen> createState() => _FamiliesScreenState();
}

class _FamiliesScreenState extends State<FamiliesScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FamilyProvider>(context, listen: false).fetchFamilies();
      Provider.of<StudentProvider>(context, listen: false).fetchStudents();
    });
  }

  void _openAddFamilyDialog() {
    showDialog(
      context: context,
      builder: (_) => const AddFamilyDialog(),
    );
  }

  void _openSiblingTree(familyModel) {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final students = studentProvider.getStudentsByFamily(familyModel.id);

    showDialog(
      context: context,
      builder: (_) => SiblingTreeView(family: familyModel, students: students),
    );
  }

  void _openSetPinDialog(familyModel) {
    showDialog(
      context: context,
      builder: (_) => SetFamilyPinDialog(familyId: familyModel.id, familyName: familyModel.familyName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<FamilyProvider, StudentProvider>(
      builder: (context, familyProvider, studentProvider, child) {
        final filteredFamilies = familyProvider.families.where((f) {
          return f.familyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              f.fatherName.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

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
                        Text(
                          'Families',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: context.textDarkColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${familyProvider.families.length} families registered',
                          style: TextStyle(color: context.textGreyColor, fontSize: 14),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _openAddFamilyDialog,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Add Family'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
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
                      hintText: 'Search by family name or father name...',
                      hintStyle: TextStyle(color: context.textMutedColor, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: context.textGreyColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: context.cardWhite,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: familyProvider.isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.mintEmerald))
                      : filteredFamilies.isEmpty
                          ? _buildEmptyState(context)
                          : RefreshIndicator(
                              onRefresh: () => familyProvider.fetchFamilies(),
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 18,
                                  mainAxisSpacing: 18,
                                  mainAxisExtent: 210,
                                ),
                                itemCount: filteredFamilies.length,
                                itemBuilder: (context, index) {
                                  final family = filteredFamilies[index];
                                  final siblingCount =
                                      studentProvider.getStudentsByFamily(family.id).length;

                                  return _FamilyCard(
                                    familyName: family.familyName,
                                    familyCode: family.familyCode,
                                    fatherName: family.fatherName,
                                    phone: family.primaryPhone,
                                    siblingCount: siblingCount,
                                    onTap: () => _openSiblingTree(family),
                                    onSetPin: () => _openSetPinDialog(family),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.family_restroom_rounded, size: 70, color: context.textGreyColor.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No families found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.textDarkColor),
          ),
          const SizedBox(height: 6),
          Text('Click "Add Family" to create a new family record',
              style: TextStyle(color: context.textGreyColor)),
        ],
      ),
    );
  }
}

// ===== Family Card Widget =====
class _FamilyCard extends StatelessWidget {
  final String familyName;
  final String familyCode;
  final String fatherName;
  final String phone;
  final int siblingCount;
  final VoidCallback onTap;
  final VoidCallback onSetPin;

  const _FamilyCard({
    required this.familyName,
    required this.familyCode,
    required this.fatherName,
    required this.phone,
    required this.siblingCount,
    required this.onTap,
    required this.onSetPin,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cardWhite,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: context.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.mintGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: onSetPin,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.pin_outlined, size: 16, color: AppColors.accentGold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? AppColors.deepNavy.withValues(alpha: 0.3)
                              : AppColors.deepNavy.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          familyCode,
                          style: TextStyle(
                              fontSize: 10.5,
                              color: context.isDarkMode ? Colors.white : AppColors.deepNavy,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                familyName,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textDarkColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                fatherName,
                style: TextStyle(fontSize: 13, color: context.textGreyColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.phone_rounded, size: 12, color: context.textGreyColor),
                  const SizedBox(width: 4),
                  Text(phone, style: TextStyle(fontSize: 12, color: context.textGreyColor)),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.groups_2_rounded, size: 16, color: AppColors.mintEmerald),
                  const SizedBox(width: 6),
                  Text(
                    '$siblingCount student${siblingCount == 1 ? '' : 's'} linked',
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.mintEmerald, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: context.textGreyColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}