import '../../data/repositories/complaint_repository.dart';

class UpdateComplaintStatusUseCase {
	final ComplaintRepository _repository;

	UpdateComplaintStatusUseCase({required ComplaintRepository repository})
			: _repository = repository;

	Future<void> call({
		required String complaintId,
		required String newStatus,
		String? notes,
	}) {
		return _repository.updateComplaintStatus(
			complaintId,
			newStatus: newStatus,
			notes: notes,
		);
	}
}
