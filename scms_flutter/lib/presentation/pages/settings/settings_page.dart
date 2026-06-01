import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/user_model.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../widgets/common/scms_button.dart';

class SettingsPage extends StatefulWidget {
	const SettingsPage({super.key});

	@override
	State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
	ThemeMode _themeMode = ThemeMode.system;
	bool _notificationsEnabled = true;

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Settings')),
			body: BlocBuilder<AuthBloc, AuthState>(
				builder: (context, state) {
					final user = state is AuthAuthenticated ? state.user : null;
					return ListView(
						padding: const EdgeInsets.all(16),
						children: [
							_buildProfileCard(user),
							const SizedBox(height: 20),
							Text('Preferences', style: AppTextStyles.titleMedium),
							const SizedBox(height: 8),
							_buildNotificationToggle(),
							const SizedBox(height: 12),
							_buildThemeSelector(),
							const SizedBox(height: 24),
							Text('About', style: AppTextStyles.titleMedium),
							const SizedBox(height: 8),
							_buildAboutCard(),
							const SizedBox(height: 24),
							ScmsButton(
								label: 'Logout',
								variant: ScmsButtonVariant.destructive,
								onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
							),
						],
					);
				},
			),
		);
	}

	Widget _buildProfileCard(UserModel? user) {
		final initials = user?.name.isNotEmpty == true
				? user!.name.trim().substring(0, 1).toUpperCase()
				: 'U';

		return Card(
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Row(
					children: [
						CircleAvatar(
							radius: 28,
							backgroundColor: AppColors.surfaceVariant,
							backgroundImage: user?.picture != null
									? NetworkImage(user!.picture!)
									: null,
							child: user?.picture == null
									? Text(initials, style: AppTextStyles.titleLarge)
									: null,
						),
						const SizedBox(width: 16),
						Expanded(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(user?.name ?? 'Guest User', style: AppTextStyles.titleMedium),
									const SizedBox(height: 4),
									Text(
										user?.email ?? 'Not signed in',
										style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
									),
								],
							),
						),
						Container(
							padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
							decoration: BoxDecoration(
								color: AppColors.surfaceVariant,
								borderRadius: BorderRadius.circular(12),
							),
							child: Text(
								_roleLabel(user?.role),
								style: AppTextStyles.labelSmall,
							),
						),
					],
				),
			),
		);
	}

	Widget _buildNotificationToggle() {
		return Card(
			child: SwitchListTile(
				value: _notificationsEnabled,
				onChanged: (value) => setState(() => _notificationsEnabled = value),
				title: Text('Notifications', style: AppTextStyles.titleSmall),
				subtitle: Text(
					'Enable push updates and reminders',
					style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
				),
			),
		);
	}

	Widget _buildThemeSelector() {
		return Card(
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text('Theme', style: AppTextStyles.titleSmall),
						const SizedBox(height: 8),
						DropdownButtonFormField<ThemeMode>(
							value: _themeMode,
							items: const [
								DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
								DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
								DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
							],
							onChanged: (mode) {
								if (mode == null) return;
								setState(() => _themeMode = mode);
							},
							decoration: const InputDecoration(border: OutlineInputBorder()),
						),
					],
				),
			),
		);
	}

	Widget _buildAboutCard() {
		return Card(
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text(AppConstants.appName, style: AppTextStyles.titleSmall),
						const SizedBox(height: 6),
						Text(
							AppConstants.appTagline,
							style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
						),
						const SizedBox(height: 12),
						Text(
							'Version ${AppConstants.appVersion} (${AppConstants.buildNumber})',
							style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
						),
					],
				),
			),
		);
	}

	String _roleLabel(String? role) {
		switch (role) {
			case 'ROLE_ADMIN':
				return 'ADMIN';
			case 'ROLE_DEPT_HEAD':
				return 'DEPT HEAD';
			case 'ROLE_STAFF':
				return 'STAFF';
			case 'ROLE_SR':
				return 'SR';
			default:
				return 'USER';
		}
	}
}
