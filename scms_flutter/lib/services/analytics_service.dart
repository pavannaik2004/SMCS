import 'dart:ui';

import '../core/utils/logger.dart';

class AnalyticsService {
	AnalyticsService._();

	static Future<void> initialize() async {
		FlutterError.onError = (details) {
			FlutterError.presentError(details);
			AppLogger.error(
				'Flutter error',
				tag: 'Analytics',
				error: details.exception,
				stackTrace: details.stack,
			);
		};

		PlatformDispatcher.instance.onError = (error, stack) {
			AppLogger.error(
				'Uncaught error',
				tag: 'Analytics',
				error: error,
				stackTrace: stack,
			);
			return true;
		};
	}

	static void logEvent(String name, {Map<String, Object?>? params}) {
		final payload = params == null ? '' : ' ${params.toString()}';
		AppLogger.info('Event: $name$payload', tag: 'Analytics');
	}

	static void logScreenView(String screenName) {
		AppLogger.info('Screen: $screenName', tag: 'Analytics');
	}
}
