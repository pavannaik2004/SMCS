import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../data/repositories/sr_review_repository.dart';
import '../../../domain/usecases/sr_approve_complaint_usecase.dart';
import '../../../domain/usecases/sr_reject_complaint_usecase.dart';
import 'sr_review_event.dart';
import 'sr_review_state.dart';

class SrReviewBloc extends Bloc<SrReviewEvent, SrReviewState> {
	final SrReviewRepository _repository;
	final SrApproveComplaintUseCase _approveUseCase;
	final SrRejectComplaintUseCase _rejectUseCase;

	SrReviewBloc({
		required SrReviewRepository repository,
		required SrApproveComplaintUseCase approveUseCase,
		required SrRejectComplaintUseCase rejectUseCase,
	})  : _repository = repository,
				_approveUseCase = approveUseCase,
				_rejectUseCase = rejectUseCase,
				super(SrReviewInitial()) {
		on<LoadPendingReviews>(_onLoadPending);
		on<RefreshPendingReviews>(_onRefreshPending);
		on<ApprovePendingComplaint>(_onApprove);
		on<RejectPendingComplaint>(_onReject);
	}

	Future<void> _onLoadPending(
		LoadPendingReviews event,
		Emitter<SrReviewState> emit,
	) async {
		emit(SrReviewLoading());
		try {
			final pending = await _repository.getPendingReviews();
			if (pending.isEmpty) {
				emit(SrReviewEmpty());
				return;
			}
			emit(SrReviewLoaded(complaints: pending));
		} on Failure catch (e) {
			emit(SrReviewError(message: e.message));
		} catch (_) {
			emit(SrReviewError(message: 'Failed to load pending reviews.'));
		}
	}

	Future<void> _onRefreshPending(
		RefreshPendingReviews event,
		Emitter<SrReviewState> emit,
	) async {
		add(LoadPendingReviews());
	}

	Future<void> _onApprove(
		ApprovePendingComplaint event,
		Emitter<SrReviewState> emit,
	) async {
		if (state is! SrReviewLoaded) return;
		final current = (state as SrReviewLoaded).complaints;
		emit(SrReviewLoaded(complaints: current, processingId: event.complaintId));

		try {
			await _approveUseCase(complaintId: event.complaintId);
			final updated = current
					.where((c) => c.id != event.complaintId)
					.toList();
			if (updated.isEmpty) {
				emit(SrReviewEmpty());
				return;
			}
			emit(SrReviewLoaded(complaints: updated));
		} on Failure catch (e) {
			emit(SrReviewLoaded(complaints: current, actionError: e.message));
		} catch (_) {
			emit(SrReviewLoaded(
				complaints: current,
				actionError: 'Approval failed. Please try again.',
			));
		}
	}

	Future<void> _onReject(
		RejectPendingComplaint event,
		Emitter<SrReviewState> emit,
	) async {
		if (state is! SrReviewLoaded) return;
		final current = (state as SrReviewLoaded).complaints;
		emit(SrReviewLoaded(complaints: current, processingId: event.complaintId));

		try {
			await _rejectUseCase(
				complaintId: event.complaintId,
				rejectionCause: event.rejectionCause,
			);
			final updated = current
					.where((c) => c.id != event.complaintId)
					.toList();
			if (updated.isEmpty) {
				emit(SrReviewEmpty());
				return;
			}
			emit(SrReviewLoaded(complaints: updated));
		} on Failure catch (e) {
			emit(SrReviewLoaded(complaints: current, actionError: e.message));
		} catch (_) {
			emit(SrReviewLoaded(
				complaints: current,
				actionError: 'Rejection failed. Please try again.',
			));
		}
	}
}
