abstract class SrReviewEvent {}

class LoadPendingReviews extends SrReviewEvent {}

class RefreshPendingReviews extends SrReviewEvent {}

class ApprovePendingComplaint extends SrReviewEvent {
	final String complaintId;

	ApprovePendingComplaint({required this.complaintId});
}

class RejectPendingComplaint extends SrReviewEvent {
	final String complaintId;
	final String rejectionCause;

	RejectPendingComplaint({
		required this.complaintId,
		required this.rejectionCause,
	});
}
