import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/no_connection_card.dart';
import '../../data/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  bool _isBackendActive = false;
  bool _isCheckingBackend = true;

  final List<Map<String, dynamic>> _carouselItems = [
    {
      'image': 'assets/images/food_1.jpg',
      'title': 'Smart Catering Solutions',
      'subtitle': 'Powered by 3 AI Models',
      'gradient': [const Color(0xFF1E3A5F), const Color(0xFF2563EB)],
    },
    {
      'image': 'assets/images/food_2.jpg',
      'title': 'AI Demand Forecasting',
      'subtitle': 'Predict orders with 94% accuracy',
      'gradient': [const Color(0xFF065F46), const Color(0xFF10B981)],
    },
    {
      'image': 'assets/images/food_3.jpg',
      'title': 'Menu Recommendations',
      'subtitle': '9,500+ restaurants analyzed',
      'gradient': [const Color(0xFF92400E), const Color(0xFFF59E0B)],
    },
    {
      'image': 'assets/images/food_4.jpg',
      'title': 'On-Time Delivery',
      'subtitle': 'Real-time ETA predictions',
      'gradient': [const Color(0xFF5B21B6), const Color(0xFF8B5CF6)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkBackendStatus();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkBackendStatus() async {
    setState(() => _isCheckingBackend = true);
    final isActive = await ApiService.checkHealth();
    if (mounted) {
      setState(() {
        _isBackendActive = isActive;
        _isCheckingBackend = false;
      });
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(
      const Duration(seconds: 4),
          (timer) {
        if (_pageController.hasClients) {
          int nextPage = _currentPage + 1;
          if (nextPage >= _carouselItems.length) nextPage = 0;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isBackendActive
            ? _buildOnlineContent()
            : _buildOfflineContent(),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ONLINE CONTENT (normal home screen)
  // ═══════════════════════════════════════════
  Widget _buildOnlineContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(12),
          _buildHeader(),
          const Gap(16),
          _buildCarousel(),
          const Gap(20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildBackendStatus(),
          ),
          const Gap(20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildQuickStats(),
          ),
          const Gap(20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildAboutSection(),
          ),
          const Gap(30),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // OFFLINE CONTENT (backend not running)
  // ═══════════════════════════════════════════
  Widget _buildOfflineContent() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHeader(),
            const Gap(40),
            NoConnectionCard(
              message: _isCheckingBackend
                  ? 'Connecting to backend...'
                  : 'Could not reach the AI backend server.\nMake sure it is running on your PC.',
              onRetry: _checkBackendStatus,
              isRetrying: _isCheckingBackend,
            ),
            const Gap(20),

            // Show carousel even offline
            SizedBox(
              height: 160,
              child: _buildCarousel(),
            ),
            const Gap(20),

            // Quick stats (static, always visible)
            _buildQuickStats(),
            const Gap(20),

            // About section
            _buildAboutSection(),
            const Gap(30),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Iconsax.cpu,
              color: Colors.white,
              size: 22,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Catering',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  'Smart Platform',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _checkBackendStatus,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: _isCheckingBackend
                  ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
                  : const Icon(
                Icons.refresh_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ═══════════════════════════════════════════
  // CAROUSEL
  // ═══════════════════════════════════════════
  Widget _buildCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) =>
                setState(() => _currentPage = index),
            itemCount: _carouselItems.length,
            itemBuilder: (context, index) {
              return _buildCarouselItem(_carouselItems[index]);
            },
          ),
        ),
        const Gap(12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _carouselItems.length,
                (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? AppColors.primary
                    : AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildCarouselItem(Map<String, dynamic> item) {
    final gradientColors = item['gradient'] as List<Color>;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[1].withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              item['image'] as String,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    item['subtitle'] as String,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // BACKEND STATUS
  // ═══════════════════════════════════════════
  Widget _buildBackendStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isCheckingBackend
            ? AppColors.surfaceVariant
            : _isBackendActive
            ? AppColors.successLight
            : AppColors.errorLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isCheckingBackend
              ? AppColors.border
              : _isBackendActive
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _isCheckingBackend
                  ? AppColors.textHint
                  : _isBackendActive
                  ? AppColors.success
                  : AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isCheckingBackend
                      ? 'Checking Backend...'
                      : _isBackendActive
                      ? 'Backend Active'
                      : 'Backend Offline',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isCheckingBackend
                        ? AppColors.textSecondary
                        : _isBackendActive
                        ? const Color(0xFF065F46)
                        : const Color(0xFF991B1B),
                  ),
                ),
                const Gap(2),
                Text(
                  _isCheckingBackend
                      ? 'Connecting to ML models...'
                      : _isBackendActive
                      ? '3 ML models loaded • Ready for predictions'
                      : 'Please start backend: python run.py',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isCheckingBackend
                        ? AppColors.textHint
                        : _isBackendActive
                        ? const Color(0xFF047857)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _checkBackendStatus,
            child: Icon(
              Icons.refresh_rounded,
              color: _isBackendActive
                  ? AppColors.success
                  : AppColors.textHint,
              size: 20,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  // ═══════════════════════════════════════════
  // QUICK STATS
  // ═══════════════════════════════════════════
  Widget _buildQuickStats() {
    return Row(
      children: [
        _buildStatCard(
          icon: Iconsax.chart_2,
          value: 'R² 0.94',
          label: 'Accuracy',
          color: AppColors.primary,
        ),
        const Gap(10),
        _buildStatCard(
          icon: Iconsax.shop,
          value: '9.5K',
          label: 'Restaurants',
          color: AppColors.secondary,
        ),
        const Gap(10),
        _buildStatCard(
          icon: Iconsax.timer_1,
          value: '< 100ms',
          label: 'Response',
          color: AppColors.success,
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const Gap(8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Gap(2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ABOUT SECTION
  // ═══════════════════════════════════════════
  Widget _buildAboutSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About This Platform',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Gap(8),
          Text(
            'AI-powered catering platform that predicts order demand, '
                'recommends restaurants with menus, and estimates delivery time '
                'using LightGBM models trained on 100K+ orders.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
          const Gap(12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTechChip('LightGBM'),
              _buildTechChip('FastAPI'),
              _buildTechChip('Flutter'),
              _buildTechChip('SHAP'),
              _buildTechChip('MLflow'),
              _buildTechChip('Optuna'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 400.ms);
  }

  Widget _buildTechChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
      ),
    );
  }
}