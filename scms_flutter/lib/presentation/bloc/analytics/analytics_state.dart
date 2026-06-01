import '../../../data/models/analytics_model.dart';

abstract class AnalyticsState {}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class AnalyticsEmpty extends AnalyticsState {}

class AnalyticsLoaded extends AnalyticsState {
	final AnalyticsModel analytics;

	AnalyticsLoaded({required this.analytics});
}

class AnalyticsError extends AnalyticsState {
	final String message;

	AnalyticsError({required this.message});
}
