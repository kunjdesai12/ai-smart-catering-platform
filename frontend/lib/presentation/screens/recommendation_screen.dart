import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/widgets/no_connection_card.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/api_service.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  static const Color _accent = Color(0xFF0D9488);
  static const Color _accentLight = Color(0xFFCCFBF1);
  static const Color _accentDark = Color(0xFF0F766E);

  // Location
  List<Map<String, dynamic>> _countries = [];
  String? _selectedCountry;
  List<Map<String, dynamic>> _citiesForCountry = [];
  String? _selectedCity;
  bool _isLoadingLocations = true;

  // Form
  final _peopleController = TextEditingController(text: '50');
  final _budgetController = TextEditingController(text: '500');
  String _selectedCuisine = 'north indian';
  double _minRating = 3.5;
  int _currentTopN = 5;

  // State
  bool _isLoading = false;
  bool _isLoadingMore = false;
  List<dynamic> _recommendations = [];
  Map<String, dynamic>? _result;
  String? _errorMessage;
  int? _selectedCardIndex;
  int? _totalMatches;

  final List<Map<String, dynamic>> _cuisines = [
    {'value': 'north indian', 'label': 'North Indian', 'emoji': '🍛'},
    {'value': 'south indian', 'label': 'South Indian', 'emoji': '🥘'},
    {'value': 'chinese', 'label': 'Chinese', 'emoji': '🥡'},
    {'value': 'italian', 'label': 'Italian', 'emoji': '🍕'},
    {'value': 'mughlai', 'label': 'Mughlai', 'emoji': '🍖'},
    {'value': 'fast food', 'label': 'Fast Food', 'emoji': '🍔'},
    {'value': 'biryani', 'label': 'Biryani', 'emoji': '🍚'},
    {'value': 'desserts', 'label': 'Desserts', 'emoji': '🍰'},
    {'value': 'seafood', 'label': 'Seafood', 'emoji': '🦐'},
    {'value': 'continental', 'label': 'Continental', 'emoji': '🥗'},
  ];

  final _priceLabels = ['', '₹', '₹₹', '₹₹₹', '₹₹₹₹'];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void dispose() {
    _peopleController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    debugPrint('🔄 Loading locations...');
    setState(() => _isLoadingLocations = true);

    final locations = await ApiService.getLocations();

    debugPrint('📍 Locations received: ${locations.length} countries');
    for (var c in locations) {
      debugPrint('   🌍 ${c['country']}: ${c['total_restaurants']} restaurants');
    }

    if (mounted) {
      setState(() {
        _countries = locations;
        _isLoadingLocations = false;
      });
    }
  }

  void _onCountrySelected(String country) {
    debugPrint('🌍 Country selected: $country');
    final countryData = _countries.firstWhere(
          (c) => c['country'] == country,
      orElse: () => {'cities': []},
    );

    final cities = List<Map<String, dynamic>>.from(
      countryData['cities'] ?? [],
    );

    debugPrint('🏙 Cities available: ${cities.length}');

    setState(() {
      _selectedCountry = country;
      _citiesForCountry = cities;
      _selectedCity = null;
      _recommendations = [];
      _result = null;
    });
  }

  void _onCitySelected(String city) {
    debugPrint('🏙 City selected: $city');
    setState(() {
      _selectedCity = city;
      _recommendations = [];
      _result = null;
    });
  }

  Future<void> _getRecommendations({bool loadMore = false}) async {
    final people = int.tryParse(_peopleController.text);
    final budget = double.tryParse(_budgetController.text);

    if (people == null || people <= 0) {
      setState(() => _errorMessage = 'Enter valid number of people');
      return;
    }
    if (budget == null || budget <= 0) {
      setState(() => _errorMessage = 'Enter valid budget per person');
      return;
    }

    if (loadMore) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _result = null;
        _recommendations = [];
        _selectedCardIndex = null;
        _currentTopN = 5;
      });
    }

    final topN = loadMore ? _currentTopN + 5 : _currentTopN;

    debugPrint('🔮 Getting recommendations...');
    debugPrint('   Cuisine: $_selectedCuisine');
    debugPrint('   Budget: $budget/person, $people people');
    debugPrint('   Location: $_selectedCity, $_selectedCountry');

    final result = await ApiService.getRecommendations(
      cuisine: _selectedCuisine,
      budgetPerPerson: budget,
      numPeople: people,
      minRating: _minRating,
      topN: topN,
      city: _selectedCity,
      country: _selectedCountry,
    );

    debugPrint('📨 Result received: ${result != null}');
    if (result != null) {
      debugPrint('   Matches: ${result['total_matches']}');
      final recs = result['recommendations'] ?? [];
      debugPrint('   Recommendations: ${recs.length}');
      for (var r in recs) {
        debugPrint('   ⭐ ${r['name']} — ₹${r['cost_per_person']}/person');
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        if (result != null) {
          _result = result;
          _recommendations =
          List<dynamic>.from(result['recommendations'] ?? []);
          _totalMatches = result['total_matches'] as int?;
          _currentTopN = topN;
        } else {
          _errorMessage = 'Failed. Is backend running?';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Recommendations'),
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
            _buildHeader(),
            const Gap(16),
            _buildStepIndicator(),
            const Gap(16),
            _buildLocationSection(),
            if (_selectedCity != null) ...[
              const Gap(12),
              _buildBudgetSection(),
              const Gap(12),
              _buildCuisineSection(),
              const Gap(16),
              _buildButton(),
            ],
            const Gap(16),
            if (_errorMessage != null) _buildError(),
            if (_isLoading) _buildLoading(),
            if (_recommendations.isNotEmpty && !_isLoading) ...[
              _buildSummary(),
              const Gap(14),
              _buildList(),
              const Gap(14),
              if (_totalMatches != null &&
                  _recommendations.length < _totalMatches!)
                _buildLoadMore(),
            ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_accent, _accentDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.3),
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
            child: const Icon(Iconsax.magic_star,
                color: Colors.white, size: 26),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI-Powered Matching',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const Gap(3),
                Text('Find the perfect restaurant for your event',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ═══════════════════════════════════════════
  // STEP INDICATOR
  // ═══════════════════════════════════════════
  Widget _buildStepIndicator() {
    int step = 0;
    if (_selectedCountry != null) step = 1;
    if (_selectedCity != null) step = 2;
    if (_recommendations.isNotEmpty) step = 3;

    return Row(
      children: [
        _stepDot('Location', 0, step),
        _stepLine(step >= 1),
        _stepDot('Budget', 1, step),
        _stepLine(step >= 2),
        _stepDot('Cuisine', 2, step),
        _stepLine(step >= 3),
        _stepDot('Results', 3, step),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _stepDot(String label, int s, int current) {
    final active = current >= s;
    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: active ? _accent : AppColors.surfaceVariant,
            shape: BoxShape.circle,
            border: Border.all(
                color: active ? _accent : AppColors.border, width: 2),
          ),
          child: Center(
            child: active
                ? const Icon(Icons.check, color: Colors.white, size: 13)
                : Text('${s + 1}',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textHint)),
          ),
        ),
        const Gap(4),
        Text(label,
            style: TextStyle(
                fontSize: 9,
                color: active ? _accent : AppColors.textHint,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
      ],
    );
  }

  Widget _stepLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: active ? _accent : AppColors.border,
      ),
    );
  }

  // ═══════════════════════════════════════════
  // LOCATION
  // ═══════════════════════════════════════════
  Widget _buildLocationSection() {
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
              const Icon(Iconsax.global, color: _accent, size: 18),
              const Gap(8),
              Text('Step 1: Select Location',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const Gap(12),
          if (_isLoadingLocations)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child:
                CircularProgressIndicator(strokeWidth: 2, color: _accent),
              ),
            )
          else ...[
            DropdownButtonFormField<String>(
              value: _selectedCountry,
              isExpanded: true,
              decoration: const InputDecoration(
                hintText: 'Select Country',
                prefixIcon: Icon(Iconsax.flag, size: 18),
              ),
              items: _countries.map((c) {
                return DropdownMenuItem(
                  value: c['country'] as String,
                  child: Text(
                    '${c['country']} (${c['total_restaurants']} restaurants)',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) _onCountrySelected(v);
              },
            ),
            if (_selectedCountry != null) ...[
              const Gap(12),
              DropdownButtonFormField<String>(
                value: _selectedCity,
                isExpanded: true,
                decoration: const InputDecoration(
                  hintText: 'Select City',
                  prefixIcon: Icon(Iconsax.building, size: 18),
                ),
                items: _citiesForCountry.map((c) {
                  return DropdownMenuItem(
                    value: c['city'] as String,
                    child: Text(
                      '${c['city']} (${c['restaurant_count']})',
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) _onCitySelected(v);
                },
              ),
            ],
            if (_selectedCity != null) ...[
              const Gap(10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _accentLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.location,
                        color: _accent, size: 16),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        '$_selectedCity, $_selectedCountry',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _accentDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ═══════════════════════════════════════════
  // BUDGET
  // ═══════════════════════════════════════════
  Widget _buildBudgetSection() {
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
              const Icon(Iconsax.wallet_1,
                  color: Color(0xFFF59E0B), size: 18),
              const Gap(8),
              Text('Step 2: Event Size & Budget',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _peopleController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Guests',
                    hintText: '50',
                    prefixIcon: Icon(Iconsax.people, size: 18),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const Gap(12),
              Expanded(
                child: TextField(
                  controller: _budgetController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '₹ / Person',
                    hintText: '500',
                    prefixIcon: Icon(Iconsax.money, size: 18),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const Gap(12),
          Builder(
            builder: (context) {
              final p = int.tryParse(_peopleController.text) ?? 0;
              final b = double.tryParse(_budgetController.text) ?? 0;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.wallet_1,
                        color: Color(0xFFD97706), size: 16),
                    const Gap(8),
                    Text(
                      'Total: ₹${(p * b).toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E)),
                    ),
                    const Spacer(),
                    Text('$p × ₹${b.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFD97706))),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }

  // ═══════════════════════════════════════════
  // CUISINE
  // ═══════════════════════════════════════════
  Widget _buildCuisineSection() {
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
              const Icon(Iconsax.cake, color: Color(0xFFEC4899), size: 18),
              const Gap(8),
              Text('Step 3: Cuisine',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const Gap(12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _cuisines.length,
              itemBuilder: (context, index) {
                final c = _cuisines[index];
                final sel = _selectedCuisine == c['value'];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedCuisine = c['value'] as String),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: sel ? _accent : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: sel ? _accent : AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(c['emoji'] as String,
                            style: const TextStyle(fontSize: 15)),
                        const Gap(5),
                        Text(c['label'] as String,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: sel
                                    ? Colors.white
                                    : AppColors.textPrimary)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Gap(14),
          Row(
            children: [
              const Text('Min Rating',
                  style:
                  TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('⭐ ${_minRating.toStringAsFixed(1)}+',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          Slider(
            value: _minRating,
            min: 2.0,
            max: 4.5,
            divisions: 5,
            activeColor: _accent,
            inactiveColor: AppColors.border,
            onChanged: (v) => setState(() => _minRating = v),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms);
  }

  // ═══════════════════════════════════════════
  // BUTTON
  // ═══════════════════════════════════════════
  Widget _buildButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _getRecommendations(),
        style: ElevatedButton.styleFrom(backgroundColor: _accent),
        child: _isLoading
            ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: Colors.white))
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.magic_star, size: 20),
            Gap(10),
            Text('Get AI Recommendations'),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 300.ms);
  }

  Widget _buildLoadMore() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed:
        _isLoadingMore ? null : () => _getRecommendations(loadMore: true),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _accent),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoadingMore
            ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: _accent))
            : Text(
            'Load More (${_recommendations.length} of $_totalMatches)',
            style: const TextStyle(
                color: _accent, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // Widget _buildError() {
  //   return Container(
  //     width: double.infinity,
  //     margin: const EdgeInsets.only(bottom: 16),
  //     padding: const EdgeInsets.all(14),
  //     decoration: BoxDecoration(
  //       color: AppColors.errorLight,
  //       borderRadius: BorderRadius.circular(12),
  //       border:
  //       Border.all(color: AppColors.error.withValues(alpha: 0.3)),
  //     ),
  //     child: Row(
  //       children: [
  //         const Icon(Icons.error_outline,
  //             color: AppColors.error, size: 20),
  //         const Gap(10),
  //         Expanded(
  //             child: Text(_errorMessage!,
  //                 style: const TextStyle(
  //                     color: AppColors.error, fontSize: 13))),
  //       ],
  //     ),
  //   );
  // }
  Widget _buildError() {
    final isConnectionError =
        _errorMessage!.toLowerCase().contains('failed') ||
            _errorMessage!.toLowerCase().contains('backend');

    if (isConnectionError) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: NoConnectionCard(
          message: _errorMessage!,
          onRetry: () => _getRecommendations(),
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            CircularProgressIndicator(color: _accent),
            Gap(16),
            Text('Finding best restaurants...',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // SUMMARY
  // ═══════════════════════════════════════════
  Widget _buildSummary() {
    final q = _result!['query'] as Map<String, dynamic>;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accentLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.search_normal_1,
                  color: _accent, size: 18),
              const Gap(8),
              Text('$_totalMatches restaurants matched',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _accentDark)),
            ],
          ),
          const Gap(8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip('📍 ${q['city'] ?? 'All'}'),
              _chip('🍽 ${q['cuisine']}'),
              _chip('👥 ${q['num_people']} people'),
              _chip('💰 ₹${q['budget_per_person']}/person'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _accent.withValues(alpha: 0.2)),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }

  // ═══════════════════════════════════════════
  // LIST
  // ═══════════════════════════════════════════
  Widget _buildList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top ${_recommendations.length} Recommendations',
            style: Theme.of(context).textTheme.titleLarge)
            .animate()
            .fadeIn(duration: 300.ms),
        const Gap(12),
        ..._recommendations.asMap().entries.map((entry) {
          final i = entry.key;
          final r = entry.value as Map<String, dynamic>;
          final exp = _selectedCardIndex == i;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCard(r, i + 1, exp, i)
                .animate()
                .fadeIn(
                duration: 400.ms,
                delay: Duration(milliseconds: 80 * i))
                .slideY(begin: 0.03),
          );
        }),
      ],
    );
  }

  Widget _buildCard(
      Map<String, dynamic> r,
      int rank,
      bool expanded,
      int index,
      ) {
    final match = ((r['match_score'] ?? 0) as num).toDouble() * 100;
    final menu = List<String>.from(r['suggested_menu'] ?? []);
    final rating = r['rating'] ?? 0;
    final priceRange = (r['price_range'] ?? 2) as int;
    final name = r['name'] ?? 'Restaurant #${r['restaurant_id']}';
    final city = r['city'] ?? '';
    final country = r['country'] ?? '';
    final costPerPerson = r['cost_per_person'] ?? 0;
    final estimatedCost = r['estimated_cost'] ?? 0;
    final cuisineMatch =
        ((r['cuisine_match'] ?? 0) as num).toDouble() * 100;

    String rankEmoji = rank == 1
        ? '🥇'
        : rank == 2
        ? '🥈'
        : rank == 3
        ? '🥉'
        : '#$rank';

    return GestureDetector(
      onTap: () => setState(() {
        _selectedCardIndex = expanded ? null : index;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: expanded
                ? _accent.withValues(alpha: 0.4)
                : rank == 1
                ? const Color(0xFFFFD700).withValues(alpha: 0.4)
                : AppColors.border,
            width: expanded || rank == 1 ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _accentLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                      child: Text(rankEmoji,
                          style: const TextStyle(fontSize: 16))),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(2),
                      Text(
                        '${r['primary_cuisine'] ?? ''}'
                            '${city.isNotEmpty ? " • $city" : ""}'
                            '${country.isNotEmpty ? ", $country" : ""}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textHint),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: match >= 70
                        ? _accentLight
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${match.toInt()}%',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: match >= 70
                              ? _accentDark
                              : AppColors.textSecondary)),
                ),
                const Gap(6),
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: AppColors.textHint,
                  size: 22,
                ),
              ],
            ),
            const Gap(10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _rChip('⭐ $rating'),
                _rChip(_priceLabels[priceRange.clamp(1, 4)]),
                _rChip('₹$costPerPerson/person'),
              ],
            ),
            if (expanded) ...[
              const Gap(14),
              const Divider(height: 1),
              const Gap(14),
              _detail('Cuisine Match', '${cuisineMatch.toInt()}%'),
              _detail('Total Cost', '₹$estimatedCost'),
              if (city.isNotEmpty)
                _detail('Location',
                    '$city${country.isNotEmpty ? ", $country" : ""}'),
              const Gap(12),
              if (menu.isNotEmpty) ...[
                const Text('Suggested Menu',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                const Gap(6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: menu
                      .map((item) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                      border:
                      Border.all(color: AppColors.border),
                    ),
                    child: Text(item,
                        style: const TextStyle(fontSize: 11)),
                  ))
                      .toList(),
                ),
                const Gap(14),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showSummary(r),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Iconsax.tick_circle,
                      size: 18, color: Colors.white),
                  label: const Text('Select for Event',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _rChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style:
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // SHOW SUMMARY POPUP
  // ═══════════════════════════════════════════
  void _showSummary(Map<String, dynamic> r) {
    final people = int.tryParse(_peopleController.text) ?? 50;
    final menu = List<String>.from(r['suggested_menu'] ?? []);
    final name = r['name'] ?? 'Restaurant #${r['restaurant_id']}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Gap(20),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: _accentLight,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Iconsax.tick_circle,
                      color: _accent, size: 24),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Event Summary',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      Text('Restaurant Selected',
                          style: TextStyle(fontSize: 12, color: _accentDark)),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(20),
            _sRow('Restaurant', name, Iconsax.shop),
            _sRow('Cuisine', r['primary_cuisine'] ?? '', Iconsax.cake),
            _sRow('Location',
                '${r['city'] ?? ''}, ${r['country'] ?? ''}', Iconsax.location),
            _sRow('Rating', '⭐ ${r['rating']}', Iconsax.star_1),
            _sRow('Guests', '$people people', Iconsax.people),
            _sRow('Cost/Person', '₹${r['cost_per_person']}', Iconsax.money),
            const Gap(12),
            const Divider(),
            const Gap(12),
            Row(
              children: [
                const Text('Total Estimated Cost',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('₹${r['estimated_cost']}',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _accent)),
              ],
            ),
            const Gap(16),
            if (menu.isNotEmpty) ...[
              const Text('Suggested Menu',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const Gap(8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: menu
                    .map((item) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: _accentLight,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(item,
                      style: const TextStyle(
                          fontSize: 11,
                          color: _accentDark,
                          fontWeight: FontWeight.w500)),
                ))
                    .toList(),
              ),
            ],
            const Gap(20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Back',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
                const Gap(12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ $name selected!'),
                          backgroundColor: _accent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Confirm Selection',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const Gap(10),
          ],
        ),
      ),
    );
  }

  Widget _sRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textHint, size: 18),
          const Gap(10),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Flexible(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}