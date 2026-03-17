import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

class AiFeaturesScreen extends StatelessWidget {
  const AiFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(10),

              // Header
              Text(
                'AI Features',
                style: Theme.of(context).textTheme.headlineLarge,
              ).animate().fadeIn(duration: 400.ms),
              const Gap(6),
              Text(
                'Tap any feature to explore AI predictions',
                style: Theme.of(context).textTheme.bodyMedium,
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
              const Gap(24),

              // Feature Cards
              _buildFeatureCard(
                context: context,
                icon: Iconsax.chart_2,
                iconColor: AppColors.primary,
                iconBgColor: AppColors.primarySurface,
                title: 'Demand Forecast',
                subtitle:
                'Predict hourly order demand for any restaurant. '
                    'See 24-hour forecast with peak hour detection.',
                stats: 'R² = 0.94 • RMSE = 5.65',
                onTap: () => Navigator.pushNamed(context, '/demand'),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.05),

              const Gap(14),

              _buildFeatureCard(
                context: context,
                icon: Iconsax.cake,
                iconColor: AppColors.secondary,
                iconBgColor: AppColors.warningLight,
                title: 'Smart Recommendations',
                subtitle:
                'AI-powered restaurant & menu suggestions for catering. '
                    'Budget-aware with cuisine matching.',
                stats: '9,551 restaurants • 200 TF-IDF features',
                onTap: () => Navigator.pushNamed(context, '/recommend'),
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.05),

              const Gap(14),

              _buildFeatureCard(
                context: context,
                icon: Iconsax.timer_1,
                iconColor: AppColors.success,
                iconBgColor: AppColors.successLight,
                title: 'Delivery ETA',
                subtitle:
                'Predict accurate delivery time considering distance, '
                    'traffic, weather and vehicle type.',
                stats: 'R² = 0.81 • RMSE = 9.39',
                onTap: () => Navigator.pushNamed(context, '/eta'),
              ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.05),

              const Gap(30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String stats,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const Gap(14),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Icon(
                    Iconsax.arrow_right_3,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                ],
              ),
              const Gap(12),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                ),
              ),
              const Gap(10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  stats,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}