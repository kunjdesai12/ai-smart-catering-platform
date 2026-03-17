import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';
import '../../data/services/api_service.dart';

class DemandScreen extends StatefulWidget {
  const DemandScreen({super.key});

  @override
  State<DemandScreen> createState() => _DemandScreenState();
}

class _DemandScreenState extends State<DemandScreen> {
  // ─── Location State ───
  List<Map<String, dynamic>> _cities = [];
  String? _selectedCity;
  List<Map<String, dynamic>> _restaurants = [];
  Map<String, dynamic>? _selectedRestaurant;

  // ─── Form State ───
  int _selectedDay = DateTime.now().weekday % 7;
  bool _isHoliday = false;

  // ─── Loading States ───
  bool _isLoadingCities = true;
  bool _isLoadingRestaurants = false;
  bool _isPredicting = false;

  // ─── Result ───
  Map<String, dynamic>? _forecastResult;
  String? _errorMessage;

  final List<String> _dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  final List<String> _priceLabels = ['', '₹', '₹₹', '₹₹₹', '₹₹₹₹'];

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    setState(() => _isLoadingCities = true);
    final cities = await ApiService.getCities();
    if (mounted) {
      setState(() {
        _cities = cities;
        _isLoadingCities = false;
      });
    }
  }

  Future<void> _loadRestaurants(String city) async {
    setState(() {
      _isLoadingRestaurants = true;
      _selectedRestaurant = null;
      _forecastResult = null;
    });

    final restaurants = await ApiService.getRestaurants(city: city);
    if (mounted) {
      setState(() {
        _restaurants = restaurants;
        _isLoadingRestaurants = false;
      });
    }
  }

  Future<void> _predictDemand() async {
    if (_selectedRestaurant == null) {
      setState(() => _errorMessage = 'Please select a restaurant first');
      return;
    }

    setState(() {
      _isPredicting = true;
      _errorMessage = null;
      _forecastResult = null;
    });

    final result = await ApiService.predictDemandBulk(
      restaurantId: _selectedRestaurant!['restaurant_id'],
      dayOfWeek: _selectedDay,
      holiday: _isHoliday ? 1 : 0,
      restaurantRating: (_selectedRestaurant!['rating'] as num).toDouble(),
      priceRange: _selectedRestaurant!['price_range'] as int,
    );

    if (mounted) {
      setState(() {
        _isPredicting = false;
        if (result != null) {
          _forecastResult = result;
        } else {
          _errorMessage = 'Prediction failed. Is backend running?';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demand Forecast'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepIndicator(),
            const Gap(16),
            _buildCitySelector(),
            const Gap(12),
            if (_selectedCity != null) _buildRestaurantSelector(),
            if (_selectedRestaurant != null) ...[
              const Gap(12),
              _buildSelectedRestaurantCard(),
              const Gap(12),
              _buildDaySelector(),
              const Gap(16),
              _buildPredictButton(),
            ],
            const Gap(16),
            if (_errorMessage != null) _buildErrorMessage(),
            if (_isPredicting) _buildLoadingIndicator(),
            if (_forecastResult != null && !_isPredicting) ...[
              _buildSummaryCards(),
              const Gap(16),
              _buildChart(),
              const Gap(16),
              _buildHourlyList(),
            ],
            const Gap(30),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    int currentStep = 0;
    if (_selectedCity != null) currentStep = 1;
    if (_selectedRestaurant != null) currentStep = 2;
    if (_forecastResult != null) currentStep = 3;

    return Row(
      children: [
        _buildStepDot('City', 0, currentStep),
        _buildStepLine(currentStep >= 1),
        _buildStepDot('Restaurant', 1, currentStep),
        _buildStepLine(currentStep >= 2),
        _buildStepDot('Predict', 2, currentStep),
        _buildStepLine(currentStep >= 3),
        _buildStepDot('Result', 3, currentStep),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildStepDot(String label, int step, int currentStep) {
    final isActive = currentStep >= step;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.surfaceVariant,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
              width: 2,
            ),
          ),
          child: Center(
            child: isActive
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : Text('${step + 1}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textHint)),
          ),
        ),
        const Gap(4),
        Text(label,
            style: TextStyle(
                fontSize: 9,
                color: isActive ? AppColors.primary : AppColors.textHint,
                fontWeight:
                isActive ? FontWeight.w600 : FontWeight.w400)),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: isActive ? AppColors.primary : AppColors.border,
      ),
    );
  }

  Widget _buildCitySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.location, color: AppColors.primary, size: 18),
              const Gap(8),
              Text('Step 1: Select City',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const Gap(12),
          if (_isLoadingCities)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child:
                CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            DropdownButtonFormField<String>(
              value: _selectedCity,
              isExpanded: true,
              decoration: const InputDecoration(
                hintText: 'Choose a city',
                prefixIcon: Icon(Iconsax.building, size: 18),
              ),
              items: _cities.map((city) {
                return DropdownMenuItem<String>(
                  value: city['city'] as String,
                  child: Text(
                    '${city['city']} (${city['restaurant_count']} restaurants)',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCity = value);
                  _loadRestaurants(value);
                }
              },
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildRestaurantSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.shop, color: AppColors.secondary, size: 18),
              const Gap(8),
              Text('Step 2: Select Restaurant',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const Gap(12),
          if (_isLoadingRestaurants)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child:
                CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_restaurants.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No restaurants found',
                  style: TextStyle(color: AppColors.textHint)),
            )
          else
            DropdownButtonFormField<int>(
              value: _selectedRestaurant?['restaurant_id'] as int?,
              isExpanded: true,
              decoration: const InputDecoration(
                hintText: 'Choose a restaurant',
                prefixIcon: Icon(Iconsax.cake, size: 18),
              ),
              items: _restaurants.map((r) {
                final name =
                    r['name'] ?? 'Restaurant #${r['restaurant_id']}';
                final cuisine = r['primary_cuisine'] ?? '';
                final rating = r['rating'] ?? 0;
                return DropdownMenuItem<int>(
                  value: r['restaurant_id'] as int,
                  child: Text(
                    '$name • $cuisine • ⭐$rating',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  final restaurant = _restaurants.firstWhere(
                        (r) => r['restaurant_id'] == value,
                  );
                  setState(() {
                    _selectedRestaurant = restaurant;
                    _forecastResult = null;
                  });
                }
              },
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }

  Widget _buildSelectedRestaurantCard() {
    final r = _selectedRestaurant!;
    final name = r['name'] ?? 'Restaurant #${r['restaurant_id']}';
    final cuisine = r['cuisines'] ?? 'Unknown';
    final rating = r['rating'] ?? 3.5;
    final priceRange = r['price_range'] ?? 2;
    final city = r['city'] ?? 'Unknown';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.shop,
                    color: AppColors.primary, size: 22),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const Gap(2),
                    Text('$city • ID: ${r['restaurant_id']}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const Gap(12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildInfoChip('⭐ $rating', AppColors.warningLight),
              _buildInfoChip(
                  _priceLabels[priceRange.clamp(1, 4)],
                  AppColors.successLight),
              _buildInfoChip(
                  cuisine.toString().length > 25
                      ? '${cuisine.toString().substring(0, 25)}...'
                      : cuisine.toString(),
                  AppColors.primarySurface),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms);
  }

  Widget _buildInfoChip(String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style:
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.calendar_1,
                  color: AppColors.success, size: 18),
              const Gap(8),
              Text('Step 3: Select Day',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const Gap(12),
          DropdownButtonFormField<int>(
            value: _selectedDay,
            isExpanded: true,
            decoration: const InputDecoration(
              hintText: 'Select day',
              prefixIcon: Icon(Iconsax.calendar_1, size: 18),
            ),
            items: List.generate(7, (i) {
              final isWeekend = i >= 5;
              return DropdownMenuItem(
                value: i,
                child: Row(
                  children: [
                    Text(_dayNames[i]),
                    if (isWeekend) ...[
                      const Gap(8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Weekend',
                            style: TextStyle(fontSize: 9)),
                      ),
                    ],
                  ],
                ),
              );
            }),
            onChanged: (value) {
              if (value != null) setState(() => _selectedDay = value);
            },
          ),
          const Gap(10),
          SwitchListTile(
            title:
            const Text('Holiday', style: TextStyle(fontSize: 14)),
            subtitle: const Text('Toggle if public holiday',
                style: TextStyle(fontSize: 11)),
            value: _isHoliday,
            onChanged: (v) => setState(() => _isHoliday = v),
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 300.ms);
  }

  Widget _buildPredictButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isPredicting ? null : _predictDemand,
        child: _isPredicting
            ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: Colors.white))
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.chart_2, size: 20),
            Gap(10),
            Text('Predict 24-Hour Demand'),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 400.ms);
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.error, size: 20),
          const Gap(10),
          Expanded(
            child: Text(_errorMessage!,
                style: const TextStyle(
                    color: AppColors.error, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            Gap(16),
            Text('Running AI prediction...',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final peakHour = _forecastResult!['peak_hour'] ?? 0;
    final peakOrders = _forecastResult!['peak_orders'] ?? 0;
    final totalOrders = _forecastResult!['total_day_orders'] ?? 0;
    final bestTime = _forecastResult!['best_time_to_order'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Forecast Summary',
            style: Theme.of(context).textTheme.titleLarge)
            .animate()
            .fadeIn(duration: 300.ms),
        const Gap(12),
        Row(
          children: [
            _buildSummaryCard('Peak Hour', '$peakHour:00',
                Iconsax.timer_1, AppColors.error, AppColors.errorLight),
            const Gap(10),
            _buildSummaryCard(
                'Peak Orders',
                '$peakOrders',
                Iconsax.chart_2,
                AppColors.primary,
                AppColors.primarySurface),
            const Gap(10),
            _buildSummaryCard(
                'Total Day',
                '$totalOrders',
                Iconsax.box_1,
                AppColors.success,
                AppColors.successLight),
          ],
        ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
        const Gap(12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Iconsax.info_circle,
                  color: AppColors.primary, size: 18),
              const Gap(10),
              Expanded(
                child: Text(bestTime,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon,
      Color color, Color bgColor) {
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
            Icon(icon, color: color, size: 20),
            const Gap(8),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const Gap(2),
            Text(title,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    final hourlyData = _forecastResult!['hourly_forecast'] as List;
    int maxOrders = 1;
    for (var h in hourlyData) {
      final orders = (h['predicted_orders'] as num).toInt();
      if (orders > maxOrders) maxOrders = orders;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('24-Hour Demand Forecast',
              style: Theme.of(context).textTheme.titleLarge),
          Text(
            '${_selectedRestaurant?['name'] ?? ''} • ${_dayNames[_selectedDay]}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Gap(20),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 23,
                minY: 0,
                maxY: (maxOrders * 1.2).toDouble(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                  (maxOrders / 4).ceilToDouble().clamp(1, 100),
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 4,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('${value.toInt()}h',
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textHint)),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      interval:
                      (maxOrders / 4).ceilToDouble().clamp(1, 100),
                      getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textHint)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: hourlyData
                        .map((h) => FlSpot(
                        (h['hour'] as num).toDouble(),
                        (h['predicted_orders'] as num)
                            .toDouble()))
                        .toList(),
                    isCurved: true,
                    color: AppColors.chartLine,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        final status =
                        hourlyData[index]['peak_status'];
                        return FlDotCirclePainter(
                          radius: status == 'peak' ? 5 : 3,
                          color: status == 'peak'
                              ? AppColors.peak
                              : status == 'dead'
                              ? AppColors.dead
                              : AppColors.chartLine,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                        show: true, color: AppColors.chartFill),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots
                        .map((spot) => LineTooltipItem(
                      '${spot.x.toInt()}:00\n${spot.y.toInt()} orders',
                      const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
          const Gap(14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Peak', AppColors.peak),
              const Gap(16),
              _buildLegendItem('Normal', AppColors.chartLine),
              const Gap(16),
              _buildLegendItem('Dead', AppColors.dead),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
            BoxDecoration(color: color, shape: BoxShape.circle)),
        const Gap(5),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildHourlyList() {
    final hourlyData = _forecastResult!['hourly_forecast'] as List;
    final peakOrders = (_forecastResult!['peak_orders'] as num)
        .toDouble()
        .clamp(1, 9999);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hourly Breakdown',
              style: Theme.of(context).textTheme.titleLarge),
          const Gap(12),
          ...hourlyData.map((h) {
            final hour = h['hour'] as int;
            final orders = (h['predicted_orders'] as num).toInt();
            final status = h['peak_status'] as String;

            Color statusColor;
            String statusLabel;
            if (status == 'peak') {
              statusColor = AppColors.peak;
              statusLabel = '🔥 Peak';
            } else if (status == 'dead') {
              statusColor = AppColors.dead;
              statusLabel = '😴 Dead';
            } else {
              statusColor = AppColors.normal;
              statusLabel = 'Normal';
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 45,
                    child: Text('$hour:00',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: orders / peakOrders,
                        backgroundColor: AppColors.surfaceVariant,
                        color: statusColor,
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const Gap(8),
                  SizedBox(
                    width: 30,
                    child: Text('$orders',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                  ),
                  const Gap(6),
                  SizedBox(
                    width: 60,
                    child: Text(statusLabel,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 9,
                            color: statusColor,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 400.ms);
  }
}