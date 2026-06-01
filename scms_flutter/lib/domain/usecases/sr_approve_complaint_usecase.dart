import '../../data/repositories/sr_review_repository.dart';

class SrApproveComplaintUseCase {
	final SrReviewRepository _repository;

	SrApproveComplaintUseCase({required SrReviewRepository repository})
			: _repository = repository;

	Future<void> call({required String complaintId}) {
		return _repository.approveComplaint(complaintId);
	}
}
