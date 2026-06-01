import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../bloc/sr_review/sr_review_bloc.dart';
import '../../bloc/sr_review/sr_review_event.dart';
import '../../bloc/sr_review/sr_review_state.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/scms_button.dart';
import '../../widgets/common/scms_text_field.dart';
import '../../widgets/complaint/complaint_card.dart';

class SrDashboardPage extends StatefulWidget {
	const SrDashboardPage({super.key});

	@override
	State<SrDashboardPage> createState() => _SrDashboardPageState();
}

class _SrDashboardPageState extends State<SrDashboardPage> {
	@override
	void initState() {
		super.initState();
		context.read<SrReviewBloc>().add(LoadPendingReviews());
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('SR Review'),
				actions: [
					Container(
						margin: const EdgeInsets.only(right: 16),
						padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
						decoration: BoxDecoration(
							color: AppColors.surfaceVariant,
							borderRadius: BorderRadius.circular(12),
						),
						child: Text('SR', style: AppTextStyles.labelSmall),
					),
				],
			),
			body: BlocConsumer<SrReviewBloc, SrReviewState>(
				listener: (context, state) {
					if (state is SrReviewLoaded && state.actionError != null) {
						ScaffoldMessenger.of(context).showSnackBar(
							SnackBar(content: Text(state.actionError!)),
						);
					}
				},
				builder: (context, state) {
					if (state is SrReviewLoading) {
						return const Center(child: CircularProgressIndicator());
					}
					if (state is SrReviewError) {
						return ScmsErrorWidget(
							message: state.message,
							onRetry: () => context.read<SrReviewBloc>().add(LoadPendingReviews()),
						);
					}
					if (state is SrReviewEmpty) {
						return const EmptyStateWidget(
							title: 'No pending SR reviews',
							subtitle: 'New complaints will appear here for approval.',
							icon: Icons.inbox_rounded,
						);
					}
					if (state is SrReviewLoaded) {
						return RefreshIndicator(
							onRefresh: () async =>
									context.read<SrReviewBloc>().add(RefreshPendingReviews()),
							child: ListView.builder(
								padding: const EdgeInsets.only(bottom: 24),
								itemCount: state.complaints.length,
								itemBuilder: (context, index) {
									final complaint = state.complaints[index];
									final isProcessing = state.processingId == complaint.id;
									return Column(
										children: [
											ComplaintCard(
												complaint: complaint,
												onTap: () => context.push('/sr/review/${complaint.id}'),
											),
											Padding(
												padding: const EdgeInsets.symmetric(horizontal: 16),
												child: Row(
													children: [
														Expanded(
															child: ScmsButton(
																label: 'Approve',
																isLoading: isProcessing,
																onPressed: isProcessing
																		? null
																		: () => context.read<SrReviewBloc>().add(
																					ApprovePendingComplaint(
																						complaintId: complaint.id,
																					),
																				),
																isFullWidth: true,
															),
														),
														const SizedBox(width: 12),
														Expanded(
															child: ScmsButton(
																label: 'Reject',
																variant: ScmsButtonVariant.destructive,
																isLoading: isProcessing,
																onPressed: isProcessing
																		? null
																		: () => _showRejectSheet(complaint.id),
																isFullWidth: true,
															),
														),
													],
												),
											),
											const SizedBox(height: 16),
										],
									);
								},
							),
						);
					}
					return const SizedBox.shrink();
				},
			),
		);
	}

	void _showRejectSheet(String complaintId) {
		final controller = TextEditingController();
		showModalBottomSheet<void>(
			context: context,
			isScrollControlled: true,
			shape: const RoundedRectangleBorder(
				borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
			),
			builder: (context) {
				return Padding(
					padding: EdgeInsets.only(
						left: 16,
						right: 16,
						top: 16,
						bottom: MediaQuery.of(context).viewInsets.bottom + 16,
					),
					child: Column(
						mainAxisSize: MainAxisSize.min,
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text('Rejection Reason', style: AppTextStyles.titleMedium),
							const SizedBox(height: 12),
							ScmsTextField(
								label: 'Reason',
								hint: 'Add a short explanation',
								controller: controller,
								maxLines: 3,
							),
							const SizedBox(height: 16),
							ScmsButton(
								label: 'Submit Rejection',
								variant: ScmsButtonVariant.destructive,
								onPressed: () {
									final reason = controller.text.trim();
									if (reason.isEmpty) {
										ScaffoldMessenger.of(context).showSnackBar(
											const SnackBar(content: Text('Please enter a rejection reason.')),
										);
										return;
									}
									context.read<SrReviewBloc>().add(
												RejectPendingComplaint(
													complaintId: complaintId,
													rejectionCause: reason,
												),
											);
									Navigator.pop(context);
								},
							),
						],
					),
				);
			},
		).whenComplete(controller.dispose);
	}
}
