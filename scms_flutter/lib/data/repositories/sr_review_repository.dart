import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../datasources/remote/sr_review_remote_datasource.dart';
import '../models/complaint_model.dart';

class SrReviewRepository {
	final SrReviewRemoteDataSource _remoteDataSource;
	final NetworkInfo _networkInfo;

	SrReviewRepository({
		required SrReviewRemoteDataSource remoteDataSource,
		required NetworkInfo networkInfo,
	})  : _remoteDataSource = remoteDataSource,
				_networkInfo = networkInfo;

	Future<List<ComplaintModel>> getPendingReviews() async {
		if (!await _networkInfo.isConnected) throw const NetworkFailure();
		try {
			return await _remoteDataSource.getPendingReviews();
		} on ServerException catch (e) {
			throw ServerFailure(message: e.message, statusCode: e.statusCode);
		}
	}

	Future<void> approveComplaint(String complaintId) async {
		if (!await _networkInfo.isConnected) throw const NetworkFailure();
		try {
			await _remoteDataSource.approveComplaint(complaintId);
		} on ServerException catch (e) {
			throw ServerFailure(message: e.message, statusCode: e.statusCode);
		}
	}

	Future<void> rejectComplaint(
		String complaintId, {
		required String rejectionCause,
	}) async {
		if (!await _networkInfo.isConnected) throw const NetworkFailure();
		try {
			await _remoteDataSource.rejectComplaint(
				complaintId,
				rejectionCause: rejectionCause,
			);
		} on ServerException catch (e) {
			throw ServerFailure(message: e.message, statusCode: e.statusCode);
		}
	}
}
