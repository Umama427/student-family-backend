import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/dashboard_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/dark_mode_toggle.dart'; // ✅ NEW

// ✅ NEW imports for clickable cards & quick actions
import 'students_screen.dart';
import 'families_screen.dart';
import 'fee_challans_screen.dart';
import 'exams_screen.dart';
import 'classes_screen.dart';
import 'my_children_screen.dart';
import 'bulk_fee_challan_screen.dart';
import 'bulk_result_entry_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<String?> _userNameFuture;

  @override
  void initState() {
    super.initState();
    _userNameFuture = AuthService.getUserName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData();
    });
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _openScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1000 ? 4 : (screenWidth > 650 ? 2 : 1);

    return Container(
      decoration: BoxDecoration(gradient: context.bgGradient),
      child: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.02),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: provider.isLoading
                ? _buildShimmerLoading(crossAxisCount)
                : provider.errorMessage != null
                    ? _buildErrorState(provider)
                    : _buildContent(provider, crossAxisCount),
          );
        },
      ),
    );
  }

  Widget _buildContent(DashboardProvider provider, int crossAxisCount) {
    return RefreshIndicator(
      key: const ValueKey('content'),
      onRefresh: () => provider.fetchDashboardData(),
      color: AppColors.mintEmerald,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(provider),
            const SizedBox(height: 30),
            if (provider.role == 'admin') _buildAdminView(provider, crossAxisCount),
            if (provider.role == 'teacher') _buildTeacherView(provider),
            if (provider.role == 'parent') _buildParentView(provider),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ===================== HEADER =====================
  Widget _buildHeader(DashboardProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<String?>(
                future: _userNameFuture,
                builder: (context, snapshot) {
                  final name = snapshot.data;
                  return Text(
                    name != null && name.isNotEmpty ? '$_greeting, $name 👋' : '$_greeting! 👋',
                    style: AppText.h1.copyWith(color: context.textDarkColor),
                  );
                },
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 13, color: context.textMutedColor),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                    style: AppText.body.copyWith(color: context.textGreyColor),
                  ),
                  Text('  •  ', style: AppText.body.copyWith(color: context.textGreyColor)),
                  Text(_welcomeMessage(provider.role), style: AppText.body.copyWith(color: context.textGreyColor)),
                ],
              ),
            ],
          ),
        ),
        // ✅ NEW — Dark Mode Toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: context.cardWhite,
            borderRadius: BorderRadius.circular(30),
            boxShadow: context.cardShadow,
            border: Border.all(color: context.borderColor),
          ),
          child: const DarkModeToggle(),
        ),
        const SizedBox(width: 14),
        _headerIconButton(
          icon: Icons.refresh_rounded,
          onTap: () => provider.fetchDashboardData(),
        ),
        const SizedBox(width: 10),
        _headerIconButton(icon: Icons.notifications_none_rounded, showDot: true, onTap: () {}),
        const SizedBox(width: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: context.cardWhite,
            borderRadius: BorderRadius.circular(30),
            boxShadow: context.cardShadow,
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.mintEmerald, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                provider.role.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.textDarkColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerIconButton({required IconData icon, bool showDot = false, required VoidCallback onTap}) {
    return Material(
      color: context.cardWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: context.cardShadow,
            border: Border.all(color: context.borderColor),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 20, color: context.textDarkColor),
              if (showDot)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.overdueCrimson,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.cardWhite, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _welcomeMessage(String role) {
    switch (role) {
      case 'teacher':
        return 'Here is your class summary';
      case 'parent':
        return 'Here is your children\'s summary';
      default:
        return 'Here is your real-time system summary';
    }
  }

  // ===================== CLICKABLE STAT CARD WRAPPER =====================
  Widget _tappable({required Widget child, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: child,
    );
  }

  // ===================== QUICK ACTION BUTTON =====================
  Widget _quickActionButton({required String label, required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: AppColors.mintEmerald,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 10),
              Text(label, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== ADMIN VIEW =====================
  Widget _buildAdminView(DashboardProvider provider, int crossAxisCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          childAspectRatio: 1.5,
          children: [
            _tappable(
              onTap: () => _openScreen(const StudentsScreen()),
              child: StatCard(
                title: 'Total Students',
                value: provider.totalStudents.toString(),
                numericValue: provider.totalStudents.toDouble(),
                icon: Icons.school_rounded,
                gradient: AppColors.navyGradient,
                caption: 'Across all classes',
              ),
            ),
            _tappable(
              onTap: () => _openScreen(const FamiliesScreen()),
              child: StatCard(
                title: 'Total Families',
                value: provider.totalFamilies.toString(),
                numericValue: provider.totalFamilies.toDouble(),
                icon: Icons.family_restroom_rounded,
                gradient: AppColors.mintGradient,
                caption: 'Registered accounts',
              ),
            ),
            _tappable(
              onTap: () => _openScreen(const FeeChallansScreen()),
              child: StatCard(
                title: 'Revenue Collected',
                value: 'Rs. ${provider.totalRevenueCollected.toStringAsFixed(0)}',
                numericValue: provider.totalRevenueCollected,
                prefix: 'Rs. ',
                icon: Icons.account_balance_wallet_rounded,
                gradient: AppColors.goldGradient,
                caption: 'This month',
              ),
            ),
            _tappable(
              onTap: () => _openScreen(const FeeChallansScreen()),
              child: StatCard(
                title: 'Pending Amount',
                value: 'Rs. ${provider.totalPendingAmount.toStringAsFixed(0)}',
                numericValue: provider.totalPendingAmount,
                prefix: 'Rs. ',
                icon: Icons.pending_actions_rounded,
                gradient: AppColors.coralGradient,
                caption: 'Needs attention',
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _cardWrapper(
          title: 'Quick Actions',
          subtitle: 'Common admin tasks',
          headerIcon: Icons.bolt_rounded,
          headerColor: AppColors.accentGold,
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _quickActionButton(
                label: 'Bulk Fee Challans',
                icon: Icons.receipt_long_rounded,
                onTap: () => _openScreen(const BulkFeeChallanScreen()),
              ),
              _quickActionButton(
                label: 'Bulk Result Entry',
                icon: Icons.table_chart_rounded,
                onTap: () => _openScreen(const BulkResultEntryScreen()),
              ),
              _quickActionButton(
                label: 'Manage Classes',
                icon: Icons.class_rounded,
                onTap: () => _openScreen(const ClassesScreen()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            final pieChartCard = _buildPieChartCard(provider);
            final lineChartCard = _buildRevenueTrendCard(provider);

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: pieChartCard),
                  const SizedBox(width: 20),
                  Expanded(flex: 3, child: lineChartCard),
                ],
              );
            }
            return Column(children: [pieChartCard, const SizedBox(height: 20), lineChartCard]);
          },
        ),
      ],
    );
  }

  // ===================== TEACHER VIEW =====================
  Widget _buildTeacherView(DashboardProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          childAspectRatio: 1.6,
          children: [
            _tappable(
              onTap: () => _openScreen(const StudentsScreen()),
              child: StatCard(
                title: 'My Students',
                value: provider.totalStudents.toString(),
                numericValue: provider.totalStudents.toDouble(),
                icon: Icons.school_rounded,
                gradient: AppColors.navyGradient,
                caption: 'In your classes',
              ),
            ),
            _tappable(
              onTap: () => _openScreen(const ExamsScreen()),
              child: StatCard(
                title: 'Assigned Classes',
                value: provider.assignedClasses.length.toString(),
                numericValue: provider.assignedClasses.length.toDouble(),
                icon: Icons.class_rounded,
                gradient: AppColors.mintGradient,
                caption: 'Active this term',
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _cardWrapper(
          title: 'Quick Actions',
          subtitle: 'Common teacher tasks',
          headerIcon: Icons.bolt_rounded,
          headerColor: AppColors.accentGold,
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _quickActionButton(
                label: 'Bulk Result Entry',
                icon: Icons.table_chart_rounded,
                onTap: () => _openScreen(const BulkResultEntryScreen()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _cardWrapper(
          title: 'Class-wise Breakdown',
          subtitle: 'Students per assigned class',
          headerIcon: Icons.bar_chart_rounded,
          headerColor: AppColors.sky,
          child: provider.classWiseBreakdown.isEmpty
              ? _emptyState('No classes assigned yet', Icons.class_outlined)
              : Column(
                  children: provider.classWiseBreakdown.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key, style: AppText.bodyBold.copyWith(color: context.textDarkColor)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.mintEmerald.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('${e.value} students',
                                style: GoogleFonts.inter(
                                    color: AppColors.mintEmerald, fontWeight: FontWeight.w700, fontSize: 12.5)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  // ===================== PARENT VIEW =====================
  Widget _buildParentView(DashboardProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          childAspectRatio: 1.4,
          children: [
            _tappable(
              onTap: () => _openScreen(const MyChildrenScreen()),
              child: StatCard(
                title: 'My Children',
                value: provider.children.length.toString(),
                numericValue: provider.children.length.toDouble(),
                icon: Icons.family_restroom_rounded,
                gradient: AppColors.navyGradient,
                caption: 'Enrolled',
              ),
            ),
            _tappable(
              onTap: () => _openScreen(const FeeChallansScreen()),
              child: StatCard(
                title: 'Amount Paid',
                value: 'Rs. ${provider.totalRevenueCollected.toStringAsFixed(0)}',
                numericValue: provider.totalRevenueCollected,
                prefix: 'Rs. ',
                icon: Icons.check_circle_rounded,
                gradient: AppColors.mintGradient,
                caption: 'All time',
              ),
            ),
            _tappable(
              onTap: () => _openScreen(const FeeChallansScreen()),
              child: StatCard(
                title: 'Pending Dues',
                value: 'Rs. ${provider.totalPendingAmount.toStringAsFixed(0)}',
                numericValue: provider.totalPendingAmount,
                prefix: 'Rs. ',
                icon: Icons.pending_actions_rounded,
                gradient: AppColors.coralGradient,
                caption: 'To be paid',
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _cardWrapper(
          title: 'My Children',
          subtitle: '${provider.children.length} enrolled',
          headerIcon: Icons.family_restroom_rounded,
          headerColor: AppColors.purple,
          child: provider.children.isEmpty
              ? _emptyState('No children found', Icons.family_restroom_outlined)
              : Column(
                  children: provider.children.map((c) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.bgLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: AppColors.mintGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.person_rounded, size: 18, color: Colors.white),
                          ),
                          const SizedBox(width: 14),
                          Text(c['name'] ?? '', style: AppText.bodyBold.copyWith(color: context.textDarkColor)),
                          const SizedBox(width: 10),
                          Text('(${c['className'] ?? ''})', style: AppText.caption.copyWith(color: context.textMutedColor)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
          footer: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _openScreen(const MyChildrenScreen()),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('View Full Details & Report Cards'),
            ),
          ),
        ),
      ],
    );
  }

  // ===================== PIE CHART (With % bars) =====================
  Widget _buildPieChartCard(DashboardProvider provider) {
    final paid = provider.paidCount;
    final pending = provider.pendingCount;
    final overdue = provider.overdueCount;
    final total = paid + pending + overdue;

    return _cardWrapper(
      title: 'Fee Collection Status',
      subtitle: 'Current month breakdown',
      headerIcon: Icons.pie_chart_rounded,
      headerColor: AppColors.accentGold,
      child: total == 0
          ? _emptyState('No fee data available', Icons.pie_chart_outline_rounded)
          : SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 50,
                      sections: [
                        PieChartSectionData(value: paid.toDouble(), color: AppColors.paidGreen, title: '', radius: 38),
                        PieChartSectionData(value: pending.toDouble(), color: AppColors.pendingAmber, title: '', radius: 38),
                        PieChartSectionData(value: overdue.toDouble(), color: AppColors.overdueCrimson, title: '', radius: 38),
                      ],
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 700),
                    swapAnimationCurve: Curves.easeOutCubic,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedCounterText(value: total.toDouble()),
                      Text('Total Challans', style: AppText.caption.copyWith(color: context.textMutedColor)),
                    ],
                  ),
                ],
              ),
            ),
      footer: total == 0
          ? null
          : Column(
              children: [
                _statusBar('Paid', paid, total, AppColors.paidGreen),
                const SizedBox(height: 10),
                _statusBar('Pending', pending, total, AppColors.pendingAmber),
                const SizedBox(height: 10),
                _statusBar('Overdue', overdue, total, AppColors.overdueCrimson),
              ],
            ),
    );
  }

  Widget _statusBar(String label, int count, int total, Color color) {
    final pct = total == 0 ? 0.0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(label, style: AppText.bodyBold.copyWith(fontSize: 13, color: context.textDarkColor)),
              ],
            ),
            Text('$count  •  ${(pct * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.inter(fontSize: 12, color: context.textGreyColor, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              return LinearProgressIndicator(
                value: val,
                minHeight: 7,
                backgroundColor: context.borderColor,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              );
            },
          ),
        ),
      ],
    );
  }

  // ===================== REVENUE TREND =====================
  Widget _buildRevenueTrendCard(DashboardProvider provider) {
    final totalRevenue = provider.revenueTrend.fold<double>(
      0,
      (sum, e) => sum + ((e['amount'] ?? 0) as num).toDouble(),
    );

    return _cardWrapper(
      title: 'Revenue Trend',
      subtitle: 'Monthly collection overview',
      headerIcon: Icons.show_chart_rounded,
      headerColor: AppColors.mintEmerald,
      trailing: provider.revenueTrend.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.mintEmerald.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Total: Rs. ${NumberFormat('#,##0').format(totalRevenue)}',
                style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.mintEmerald),
              ),
            ),
      child: SizedBox(
        height: 220,
        child: provider.revenueTrend.isEmpty
            ? _emptyState('No revenue data yet', Icons.show_chart_rounded)
            : provider.revenueTrend.length == 1
                ? _barStyleSingle(provider.revenueTrend.first)
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1000,
                        getDrawingHorizontalLine: (value) =>
                            FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
                      ),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) => AppColors.deepNavy,
                          tooltipRoundedRadius: 10,
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: provider.revenueTrend
                              .asMap()
                              .entries
                              .map((e) => FlSpot(
                                    e.key.toDouble(),
                                    ((e.value['amount'] ?? 0) as num).toDouble(),
                                  ))
                              .toList(),
                          isCurved: true,
                          gradient: AppColors.mintGradient,
                          barWidth: 4,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                              radius: 4,
                              color: Colors.white,
                              strokeWidth: 3,
                              strokeColor: AppColors.mintEmerald,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.mintEmerald.withOpacity(0.25),
                                AppColors.mintEmerald.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 700),
                  ),
      ),
    );
  }

  Widget _barStyleSingle(Map<String, dynamic> data) {
    final monthStr = data['month']?.toString() ?? '10';
    final yearStr = data['year']?.toString() ?? '2026';
    final amountVal = (data['amount'] ?? 0).toString();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.mintGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.colored(AppColors.mintEmerald),
            ),
          ),
          const SizedBox(height: 14),
          Text('Month $monthStr/$yearStr', style: AppText.bodyBold.copyWith(color: context.textDarkColor)),
          Text('Rs. $amountVal', style: AppText.caption.copyWith(color: context.textMutedColor)),
          const SizedBox(height: 4),
          Text(
            '(Line graph will appear once more months of data are available)',
            style: AppText.caption.copyWith(color: context.textMutedColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String message, IconData icon) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: context.textMutedColor.withOpacity(0.5)),
            const SizedBox(height: 10),
            Text(message, style: AppText.body.copyWith(color: context.textGreyColor)),
          ],
        ),
      ),
    );
  }

  // ===================== CARD WRAPPER (With Icon Badge) =====================
  Widget _cardWrapper({
    required String title,
    required String subtitle,
    required Widget child,
    Widget? footer,
    Widget? trailing,
    IconData? headerIcon,
    Color? headerColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardWhite,
        borderRadius: BorderRadius.circular(22),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (headerIcon != null) ...[
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: (headerColor ?? AppColors.mintEmerald).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(headerIcon, size: 17, color: headerColor ?? AppColors.mintEmerald),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.h3.copyWith(color: context.textDarkColor)),
                    Text(subtitle, style: AppText.caption.copyWith(color: context.textMutedColor)),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 18),
          child,
          if (footer != null) ...[const SizedBox(height: 18), footer],
        ],
      ),
    );
  }

  // ===================== SHIMMER LOADING =====================
  Widget _buildShimmerLoading(int crossAxisCount) {
    return SingleChildScrollView(
      key: const ValueKey('shimmer'),
      padding: const EdgeInsets.all(28),
      physics: const NeverScrollableScrollPhysics(),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 260, height: 28, decoration: _shimmerBox()),
            const SizedBox(height: 10),
            Container(width: 180, height: 14, decoration: _shimmerBox()),
            const SizedBox(height: 30),
            GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              childAspectRatio: 1.5,
              children: List.generate(4, (i) => Container(decoration: _shimmerBox(radius: 22))),
            ),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: Container(height: 280, decoration: _shimmerBox(radius: 22))),
                const SizedBox(width: 20),
                Expanded(flex: 3, child: Container(height: 280, decoration: _shimmerBox(radius: 22))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _shimmerBox({double radius = 8}) {
    return BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(radius));
  }

  Widget _buildErrorState(DashboardProvider provider) {
    return Center(
      key: const ValueKey('error'),
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: context.cardWhite,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: context.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.overdueCrimson.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.overdueCrimson),
            ),
            const SizedBox(height: 16),
            Text('Something went wrong', style: AppText.h3.copyWith(color: context.textDarkColor)),
            const SizedBox(height: 6),
            Text(provider.errorMessage ?? '', textAlign: TextAlign.center, style: AppText.body.copyWith(color: context.textGreyColor)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => provider.fetchDashboardData(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mintEmerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Small helper for animated total count in pie chart center
class AnimatedCounterText extends StatelessWidget {
  final double value;
  const AnimatedCounterText({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return Text(
          val.round().toString(),
          style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: context.textDarkColor),
        );
      },
    );
  }
}