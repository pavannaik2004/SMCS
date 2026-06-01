import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../data/models/analytics_model.dart';
import '../../../domain/usecases/get_analytics_usecase.dart';
import 'analytics_state.dart';

class AnalyticsCubit extends Cubit<AnalyticsState> {
	final GetAnalyticsUseCase _getAnalyticsUseCase;

	AnalyticsCubit({required GetAnalyticsUseCase getAnalyticsUseCase})
			: _getAnalyticsUseCase = getAnalyticsUseCase,
				super(AnalyticsInitial());

	Future<void> loadSummary() async {
		emit(AnalyticsLoading());
		try {
			final analytics = await _getAnalyticsUseCase();
			if (_isEmpty(analytics)) {
				emit(AnalyticsEmpty());
				return;
			}
			emit(AnalyticsLoaded(analytics: analytics));
		} on Failure catch (e) {
			emit(AnalyticsError(message: e.message));
		} catch (_) {
			emit(AnalyticsError(message: 'Failed to load analytics.'));
		}
	}

	bool _isEmpty(AnalyticsModel analytics) {
		return analytics.totalActiveComplaints == 0 &&
				analytics.byDepartment.isEmpty &&
				analytics.byCategory.isEmpty &&
				analytics.recentSlaBreaches.isEmpty;
	}
}
