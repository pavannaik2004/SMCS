import '../../data/repositories/sr_review_repository.dart';

class SrRejectComplaintUseCase {
	final SrReviewRepository _repository;

	SrRejectComplaintUseCase({required SrReviewRepository repository})
			: _repository = repository;

	Future<void> call({
		required String complaintId,
		required String rejectionCause,
	}) {
		return _repository.rejectComplaint(
			complaintId,
			rejectionCause: rejectionCause,
		);
	}
}
