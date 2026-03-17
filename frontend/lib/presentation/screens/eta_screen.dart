import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/widgets/no_connection_card.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/api_service.dart';

class ETAScreen extends StatefulWidget {
  const ETAScreen({super.key});

  @override
  State<ETAScreen> createState() => _ETAScreenState();
}

class _ETAScreenState extends State<ETAScreen>
    with SingleTickerProviderStateMixin {
  // ─── Brand Color ───
  static const Color _accentColor = Color(0xFF0EA5E9);
  static const Color _accentLight = Color(0xFFE0F2FE);
  static const Color _accentDark = Color(0xFF0369A1);

  // ─── Form Controllers ───
  final _distanceController = TextEditingController(text: '5.0');
  final _prepTimeController = TextEditingController(text: '20');

  // ─── Form State ───
  String _selectedWeather = 'clear';
  String _selectedTraffic = 'medium';
  String _selectedTimeOfDay = 'evening';
  String _selectedVehicle = 'bike';

  // ─── Loading & Result ───
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _errorMessage;

  // ─── Animation ───
  late AnimationController _pulseController;

  // ─── Options ───
  final List<Map<String, dynamic>> _weatherOptions = [
    {'value': 'clear', 'label': 'Clear', 'emoji': '☀️'},
    {'value': 'rainy', 'label': 'Rainy', 'emoji': '🌧️'},
    {'value': 'foggy', 'label': 'Foggy', 'emoji': '🌫️'},
    {'value': 'windy', 'label': 'Windy', 'emoji': '💨'},
    {'value': 'snowy', 'label': 'Snowy', 'emoji': '❄️'},
  ];

  final List<Map<String, dynamic>> _trafficOptions = [
    {'value': 'low', 'label': 'Low', 'emoji': '🟢', 'color': Color(0xFF10B981)},
    {'value': 'medium', 'label': 'Medium', 'emoji': '🟡', 'color': Color(0xFFF59E0B)},
    {'value': 'high', 'label': 'High', 'emoji': '🔴', 'color': Color(0xFFEF4444)},
  ];

  final List<Map<String, dynamic>> _timeOptions = [
    {'value': 'morning', 'label': 'Morning', 'emoji': '🌅', 'range': '6AM - 12PM'},
    {'value': 'afternoon', 'label': 'Afternoon', 'emoji': '☀️', 'range': '12PM - 5PM'},
    {'value': 'evening', 'label': 'Evening', 'emoji': '🌆', 'range': '5PM - 9PM'},
    {'value': 'night', 'label': 'Night', 'emoji': '🌙', 'range': '9PM - 6AM'},
  ];

  final List<Map<String, dynamic>> _vehicleOptions = [
    {'value': 'bicycle', 'label': 'Bicycle', 'emoji': '🚲'},
    {'value': 'bike', 'label': 'Bike', 'emoji': '🏍️'},
    {'value': 'scooter', 'label': 'Scooter', 'emoji': '🛵'},
    {'value': 'car', 'label': 'Car', 'emoji': '🚗'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _prepTimeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _predictETA() async {
    final distance = double.tryParse(_distanceController.text);
    final prepTime = double.tryParse(_prepTimeController.text);

    if (distance == null || distance <= 0 || distance > 50) {
      setState(() => _errorMessage = 'Enter valid distance (0.5 - 50 km)');
      return;
    }
    if (prepTime == null || prepTime <= 0 || prepTime > 60) {
      setState(() => _errorMessage = 'Enter valid prep time (1 - 60 min)');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    final result = await ApiService.predictEta(
      distanceKm: distance,
      preparationTimeMin: prepTime,
      weather: _selectedWeather,
      trafficLevel: _selectedTraffic,
      timeOfDay: _selectedTimeOfDay,
      vehicleType: _selectedVehicle,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result != null) {
          _result = result;
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
        title: const Text('Delivery ETA'),
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
            _buildHeaderCard(),
            const Gap(16),
            _buildDeliveryForm(),
            const Gap(16),
            _buildConditionsForm(),
            const Gap(16),
            _buildPredictButton(),
            const Gap(16),
            if (_errorMessage != null) _buildErrorMessage(),
            if (_isLoading) _buildLoading(),
            if (_result != null && !_isLoading) ...[
              _buildETAResult(),
              const Gap(14),
              _buildBreakdown(),
              const Gap(14),
              _buildTimeline(),
              const Gap(14),
              _buildConfidenceCard(),
            ],
            const Gap(30),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // HEADER CARD
  // ═══════════════════════════════════════════
  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_accentColor, _accentDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Iconsax.timer_1, color: Colors.white, size: 26),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Delivery Predictor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(3),
                Text(
                  'Accurate ETA based on real-world factors',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ═══════════════════════════════════════════
  // DELIVERY FORM (Distance + Prep Time)
  // ═══════════════════════════════════════════
  Widget _buildDeliveryForm() {
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
          Row(
            children: [
              const Icon(Iconsax.routing, color: _accentColor, size: 18),
              const Gap(8),
              Text(
                'Delivery Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const Gap(14),

          // Distance
          TextField(
            controller: _distanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Distance (km)',
              hintText: '5.0',
              prefixIcon: const Icon(Iconsax.location, size: 18),
              suffixText: 'km',
              suffixStyle: TextStyle(
                color: AppColors.textHint,
                fontSize: 13,
              ),
            ),
          ),
          const Gap(12),

          // Prep Time
          TextField(
            controller: _prepTimeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Preparation Time (minutes)',
              hintText: '20',
              prefixIcon: const Icon(Iconsax.clock, size: 18),
              suffixText: 'min',
              suffixStyle: TextStyle(
                color: AppColors.textHint,
                fontSize: 13,
              ),
            ),
          ),
          const Gap(14),

          // Quick distance buttons
          Text(
            'Quick Select Distance',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Gap(6),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [2.0, 5.0, 8.0, 10.0, 15.0, 20.0].map((d) {
                final isSelected = _distanceController.text == d.toString();
                return GestureDetector(
                  onTap: () {
                    setState(() => _distanceController.text = d.toString());
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? _accentColor : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? _accentColor : AppColors.border,
                      ),
                    ),
                    child: Text(
                      '${d.toStringAsFixed(0)} km',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  // ═══════════════════════════════════════════
  // CONDITIONS FORM
  // ═══════════════════════════════════════════
  Widget _buildConditionsForm() {
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
          Row(
            children: [
              const Icon(Iconsax.setting_2, color: _accentColor, size: 18),
              const Gap(8),
              Text(
                'Conditions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const Gap(14),

          // Weather
          _buildSectionLabel('Weather'),
          const Gap(6),
          _buildChipSelector(
            options: _weatherOptions,
            selectedValue: _selectedWeather,
            onSelect: (v) => setState(() => _selectedWeather = v),
          ),
          const Gap(14),

          // Traffic
          _buildSectionLabel('Traffic Level'),
          const Gap(6),
          _buildTrafficSelector(),
          const Gap(14),

          // Time of Day
          _buildSectionLabel('Time of Day'),
          const Gap(6),
          _buildTimeSelector(),
          const Gap(14),

          // Vehicle
          _buildSectionLabel('Vehicle Type'),
          const Gap(6),
          _buildChipSelector(
            options: _vehicleOptions,
            selectedValue: _selectedVehicle,
            onSelect: (v) => setState(() => _selectedVehicle = v),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
    );
  }

  Widget _buildChipSelector({
    required List<Map<String, dynamic>> options,
    required String selectedValue,
    required Function(String) onSelect,
  }) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = selectedValue == option['value'];

          return GestureDetector(
            onTap: () => onSelect(option['value'] as String),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _accentColor : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? _accentColor : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(option['emoji'] as String, style: const TextStyle(fontSize: 16)),
                  const Gap(6),
                  Text(
                    option['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrafficSelector() {
    return Row(
      children: _trafficOptions.map((option) {
        final isSelected = _selectedTraffic == option['value'];
        final color = option['color'] as Color;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTraffic = option['value'] as String),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? color : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(option['emoji'] as String, style: const TextStyle(fontSize: 20)),
                  const Gap(4),
                  Text(
                    option['label'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? color : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeSelector() {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _timeOptions.length,
        itemBuilder: (context, index) {
          final option = _timeOptions[index];
          final isSelected = _selectedTimeOfDay == option['value'];

          return GestureDetector(
            onTap: () => setState(() => _selectedTimeOfDay = option['value'] as String),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _accentColor : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? _accentColor : AppColors.border,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(option['emoji'] as String, style: const TextStyle(fontSize: 14)),
                      const Gap(4),
                      Text(
                        option['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Gap(2),
                  Text(
                    option['range'] as String,
                    style: TextStyle(
                      fontSize: 9,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════
  // PREDICT BUTTON
  // ═══════════════════════════════════════════
  Widget _buildPredictButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _predictETA,
        style: ElevatedButton.styleFrom(backgroundColor: _accentColor),
        child: _isLoading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.timer_1, size: 20),
            Gap(10),
            Text('Predict Delivery Time'),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }

  // ═══════════════════════════════════════════
  // ERROR + LOADING
  // ═══════════════════════════════════════════
  // Widget _buildErrorMessage() {
  //   return Container(
  //     width: double.infinity,
  //     margin: const EdgeInsets.only(bottom: 16),
  //     padding: const EdgeInsets.all(14),
  //     decoration: BoxDecoration(
  //       color: AppColors.errorLight,
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
  //     ),
  //     child: Row(
  //       children: [
  //         const Icon(Icons.error_outline, color: AppColors.error, size: 20),
  //         const Gap(10),
  //         Expanded(
  //           child: Text(
  //             _errorMessage!,
  //             style: const TextStyle(color: AppColors.error, fontSize: 13),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Widget _buildErrorMessage() {
    final isConnectionError =
        _errorMessage!.toLowerCase().contains('failed') ||
            _errorMessage!.toLowerCase().contains('backend');

    if (isConnectionError) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: NoConnectionCard(
          message: _errorMessage!,
          onRetry: _predictETA,
          isRetrying: _isLoading,
        ),
      );
    }

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
                      color: AppColors.error, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.1),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _accentLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: _accentColor, width: 2),
                    ),
                    child: const Icon(Iconsax.timer_1, color: _accentColor, size: 28),
                  ),
                );
              },
            ),
            const Gap(16),
            const Text(
              'Calculating delivery time...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ETA RESULT (big number)
  // ═══════════════════════════════════════════
  Widget _buildETAResult() {
    final eta = _result!['eta_minutes'] ?? 0;

    // Color based on ETA
    Color etaColor;
    String etaLabel;
    if (eta <= 25) {
      etaColor = const Color(0xFF10B981);
      etaLabel = 'Fast Delivery';
    } else if (eta <= 45) {
      etaColor = const Color(0xFFF59E0B);
      etaLabel = 'Standard Delivery';
    } else {
      etaColor = const Color(0xFFEF4444);
      etaLabel = 'Slow — Consider Closer Restaurant';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            etaColor.withValues(alpha: 0.08),
            etaColor.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: etaColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: etaColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: etaColor.withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(Iconsax.timer_1, color: etaColor, size: 36),
          ),
          const Gap(16),
          Text(
            '$eta',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              color: etaColor,
              height: 1,
            ),
          ),
          const Gap(4),
          Text(
            'minutes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: etaColor.withValues(alpha: 0.8),
            ),
          ),
          const Gap(10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: etaColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              etaLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: etaColor,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9));
  }

  // ═══════════════════════════════════════════
  // BREAKDOWN
  // ═══════════════════════════════════════════
  Widget _buildBreakdown() {
    final breakdown = _result!['breakdown'] as Map<String, dynamic>;
    final prepTime = breakdown['preparation'] ?? 0;
    final travelTime = breakdown['travel_estimate'] ?? 0;
    final distance = breakdown['distance_km'] ?? 0;
    final weather = breakdown['weather'] ?? 'clear';
    final traffic = breakdown['traffic'] ?? 'medium';

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
          Text('Time Breakdown', style: Theme.of(context).textTheme.titleLarge),
          const Gap(14),

          // Prep time
          _buildBreakdownRow(
            icon: Iconsax.clock,
            color: const Color(0xFFF59E0B),
            label: 'Preparation',
            value: '$prepTime min',
            percentage: prepTime / (prepTime + travelTime),
          ),
          const Gap(10),

          // Travel time
          _buildBreakdownRow(
            icon: Iconsax.routing,
            color: _accentColor,
            label: 'Travel ($distance km)',
            value: '$travelTime min',
            percentage: travelTime / (prepTime + travelTime),
          ),
          const Gap(14),
          const Divider(height: 1),
          const Gap(14),

          // Conditions used
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildConditionChip(
                _getWeatherEmoji(weather),
                weather.substring(0, 1).toUpperCase() + weather.substring(1),
              ),
              _buildConditionChip(
                _getTrafficEmoji(traffic),
                '$traffic traffic',
              ),
              _buildConditionChip(
                _getTimeEmoji(_selectedTimeOfDay),
                _selectedTimeOfDay.substring(0, 1).toUpperCase() +
                    _selectedTimeOfDay.substring(1),
              ),
              _buildConditionChip(
                _getVehicleEmoji(_selectedVehicle),
                _selectedVehicle.substring(0, 1).toUpperCase() +
                    _selectedVehicle.substring(1),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildBreakdownRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required double percentage,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const Gap(10),
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const Spacer(),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const Gap(6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage.clamp(0, 1),
            backgroundColor: AppColors.surfaceVariant,
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildConditionChip(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$emoji $label',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // VISUAL TIMELINE
  // ═══════════════════════════════════════════
  Widget _buildTimeline() {
    final breakdown = _result!['breakdown'] as Map<String, dynamic>;
    final prepTime = breakdown['preparation'] ?? 0;
    final travelTime = breakdown['travel_estimate'] ?? 0;
    final eta = _result!['eta_minutes'] ?? 0;

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
          Text('Delivery Timeline', style: Theme.of(context).textTheme.titleLarge),
          const Gap(16),

          // Timeline visual
          _buildTimelineStep(
            isFirst: true,
            isLast: false,
            color: const Color(0xFF10B981),
            title: 'Order Placed',
            subtitle: 'Now',
            icon: Iconsax.tick_circle,
          ),
          _buildTimelineStep(
            isFirst: false,
            isLast: false,
            color: const Color(0xFFF59E0B),
            title: 'Food Being Prepared',
            subtitle: '0 - $prepTime min',
            icon: Iconsax.clock,
          ),
          _buildTimelineStep(
            isFirst: false,
            isLast: false,
            color: _accentColor,
            title: 'Out for Delivery',
            subtitle: '$prepTime - $eta min',
            icon: Iconsax.routing,
          ),
          _buildTimelineStep(
            isFirst: false,
            isLast: true,
            color: const Color(0xFF8B5CF6),
            title: 'Delivered',
            subtitle: '~$eta min',
            icon: Iconsax.home_2,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }

  Widget _buildTimelineStep({
    required bool isFirst,
    required bool isLast,
    required Color color,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Timeline line + dot
          SizedBox(
            width: 36,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(child: Container(width: 2, color: color.withValues(alpha: 0.3))),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: color.withValues(alpha: 0.3))),
              ],
            ),
          ),
          const Gap(12),

          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // CONFIDENCE CARD
  // ═══════════════════════════════════════════
  Widget _buildConfidenceCard() {
    final confidence = ((_result!['confidence'] as num) * 100).toInt();
    final rmse = (_result!['model_rmse'] as num).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accentLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.info_circle, color: _accentColor, size: 18),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Model Confidence: $confidence%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _accentDark,
                  ),
                ),
                Text(
                  'Average error: ±${rmse.toStringAsFixed(1)} minutes',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 400.ms);
  }

  // ═══════════════════════════════════════════
  // HELPER METHODS (emoji lookups)
  // ═══════════════════════════════════════════
  String _getWeatherEmoji(String weather) {
    switch (weather.toLowerCase()) {
      case 'clear': return '☀️';
      case 'rainy': return '🌧️';
      case 'foggy': return '🌫️';
      case 'windy': return '💨';
      case 'snowy': return '❄️';
      default: return '☀️';
    }
  }

  String _getTrafficEmoji(String traffic) {
    switch (traffic.toLowerCase()) {
      case 'low': return '🟢';
      case 'medium': return '🟡';
      case 'high': return '🔴';
      default: return '🟡';
    }
  }

  String _getTimeEmoji(String time) {
    switch (time.toLowerCase()) {
      case 'morning': return '🌅';
      case 'afternoon': return '☀️';
      case 'evening': return '🌆';
      case 'night': return '🌙';
      default: return '🌆';
    }
  }

  String _getVehicleEmoji(String vehicle) {
    switch (vehicle.toLowerCase()) {
      case 'bicycle': return '🚲';
      case 'bike': return '🏍️';
      case 'scooter': return '🛵';
      case 'car': return '🚗';
      default: return '🏍️';
    }
  }
}