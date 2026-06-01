import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/api_constants.dart';
import '../core/constants/app_constants.dart';
import '../core/network/dio_client.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class NotificationService {
	NotificationService._();

	static final NotificationService instance = NotificationService._();

	final FirebaseMessaging _messaging = FirebaseMessaging.instance;
	final FlutterLocalNotificationsPlugin _localNotifications =
			FlutterLocalNotificationsPlugin();

	OverlayEntry? _bannerEntry;
	bool _initialized = false;

	Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
		if (_initialized) return;
		_initialized = true;

		await _messaging.requestPermission();

		const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
		const iosSettings = DarwinInitializationSettings();
		const initSettings = InitializationSettings(
			android: androidSettings,
			iOS: iosSettings,
		);

		await _localNotifications.initialize(
			initSettings,
			onDidReceiveNotificationResponse: (response) {
				final payload = response.payload;
				if (payload != null) {
					_handlePayloadTap(payload, navigatorKey);
				}
			},
		);

		await _messaging.setForegroundNotificationPresentationOptions(
			alert: true,
			badge: true,
			sound: true,
		);

		await _syncFcmToken();
		_messaging.onTokenRefresh.listen(_sendTokenToServer);

		FirebaseMessaging.onMessage.listen((message) {
			_showInAppBanner(message, navigatorKey);
			_showLocalNotification(message);
		});

		FirebaseMessaging.onMessageOpenedApp.listen(
			(message) => _handleMessageTap(message, navigatorKey),
		);

		final initialMessage = await _messaging.getInitialMessage();
		if (initialMessage != null) {
			_handleMessageTap(initialMessage, navigatorKey);
		}
	}

	Future<void> _syncFcmToken() async {
		final token = await _messaging.getToken();
		if (token == null) return;
		await _sendTokenToServer(token);
	}

	Future<void> _sendTokenToServer(String token) async {
		try {
			final dioClient = DioClient();
			await dioClient.dio.patch(
				ApiConstants.userFcmToken,
				data: {'token': token},
			);
		} catch (_) {
			// Token sync is best-effort; fail silently.
		}
	}

	void _showLocalNotification(RemoteMessage message) {
		final notification = message.notification;
		if (notification == null) return;

		const androidDetails = AndroidNotificationDetails(
			'scms_updates',
			'SCMS Updates',
			importance: Importance.max,
			priority: Priority.high,
		);
		const iosDetails = DarwinNotificationDetails();
		const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

		_localNotifications.show(
			notification.hashCode,
			notification.title ?? 'SCMS',
			notification.body,
			details,
			payload: _encodePayload(message.data),
		);
	}

	void _showInAppBanner(RemoteMessage message, GlobalKey<NavigatorState>? key) {
		final context = key?.currentContext;
		if (context == null) return;

		_removeBanner();
		_bannerEntry = OverlayEntry(
			builder: (_) => _NotificationBanner(
				title: message.notification?.title ?? 'SCMS',
				body: message.notification?.body ?? 'You have a new update.',
				onTap: () {
					_handleMessageTap(message, key);
					_removeBanner();
				},
			),
		);

		final overlay = Overlay.of(context, rootOverlay: true);
		overlay.insert(_bannerEntry!);

		Timer(
			const Duration(seconds: AppConstants.notificationBannerDurationSec),
			_removeBanner,
		);
	}

	void _removeBanner() {
		_bannerEntry?.remove();
		_bannerEntry = null;
	}

	void _handleMessageTap(RemoteMessage message, GlobalKey<NavigatorState>? key) {
		final complaintId = _extractComplaintId(message.data);
		if (complaintId == null) return;

		final context = key?.currentContext;
		if (context != null) {
			context.push('/complaint/$complaintId');
		}
	}

	void _handlePayloadTap(String payload, GlobalKey<NavigatorState>? key) {
		final parts = payload.split(':');
		if (parts.length != 2 || parts[0] != 'complaint') return;
		final id = parts[1];
		final context = key?.currentContext;
		if (context != null) {
			context.push('/complaint/$id');
		}
	}

	String? _extractComplaintId(Map<String, dynamic> data) {
		final id = data['complaintId'];
		if (id == null) return null;
		return id.toString();
	}

	String? _encodePayload(Map<String, dynamic> data) {
		final id = _extractComplaintId(data);
		if (id == null) return null;
		return 'complaint:$id';
	}
}

class _NotificationBanner extends StatelessWidget {
	final String title;
	final String body;
	final VoidCallback onTap;

	const _NotificationBanner({
		required this.title,
		required this.body,
		required this.onTap,
	});

	@override
	Widget build(BuildContext context) {
		return SafeArea(
			child: Material(
				color: Colors.transparent,
				child: Align(
					alignment: Alignment.topCenter,
					child: Padding(
						padding: const EdgeInsets.all(12),
						child: GestureDetector(
							onTap: onTap,
							child: Container(
								padding: const EdgeInsets.all(14),
								decoration: BoxDecoration(
									color: AppColors.surface,
									borderRadius: BorderRadius.circular(16),
									border: Border.all(color: AppColors.border),
									boxShadow: [
										BoxShadow(
											color: Colors.black.withOpacity(0.08),
											blurRadius: 12,
											offset: const Offset(0, 6),
										),
									],
								),
								child: Row(
									children: [
										Container(
											width: 36,
											height: 36,
											decoration: BoxDecoration(
												color: AppColors.primary.withOpacity(0.12),
												borderRadius: BorderRadius.circular(10),
											),
											child: const Icon(Icons.notifications_rounded, color: AppColors.primary),
										),
										const SizedBox(width: 12),
										Expanded(
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													Text(title, style: AppTextStyles.titleSmall),
													const SizedBox(height: 4),
													Text(
														body,
														style: AppTextStyles.bodySmall.copyWith(
															color: AppColors.textSecondary,
														),
														maxLines: 2,
														overflow: TextOverflow.ellipsis,
													),
												],
											),
										),
									],
								),
							),
						),
					),
				),
			),
		);
	}
}
