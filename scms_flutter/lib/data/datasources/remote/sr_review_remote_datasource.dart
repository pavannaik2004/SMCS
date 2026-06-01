import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/dio_client.dart';
import '../../models/complaint_model.dart';

/// Remote data source for SR review API calls
class SrReviewRemoteDataSource {
	final DioClient _dioClient;

	SrReviewRemoteDataSource({required DioClient dioClient})
			: _dioClient = dioClient;

	Future<List<ComplaintModel>> getPendingReviews() async {
		try {
			final response = await _dioClient.dio.get(ApiConstants.srPendingReviews);
			final list = response.data as List<dynamic>;
			return list
					.map((json) => ComplaintModel.fromJson(json as Map<String, dynamic>))
					.toList();
		} on DioException catch (e) {
			throw ServerException(
				message: e.response?.data?['message'] ?? 'Failed to fetch pending reviews',
				statusCode: e.response?.statusCode,
			);
		}
	}

	Future<void> approveComplaint(String complaintId) async {
		try {
			await _dioClient.dio.post(ApiConstants.srApprove(complaintId));
		} on DioException catch (e) {
			throw ServerException(
				message: e.response?.data?['message'] ?? 'Failed to approve complaint',
				statusCode: e.response?.statusCode,
			);
		}
	}

	Future<void> rejectComplaint(
		String complaintId, {
		required String rejectionCause,
	}) async {
		try {
			await _dioClient.dio.post(
				ApiConstants.srReject(complaintId),
				data: {'rejectionCause': rejectionCause},
			);
		} on DioException catch (e) {
			throw ServerException(
				message: e.response?.data?['message'] ?? 'Failed to reject complaint',
				statusCode: e.response?.statusCode,
			);
		}
	}
}
