import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/admin_routes.dart';
import '../../../shared/theme/admin_theme.dart';
import '../../../shared/widgets/admin_shell.dart';
import '../providers/finance_providers.dart';

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(financeStatsProvider);
    return AdminShell(
      section: AdminSection.finance,
      title: 'Finance & Tax',
      subtitle: 'GST ${stats.gstRatePct}% on approved revenue',
      actions: [
        OutlinedButton.icon(
          onPressed: () => _copyCsv(context, stats),
          icon: const Icon(Icons.content_copy_rounded, size: 18),
          label: const Text('Copy CSV'),
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AdminSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MetricGrid(stats: stats),
            const SizedBox(height: AdminSpacing.xxl),
            _MonthlyTable(stats: stats),
            const SizedBox(height: AdminSpacing.lg),
            Text(
              'Revenue includes the 18% GST. Taxable = Gross ÷ 1.18; '
              'GST = Gross − Taxable. Only bookings that reached Live or '
              'Completed status are counted (excludes cancelled, rejected, '
              'and awaiting-approval).',
              style: AdminText.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _copyCsv(BuildContext context, FinanceStats stats) {
    final buf = StringBuffer('Month,Bookings,Gross,Taxable,GST 18%\n');
    for (final b in stats.last12Months) {
      buf.writeln(
        '${DateFormat('MMM y').format(b.month)},'
        '${b.count},${b.gross},${b.taxable},${b.gst}',
      );
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV copied to clipboard.')),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.stats});
  final FinanceStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      final isWide = c.maxWidth > 900;
      final cards = [
        _MetricCard(
          label: 'GST · THIS MONTH',
          value: '₹${_fmt(stats.thisMonth.gst)}',
          subtitle:
              '${stats.thisMonth.count} bookings · ₹${_fmt(stats.thisMonth.gross)} gross',
          iconBg: AdminColors.primarySurface,
          iconFg: AdminColors.primary,
          icon: Icons.receipt_long_outlined,
        ),
        _MetricCard(
          label: 'GST · LAST MONTH',
          value: '₹${_fmt(stats.lastMonth.gst)}',
          subtitle:
              '${stats.lastMonth.count} bookings · ₹${_fmt(stats.lastMonth.gross)} gross',
          iconBg: AdminColors.infoBg,
          iconFg: AdminColors.info,
          icon: Icons.history_rounded,
        ),
        _MetricCard(
          label: 'GST · THIS QUARTER',
          value: '₹${_fmt(stats.thisQuarter.gst)}',
          subtitle:
              '${stats.thisQuarter.count} bookings · ₹${_fmt(stats.thisQuarter.gross)} gross',
          iconBg: AdminColors.warningBg,
          iconFg: AdminColors.warning,
          icon: Icons.calendar_view_month_rounded,
        ),
        _MetricCard(
          label: 'GST · FY-TO-DATE',
          value: '₹${_fmt(stats.thisYear.gst)}',
          subtitle:
              '${stats.thisYear.count} bookings · ₹${_fmt(stats.thisYear.gross)} gross',
          iconBg: AdminColors.successBg,
          iconFg: AdminColors.success,
          icon: Icons.account_balance_outlined,
        ),
      ];
      return GridView.count(
        crossAxisCount: isWide ? 4 : 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AdminSpacing.md,
        crossAxisSpacing: AdminSpacing.md,
        childAspectRatio: isWide ? 2.0 : 1.6,
        children: cards,
      );
    });
  }

  static String _fmt(int n) =>
      NumberFormat.decimalPattern('en_IN').format(n);
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.iconBg,
    required this.iconFg,
    required this.icon,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color iconBg;
  final Color iconFg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: BoxDecoration(
        color: AdminColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconFg, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: AdminText.caps.copyWith(fontSize: 10)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AdminText.metricValue.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AdminText.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyTable extends StatelessWidget {
  const _MonthlyTable({required this.stats});
  final FinanceStats stats;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern('en_IN');
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AdminSpacing.xl,
              AdminSpacing.xl,
              AdminSpacing.xl,
              AdminSpacing.md,
            ),
            child: Row(
              children: [
                Text('Monthly breakdown · last 12 months',
                    style: AdminText.h1.copyWith(fontSize: 18)),
                const Spacer(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AdminSpacing.xl,
              vertical: AdminSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AdminColors.appBg,
              border: Border(
                top: BorderSide(color: AdminColors.border),
                bottom: BorderSide(color: AdminColors.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('MONTH', style: AdminText.caps)),
                Expanded(
                  flex: 2,
                  child: Text('BOOKINGS', style: AdminText.caps),
                ),
                Expanded(
                  flex: 3,
                  child: Text('GROSS', style: AdminText.caps),
                ),
                Expanded(
                  flex: 3,
                  child: Text('TAXABLE', style: AdminText.caps),
                ),
                Expanded(
                  flex: 3,
                  child: Text('GST 18%', style: AdminText.caps),
                ),
              ],
            ),
          ),
          for (final b in stats.last12Months)
            _Row(
              month: DateFormat('MMM y').format(b.month),
              count: b.count,
              gross: '₹${fmt.format(b.gross)}',
              taxable: '₹${fmt.format(b.taxable)}',
              gst: '₹${fmt.format(b.gst)}',
              isEmpty: b.count == 0,
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.month,
    required this.count,
    required this.gross,
    required this.taxable,
    required this.gst,
    required this.isEmpty,
  });

  final String month;
  final int count;
  final String gross;
  final String taxable;
  final String gst;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final muted = isEmpty;
    final TextStyle valueStyle = AdminText.label.copyWith(
      color: muted ? AdminColors.textMuted : AdminColors.textPrimary,
      fontWeight: muted ? FontWeight.w500 : FontWeight.w600,
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.xl,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AdminColors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(month, style: valueStyle)),
          Expanded(
            flex: 2,
            child: Text('$count', style: valueStyle),
          ),
          Expanded(flex: 3, child: Text(gross, style: valueStyle)),
          Expanded(flex: 3, child: Text(taxable, style: valueStyle)),
          Expanded(
            flex: 3,
            child: Text(
              gst,
              style: valueStyle.copyWith(
                color: muted ? AdminColors.textMuted : AdminColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
