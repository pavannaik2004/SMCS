import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/network_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/datasources/local/complaint_local_datasource.dart';
import '../../../data/datasources/remote/complaint_remote_datasource.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../../domain/usecases/update_complaint_status_usecase.dart';
import '../../bloc/complaint/complaint_bloc.dart';
import '../../bloc/complaint/complaint_event.dart';
import '../../bloc/complaint/complaint_state.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/scms_button.dart';
import '../../widgets/common/scms_chip.dart';
import '../../widgets/complaint/complaint_card.dart';

class StaffDashboardPage extends StatefulWidget {
	const StaffDashboardPage({super.key});

	@override
	State<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends State<StaffDashboardPage> {
	final _filters = const ['All', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED_TODAY'];
	String _activeFilter = 'All';
	late final UpdateComplaintStatusUseCase _updateStatusUseCase;

	@override
	void initState() {
		super.initState();
		_updateStatusUseCase = UpdateComplaintStatusUseCase(
			repository: ComplaintRepository(
				remoteDataSource: ComplaintRemoteDataSource(dioClient: DioClient()),
				localDataSource: ComplaintLocalDataSource(),
				networkInfo: NetworkInfo(),
			),
		);
		context.read<ComplaintBloc>().add(LoadMyComplaints());
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('My Tasks'),
				actions: [
					Container(
						margin: const EdgeInsets.only(right: 16),
						padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
						decoration: BoxDecoration(
							color: AppColors.surfaceVariant,
							borderRadius: BorderRadius.circular(12),
						),
						child: Text('STAFF', style: AppTextStyles.labelSmall),
					),
				],
			),
			body: Column(
				children: [
					SizedBox(
						height: 48,
						child: ListView.separated(
							scrollDirection: Axis.horizontal,
							padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
							itemCount: _filters.length,
							separatorBuilder: (_, __) => const SizedBox(width: 8),
							itemBuilder: (_, i) {
								final filter = _filters[i];
								final label = filter == 'RESOLVED_TODAY'
										? 'Resolved Today'
										: filter == 'All'
												? 'All'
												: filter.replaceAll('_', ' ');
								return ScmsChip(
									label: label,
									isSelected: filter == _activeFilter,
									onTap: () {
										setState(() => _activeFilter = filter);
										final statusFilter = _activeFilter == 'All'
												? null
												: _activeFilter == 'RESOLVED_TODAY'
														? 'RESOLVED'
														: _activeFilter;
										context.read<ComplaintBloc>().add(
													LoadMyComplaints(statusFilter: statusFilter),
												);
									},
								);
							},
						),
					),
					Expanded(
						child: BlocBuilder<ComplaintBloc, ComplaintState>(
							builder: (context, state) {
								if (state is ComplaintLoading) {
									return const Center(child: CircularProgressIndicator());
								}
								if (state is ComplaintError) {
									return ScmsErrorWidget(
										message: state.message,
										onRetry: () => context.read<ComplaintBloc>().add(RefreshComplaints()),
									);
								}
								if (state is MyComplaintsLoaded) {
									final filtered = _filterComplaints(state.complaints);
									if (filtered.isEmpty) {
										return const EmptyStateWidget(
											title: 'No tasks found',
											subtitle: 'You are all caught up for now.',
											icon: Icons.task_alt_rounded,
										);
									}

									final stats = _buildStats(state.complaints);

									return RefreshIndicator(
										onRefresh: () async =>
												context.read<ComplaintBloc>().add(RefreshComplaints()),
										child: ListView(
											padding: const EdgeInsets.only(bottom: 24),
											children: [
												Padding(
													padding: const EdgeInsets.all(16),
													child: Row(
														children: [
															_statTile('Assigned', stats.assigned),
															const SizedBox(width: 12),
															_statTile('In Progress', stats.inProgress),
															const SizedBox(width: 12),
															_statTile('Completed Today', stats.resolvedToday),
														],
													),
												),
												...filtered.map((complaint) => Column(
															children: [
																ComplaintCard(
																	complaint: complaint,
																	onTap: () => context.push(
																		'/staff/complaint/${complaint.id}',
																	),
																),
																if (complaint.status == 'ASSIGNED')
																	Padding(
																		padding: const EdgeInsets.symmetric(horizontal: 16),
																		child: ScmsButton(
																			label: 'Start Working',
																			variant: ScmsButtonVariant.secondary,
																			isFullWidth: true,
																			onPressed: () => _startWorking(complaint),
																		),
																	),
																const SizedBox(height: 16),
															],
														)),
											],
										),
									);
								}
								return const SizedBox.shrink();
							},
						),
					),
				],
			),
		);
	}

	List<ComplaintModel> _filterComplaints(List<ComplaintModel> complaints) {
		if (_activeFilter == 'All') return complaints;
		if (_activeFilter == 'RESOLVED_TODAY') {
			return complaints
					.where((c) => c.status == 'RESOLVED' && c.updatedAt.isToday)
					.toList();
		}
		return complaints.where((c) => c.status == _activeFilter).toList();
	}

	_StaffStats _buildStats(List<ComplaintModel> complaints) {
		final assigned = complaints.where((c) => c.status == 'ASSIGNED').length;
		final inProgress = complaints.where((c) => c.status == 'IN_PROGRESS').length;
		final resolvedToday = complaints
				.where((c) => c.status == 'RESOLVED' && c.updatedAt.isToday)
				.length;
		return _StaffStats(assigned, inProgress, resolvedToday);
	}

	Widget _statTile(String label, int value) {
		return Expanded(
			child: Container(
				padding: const EdgeInsets.all(12),
				decoration: BoxDecoration(
					color: AppColors.surface,
					borderRadius: BorderRadius.circular(12),
					border: Border.all(color: AppColors.border),
				),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
						const SizedBox(height: 6),
						Text('$value', style: AppTextStyles.titleLarge),
					],
				),
			),
		);
	}

	Future<void> _startWorking(ComplaintModel complaint) async {
		try {
			await _updateStatusUseCase(
				complaintId: complaint.id,
				newStatus: 'IN_PROGRESS',
				notes: 'Started work',
			);
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Marked as In Progress.')),
			);
			context.read<ComplaintBloc>().add(RefreshComplaints());
		} catch (_) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Failed to update status.')),
			);
		}
	}
}

class _StaffStats {
	final int assigned;
	final int inProgress;
	final int resolvedToday;

	_StaffStats(this.assigned, this.inProgress, this.resolvedToday);
}
