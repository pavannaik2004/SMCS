import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/analytics_model.dart';
import '../../bloc/analytics/analytics_cubit.dart';
import '../../bloc/analytics/analytics_state.dart';
import '../../widgets/analytics/complaints_chart.dart';
import '../../widgets/analytics/stats_card.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/complaint/complaint_card.dart';

class AdminDashboardPage extends StatefulWidget {
	const AdminDashboardPage({super.key});

	@override
	State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
	@override
	void initState() {
		super.initState();
		context.read<AnalyticsCubit>().loadSummary();
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: BlocBuilder<AnalyticsCubit, AnalyticsState>(
				builder: (context, state) {
					if (state is AnalyticsLoading) {
						return const Center(child: CircularProgressIndicator());
					}
					if (state is AnalyticsError) {
						return ScmsErrorWidget(
							message: state.message,
							onRetry: () => context.read<AnalyticsCubit>().loadSummary(),
						);
					}
					if (state is AnalyticsEmpty) {
						return const EmptyStateWidget(
							title: 'No analytics available',
							subtitle: 'Data will appear after complaints are processed.',
							icon: Icons.insights_rounded,
						);
					}
					if (state is! AnalyticsLoaded) return const SizedBox.shrink();

					final analytics = state.analytics;
					return CustomScrollView(
						slivers: [
							SliverAppBar(
								pinned: true,
								expandedHeight: 120,
								flexibleSpace: FlexibleSpaceBar(
									title: const Text('Admin Dashboard'),
									background: Container(
										decoration: const BoxDecoration(
											gradient: LinearGradient(
												colors: [AppColors.primary, AppColors.primaryDark],
												begin: Alignment.topLeft,
												end: Alignment.bottomRight,
											),
										),
									),
								),
							),
							SliverToBoxAdapter(
								child: Padding(
									padding: const EdgeInsets.all(16),
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											_buildKpiRow(analytics),
											const SizedBox(height: 24),
											ComplaintsChart(
												departments: analytics.byDepartment,
												categories: analytics.byCategory,
											),
											const SizedBox(height: 24),
											Text('Recent SLA Breaches', style: AppTextStyles.titleMedium),
											const SizedBox(height: 12),
											if (analytics.recentSlaBreaches.isEmpty)
												Text(
													'No breaches in the last 7 days.',
													style: AppTextStyles.bodySmall.copyWith(
														color: AppColors.textSecondary,
													),
												)
											else
												ListView.builder(
													shrinkWrap: true,
													physics: const NeverScrollableScrollPhysics(),
													itemCount: analytics.recentSlaBreaches.length,
													itemBuilder: (context, index) {
														return ComplaintCard(
															complaint: analytics.recentSlaBreaches[index],
														);
													},
												),
										],
									),
								),
							),
						],
					);
				},
			),
		);
	}

	Widget _buildKpiRow(AnalyticsModel analytics) {
		return SizedBox(
			height: 140,
			child: ListView(
				scrollDirection: Axis.horizontal,
				children: [
					StatsCard(
						title: 'Total Active',
						value: '${analytics.totalActiveComplaints}',
						subtitle: 'Open + In Progress',
						icon: Icons.inbox_rounded,
						accentColor: AppColors.primary,
					),
					StatsCard(
						title: 'SLA Breaches (7d)',
						value: '${analytics.slaBreachesLast7Days}',
						subtitle: 'Needs attention',
						icon: Icons.warning_amber_rounded,
						accentColor: AppColors.severityHigh,
					),
					StatsCard(
						title: 'Avg Resolution',
						value: analytics.avgResolutionTimeHours.toHoursDuration(),
						subtitle: 'Across all depts',
						icon: Icons.timer_rounded,
						accentColor: AppColors.severityMedium,
					),
					StatsCard(
						title: 'Resolution Rate',
						value: analytics.resolutionRatePercent.toPercentString(),
						subtitle: 'Last 30 days',
						icon: Icons.trending_up_rounded,
						accentColor: AppColors.accent,
					),
				],
			),
		);
	}
}
