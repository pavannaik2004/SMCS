import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/analytics_model.dart';

class ComplaintsChart extends StatelessWidget {
	final List<DepartmentStat> departments;
	final List<CategoryStat> categories;

	const ComplaintsChart({
		super.key,
		required this.departments,
		required this.categories,
	});

	@override
	Widget build(BuildContext context) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				_buildSectionTitle('Complaints by Department'),
				const SizedBox(height: 8),
				_buildDepartmentChart(),
				const SizedBox(height: 24),
				_buildSectionTitle('Category Breakdown'),
				const SizedBox(height: 8),
				_buildCategoryChart(),
			],
		);
	}

	Widget _buildSectionTitle(String label) {
		return Text(label, style: AppTextStyles.titleMedium);
	}

	Widget _buildDepartmentChart() {
		if (departments.isEmpty) {
			return _emptyChart('No department data available');
		}

		final maxValue = departments
				.map((d) => d.totalCount)
				.fold<int>(0, (p, c) => c > p ? c : p)
				.toDouble();

		return Card(
			child: Padding(
				padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
				child: SizedBox(
					height: 220,
					child: BarChart(
						BarChartData(
							alignment: BarChartAlignment.spaceAround,
							maxY: maxValue == 0 ? 5 : maxValue + 2,
							barTouchData: BarTouchData(
								enabled: true,
								touchTooltipData: BarTouchTooltipData(
									getTooltipItem: (group, groupIndex, rod, rodIndex) {
										final label = departments[group.x.toInt()].departmentName;
										return BarTooltipItem(
											'$label\n${rod.toY.toInt()} complaints',
											AppTextStyles.bodySmall.copyWith(color: Colors.white),
										);
									},
								),
							),
							titlesData: FlTitlesData(
								topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
								rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
								leftTitles: AxisTitles(
									sideTitles: SideTitles(
										showTitles: true,
										reservedSize: 32,
										interval: maxValue <= 6 ? 1 : (maxValue / 3).ceilToDouble(),
									),
								),
								bottomTitles: AxisTitles(
									sideTitles: SideTitles(
										showTitles: true,
										getTitlesWidget: (value, meta) {
											final index = value.toInt();
											if (index < 0 || index >= departments.length) {
												return const SizedBox.shrink();
											}
											final name = departments[index].departmentName;
											final label = name.length <= 3 ? name : name.substring(0, 3).toUpperCase();
											return Padding(
												padding: const EdgeInsets.only(top: 8),
												child: Text(label, style: AppTextStyles.labelSmall),
											);
										},
									),
								),
							),
							gridData: FlGridData(
								show: true,
								drawVerticalLine: false,
								horizontalInterval: maxValue <= 6 ? 1 : (maxValue / 3).ceilToDouble(),
								getDrawingHorizontalLine: (value) => FlLine(
									color: AppColors.border,
									strokeWidth: 1,
								),
							),
							borderData: FlBorderData(show: false),
							barGroups: List.generate(departments.length, (index) {
								final count = departments[index].totalCount.toDouble();
								return BarChartGroupData(
									x: index,
									barRods: [
										BarChartRodData(
											toY: count,
											color: AppColors.primary,
											width: 18,
											borderRadius: BorderRadius.circular(6),
											backDrawRodData: BackgroundBarChartRodData(
												show: true,
												toY: maxValue == 0 ? 5 : maxValue + 2,
												color: AppColors.surfaceVariant,
											),
										),
									],
								);
							}),
						),
					),
				),
			),
		);
	}

	Widget _buildCategoryChart() {
		if (categories.isEmpty) {
			return _emptyChart('No category data available');
		}

		final colors = [
			AppColors.primary,
			AppColors.accent,
			AppColors.severityHigh,
			AppColors.severityMedium,
			AppColors.severityLow,
			AppColors.statusAssigned,
			AppColors.statusInProgress,
			AppColors.statusResolved,
		];

		return Card(
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					children: [
						SizedBox(
							height: 200,
							child: PieChart(
								PieChartData(
									centerSpaceRadius: 50,
									sectionsSpace: 2,
									sections: List.generate(categories.length, (index) {
										final stat = categories[index];
										final color = colors[index % colors.length];
										return PieChartSectionData(
											color: color,
											value: stat.count.toDouble(),
											title: '${stat.count}',
											radius: 48,
											titleStyle: AppTextStyles.labelSmall.copyWith(color: Colors.white),
										);
									}),
								),
							),
						),
						const SizedBox(height: 12),
						Wrap(
							spacing: 12,
							runSpacing: 8,
							children: List.generate(categories.length, (index) {
								final stat = categories[index];
								final color = colors[index % colors.length];
								return Row(
									mainAxisSize: MainAxisSize.min,
									children: [
										Container(
											width: 10,
											height: 10,
											decoration: BoxDecoration(color: color, shape: BoxShape.circle),
										),
										const SizedBox(width: 6),
										Text(stat.categoryName, style: AppTextStyles.labelSmall),
									],
								);
							}),
						),
					],
				),
			),
		);
	}

	Widget _emptyChart(String message) {
		return Card(
			child: Padding(
				padding: const EdgeInsets.all(24),
				child: Center(
					child: Text(
						message,
						style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
					),
				),
			),
		);
	}
}
