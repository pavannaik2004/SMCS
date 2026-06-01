import '../../../data/models/complaint_model.dart';

abstract class SrReviewState {}

class SrReviewInitial extends SrReviewState {}

class SrReviewLoading extends SrReviewState {}

class SrReviewEmpty extends SrReviewState {}

class SrReviewLoaded extends SrReviewState {
	final List<ComplaintModel> complaints;
	final String? processingId;
	final String? actionError;

	SrReviewLoaded({
		required this.complaints,
		this.processingId,
		this.actionError,
	});
}

class SrReviewError extends SrReviewState {
	final String message;
	SrReviewError({required this.message});
}
