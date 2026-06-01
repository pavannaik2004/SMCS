import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class StatsCard extends StatelessWidget {
	final String title;
	final String value;
	final String? subtitle;
	final IconData? icon;
	final Color? accentColor;

	const StatsCard({
		super.key,
		required this.title,
		required this.value,
		this.subtitle,
		this.icon,
		this.accentColor,
	});

	@override
	Widget build(BuildContext context) {
		final color = accentColor ?? AppColors.primary;
		return Card(
			margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Row(
					children: [
						if (icon != null) ...[
							Container(
								width: 40,
								height: 40,
								decoration: BoxDecoration(
									color: color.withOpacity(0.12),
									borderRadius: BorderRadius.circular(12),
								),
								child: Icon(icon, color: color, size: 20),
							),
							const SizedBox(width: 12),
						],
						Expanded(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(
										title,
										style: AppTextStyles.labelMedium.copyWith(
											color: AppColors.textSecondary,
										),
									),
									const SizedBox(height: 6),
									Text(value, style: AppTextStyles.headlineMedium),
									if (subtitle != null) ...[
										const SizedBox(height: 4),
										Text(
											subtitle!,
											style: AppTextStyles.bodySmall.copyWith(
												color: AppColors.textSecondary,
											),
										),
									],
								],
							),
						),
					],
				),
			),
		);
	}
}
