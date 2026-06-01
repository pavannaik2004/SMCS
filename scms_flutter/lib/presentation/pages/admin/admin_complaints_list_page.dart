import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../bloc/complaint/complaint_bloc.dart';
import '../../bloc/complaint/complaint_event.dart';
import '../../bloc/complaint/complaint_state.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/scms_chip.dart';
import '../../widgets/complaint/complaint_card.dart';

class AdminComplaintsListPage extends StatefulWidget {
	const AdminComplaintsListPage({super.key});

	@override
	State<AdminComplaintsListPage> createState() => _AdminComplaintsListPageState();
}

class _AdminComplaintsListPageState extends State<AdminComplaintsListPage> {
	final _filters = const [
		'All',
		'OPEN',
		'ASSIGNED',
		'IN_PROGRESS',
		'RESOLVED',
		'CLOSED',
		'REJECTED',
	];
	String _activeFilter = 'All';

	@override
	void initState() {
		super.initState();
		context.read<ComplaintBloc>().add(LoadAllComplaints());
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('All Complaints'),
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
								return ScmsChip(
									label: filter == 'All' ? 'All' : filter.replaceAll('_', ' '),
									isSelected: filter == _activeFilter,
									onTap: () {
										setState(() => _activeFilter = filter);
										context.read<ComplaintBloc>().add(
													LoadAllComplaints(
														status: filter == 'All' ? null : filter,
													),
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
										onRetry: () => context.read<ComplaintBloc>().add(LoadAllComplaints()),
									);
								}
								if (state is AllComplaintsLoaded) {
									if (state.complaints.isEmpty) {
										return const EmptyStateWidget(
											title: 'No complaints found',
											subtitle: 'Try adjusting your filters.',
											icon: Icons.search_off_rounded,
										);
									}
									return RefreshIndicator(
										onRefresh: () async =>
												context.read<ComplaintBloc>().add(LoadAllComplaints()),
										child: ListView.builder(
											padding: const EdgeInsets.only(bottom: 24),
											itemCount: state.complaints.length,
											itemBuilder: (_, i) => ComplaintCard(
												complaint: state.complaints[i],
												onTap: () => context.push('/complaint/${state.complaints[i].id}'),
											),
										),
									);
								}
								return Center(
									child: Text('Loading complaints...', style: AppTextStyles.bodySmall),
								);
							},
						),
					),
				],
			),
		);
	}
}
