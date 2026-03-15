import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/glass_card.dart';

class AnalyticsTab extends StatelessWidget {
  final Map<String, dynamic>? solution;
  final Map<String, dynamic>? inputData;

  const AnalyticsTab({super.key, this.solution, this.inputData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = solution?['data'] as Map<String, dynamic>? ?? {};
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final routes = solution?['routes'] as List? ?? [];

    double baselineTotal = 0;
    for (final route in routes) {
      baselineTotal += ((route as Map)['baselineCost'] ?? 0).toDouble();
    }
    
    if (baselineTotal == 0) {
      final baselineList = inputData?['baseline'] as List? ?? [];
      for (final b in baselineList) {
        baselineTotal += ((b as Map)['baseline_cost'] ?? (b)['baselineCost'] ?? 0).toDouble();
      }
    }

    final optimizedCost = (summary['totalMoneyCost'] ?? 0).toDouble();
    final savings = baselineTotal > 0 ? baselineTotal - optimizedCost : 0.0;
    final savingsPct = baselineTotal > 0 ? (savings / baselineTotal * 100) : 0.0;
    final globalCost = (summary['globalCost'] ?? optimizedCost).toDouble();
    final penaltyCost = globalCost - optimizedCost;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.savings_rounded,
                        size: 20, color: AppTheme.darkAccent),
                    const SizedBox(width: 8),
                    Text(
                      'Economic Efficiency',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (baselineTotal > 0) ...[
                  _costRow('Baseline (Individual)', formatCurrency(baselineTotal),
                      Colors.grey, isDark),
                  const SizedBox(height: 8),
                  _costRow('Velora Optimized', formatCurrency(optimizedCost),
                      AppTheme.darkAccent, isDark),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.darkAccent.withValues(alpha: 0.1),
                          AppTheme.darkAccent.withValues(alpha: 0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppTheme.darkAccent.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: savingsPct.clamp(0, 100) / 100,
                                strokeWidth: 6,
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.1),
                                color: AppTheme.darkAccent,
                              ),
                              Text(
                                '${savingsPct.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.darkAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cost Savings',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.5)
                                      : Colors.black.withValues(alpha: 0.5),
                                ),
                              ),
                              Text(
                                '${formatCurrency(savings)} saved',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.darkAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Center(
                    child: Column(
                      children: [
                        Text(
                          formatCurrency(optimizedCost),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.darkPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Velora Optimized Cost',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No baseline data available for comparison',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.black.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics_rounded,
                        size: 20, color: AppTheme.darkPrimary),
                    const SizedBox(width: 8),
                    Text(
                      'Operational Metrics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _metricRow(Icons.local_gas_station_rounded, 'Fuel & Distance Cost',
                    formatCurrency(optimizedCost), AppTheme.darkPrimary, isDark),
                _metricRow(
                    Icons.warning_rounded,
                    'Constraint Penalties',
                    penaltyCost > 0 ? formatCurrency(penaltyCost) : '₹0 (None)',
                    penaltyCost > 0
                        ? const Color(0xFFF59E0B)
                        : AppTheme.darkAccent,
                    isDark),
                _metricRow(
                    Icons.directions_car_rounded,
                    'Fleet Utilization',
                    '${summary['vehiclesUsed'] ?? routes.length} active',
                    AppTheme.darkSecondary,
                    isDark),
                _metricRow(
                    Icons.person_off_rounded,
                    'Unassigned Assets',
                    '${summary['unassignedCount'] ?? 0}',
                    summary['unassignedCount'] != null &&
                            (summary['unassignedCount'] as num) > 0
                        ? const Color(0xFFEF4444)
                        : AppTheme.darkAccent,
                    isDark),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _smallMetric(
                        'Total Distance',
                        '${((summary['totalDistance'] ?? 0) as num).toStringAsFixed(1)} km',
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _smallMetric(
                        'Total Time',
                        '${((summary['totalTime'] ?? 0) as num).toStringAsFixed(0)} min',
                        isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.functions_rounded,
                        size: 20, color: AppTheme.darkSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Objective Function',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _objRow('Transport Cost', formatCurrency(optimizedCost), isDark),
                      if (penaltyCost > 0)
                        _objRow('+ Penalties', formatCurrency(penaltyCost), isDark),
                      Divider(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.1),
                      ),
                      _objRow(
                        'Global Cost',
                        formatCurrency(globalCost),
                        isDark,
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _costRow(
      String label, String value, Color color, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _metricRow(
      IconData icon, String label, String value, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallMetric(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _objRow(String label, String value, bool isDark, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: bold ? 0.9 : 0.5)
                  : Colors.black.withValues(alpha: bold ? 0.9 : 0.5),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 16 : 13,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
              color: bold
                  ? AppTheme.darkPrimary
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
