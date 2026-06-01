import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/extensions.dart';
import '../../bloc/complaint/complaint_bloc.dart';
import '../../bloc/complaint/complaint_event.dart';
import '../../bloc/complaint/complaint_state.dart';
import '../../bloc/sr_review/sr_review_bloc.dart';
import '../../bloc/sr_review/sr_review_event.dart';
import '../../bloc/sr_review/sr_review_state.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/scms_button.dart';
import '../../widgets/common/scms_text_field.dart';
import '../../widgets/complaint/status_badge.dart';
import '../../widgets/complaint/sla_timer_widget.dart';

class SrReviewDetailPage extends StatefulWidget {
	final String complaintId;
	const SrReviewDetailPage({super.key, required this.complaintId});

	@override
	State<SrReviewDetailPage> createState() => _SrReviewDetailPageState();
}

class _SrReviewDetailPageState extends State<SrReviewDetailPage> {
	final TextEditingController _rejectionController = TextEditingController();
	bool _actionRequested = false;

	@override
	void initState() {
		super.initState();
		context.read<ComplaintBloc>().add(
					LoadComplaintDetail(complaintId: widget.complaintId),
				);
	}

	@override
	void dispose() {
		_rejectionController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return BlocListener<SrReviewBloc, SrReviewState>(
			listener: (context, state) {
				if (!_actionRequested) return;
				if (state is SrReviewLoaded) {
					if (state.actionError != null) {
						_actionRequested = false;
						ScaffoldMessenger.of(context).showSnackBar(
							SnackBar(content: Text(state.actionError!)),
						);
						return;
					}
					final stillExists = state.complaints
							.any((c) => c.id == widget.complaintId);
					if (!stillExists) {
						Navigator.pop(context);
					}
				}
				if (state is SrReviewEmpty) {
					Navigator.pop(context);
				}
			},
			child: Scaffold(
				appBar: AppBar(title: const Text('SR Review Detail')),
				body: BlocBuilder<ComplaintBloc, ComplaintState>(
					builder: (context, complaintState) {
						final isProcessing = context.select<SrReviewBloc, bool>(
							(bloc) => bloc.state is SrReviewLoaded &&
									(bloc.state as SrReviewLoaded).processingId == widget.complaintId,
						);

						if (complaintState is ComplaintLoading) {
							return const Center(child: CircularProgressIndicator());
						}
						if (complaintState is ComplaintError) {
							return ScmsErrorWidget(
								message: complaintState.message,
								onRetry: () => context.read<ComplaintBloc>().add(
											LoadComplaintDetail(complaintId: widget.complaintId),
										),
							);
						}
						if (complaintState is! ComplaintDetailLoaded) {
							return const SizedBox.shrink();
						}

						final c = complaintState.complaint;
						return LoadingOverlay(
							isLoading: isProcessing,
							message: 'Processing review...',
							child: ListView(
								padding: const EdgeInsets.all(16),
								children: [
									Row(
										mainAxisAlignment: MainAxisAlignment.spaceBetween,
										children: [
											Text(
												'#${c.complaintNumber}',
												style: AppTextStyles.labelMedium.copyWith(
													color: AppColors.textSecondary,
												),
											),
											StatusBadge(status: c.status),
										],
									),
									const SizedBox(height: 8),
									Text(c.subject, style: AppTextStyles.headlineMedium),
									const SizedBox(height: 4),
									Text(
										'Submitted ${DateFormatter.formatFull(c.createdAt)}',
										style: AppTextStyles.caption,
									),
									const Divider(height: 24),
									Text(c.description, style: AppTextStyles.bodyMedium),
									const SizedBox(height: 16),
									_infoRow(Icons.location_on_outlined, 'Location', c.location),
									_infoRow(Icons.category_outlined, 'Category', c.categoryName),
									_infoRow(Icons.business_rounded, 'Department', c.departmentName),
									_infoRow(Icons.warning_amber_rounded, 'Severity', c.severity),
									if (c.isSlaActive) ...[
										const SizedBox(height: 16),
										SlaTimerWidget(createdAt: c.createdAt, deadline: c.slaDeadline!),
									],
									const SizedBox(height: 24),
									Text('Review Decision', style: AppTextStyles.titleLarge),
									const SizedBox(height: 12),
									ScmsTextField(
										label: 'Rejection reason (required if rejecting)'.trim(),
										hint: 'Add a short explanation',
										controller: _rejectionController,
										maxLines: 3,
									),
									const SizedBox(height: 16),
									Row(
										children: [
											Expanded(
												child: ScmsButton(
													label: 'Approve',
													onPressed: isProcessing
															? null
															: () {
																	_actionRequested = true;
																	context.read<SrReviewBloc>().add(
																				ApprovePendingComplaint(
																					complaintId: widget.complaintId,
																				),
																			);
																},
												),
											),
											const SizedBox(width: 12),
											Expanded(
												child: ScmsButton(
													label: 'Reject',
													variant: ScmsButtonVariant.destructive,
													onPressed: isProcessing
															? null
															: () {
																	final reason = _rejectionController.text.trim();
																	if (reason.isEmpty) {
																		ScaffoldMessenger.of(context).showSnackBar(
																			const SnackBar(
																				content: Text('Please enter a rejection reason.'),
																			),
																		);
																		return;
																	}
																	_actionRequested = true;
																	context.read<SrReviewBloc>().add(
																				RejectPendingComplaint(
																					complaintId: widget.complaintId,
																					rejectionCause: reason,
																				),
																			);
																},
												),
											),
										],
									),
								],
							),
						);
					},
				),
			),
		);
	}

	Widget _infoRow(IconData icon, String label, String value) {
		return Padding(
			padding: const EdgeInsets.symmetric(vertical: 6),
			child: Row(
				children: [
					Icon(icon, size: 18, color: AppColors.textSecondary),
					const SizedBox(width: 10),
					Text('$label: ', style: AppTextStyles.labelMedium),
					Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
				],
			),
		);
	}
}
