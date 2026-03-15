import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/metric_card.dart';

class RoutesTab extends StatelessWidget {
  final Map<String, dynamic>? solution;
  final Map<String, dynamic>? inputData;

  const RoutesTab({super.key, this.solution, this.inputData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = solution?['data'] as Map<String, dynamic>? ?? {};
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final routes = solution?['routes'] as List? ?? [];
    final unassigned = solution?['unassigned'] as List? ?? [];
    final constraintAnalysis = data['constraintAnalysis'] as List? ?? [];

    // Constraint counts
    int onTimeCount = 0, toleranceCount = 0, violatedCount = 0;
    int vehPrefViolations = 0, sharingViolations = 0;
    for (final ca in constraintAnalysis) {
      final m = ca as Map<String, dynamic>;
      switch (m['overallStatus']) {
        case 'on_time':
          onTimeCount++;
          break;
        case 'within_tolerance':
          toleranceCount++;
          break;
        case 'violated':
          violatedCount++;
          break;
      }
      if (m['vehiclePrefViolated'] == true) vehPrefViolations++;
      if (m['sharingViolated'] == true) sharingViolations++;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Constraint Compliance
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Constraint Compliance',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _complianceRow('On Time', onTimeCount,
                    const Color(0xFF10B981), isDark),
                _complianceRow('Within Tolerance', toleranceCount,
                    const Color(0xFFF59E0B), isDark),
                _complianceRow('Violated', violatedCount,
                    const Color(0xFFEF4444), isDark),
                _complianceRow('Unassigned', unassigned.length,
                    const Color(0xFF6B7280), isDark),
                if (vehPrefViolations > 0)
                  _complianceRow('Vehicle Pref Violations', vehPrefViolations,
                      const Color(0xFFEF4444), isDark),
                if (sharingViolations > 0)
                  _complianceRow('Sharing Violations', sharingViolations,
                      const Color(0xFFEF4444), isDark),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Operational Metrics
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  icon: Icons.attach_money_rounded,
                  iconColor: AppTheme.darkAccent,
                  label: 'TOTAL COST',
                  value: formatCurrency(summary['totalMoneyCost']),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MetricCard(
                  icon: Icons.route_rounded,
                  iconColor: AppTheme.darkPrimary,
                  label: 'DISTANCE',
                  value: ((summary['totalDistance'] ?? 0) as num)
                      .toStringAsFixed(1),
                  suffix: 'km',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  icon: Icons.directions_car_rounded,
                  iconColor: AppTheme.darkSecondary,
                  label: 'VEHICLES',
                  value: '${summary['vehiclesUsed'] ?? routes.length}',
                  suffix: 'active',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MetricCard(
                  icon: Icons.schedule_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  label: 'TRAVEL TIME',
                  value: ((summary['totalTime'] ?? 0) as num)
                      .toStringAsFixed(0),
                  suffix: 'min',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Vehicle Dispatch Manifest header
          Text(
            'Vehicle Dispatch Manifest',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          // Route cards
          ...routes.asMap().entries.map((entry) {
            final idx = entry.key;
            final route = entry.value as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RouteCard(route: route, index: idx, isDark: isDark),
            );
          }),
          // Unassigned section
          if (unassigned.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Unassigned Requests (${unassigned.length})',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 8),
            ...unassigned.map((u) {
              final item = u is Map ? u : {'reqId': u};
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.person_off_rounded,
                          size: 18, color: const Color(0xFFEF4444)),
                      const SizedBox(width: 10),
                      Text(
                        item['employeeId']?.toString() ??
                            'Req ${item['reqId']}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      if (item['priority'] != null)
                        Text(
                          'P${item['priority']}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _complianceRow(String label, int count, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatefulWidget {
  final Map<String, dynamic> route;
  final int index;
  final bool isDark;

  const _RouteCard(
      {required this.route, required this.index, required this.isDark});

  @override
  State<_RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<_RouteCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final isDark = widget.isDark;
    final vId = route['vehicleIdStr'] ?? route['vehicleId']?.toString() ?? 'V${widget.index}';
    final type = route['vehicleType'] ?? '4w';
    final fuelType = route['fuelType'] ?? '';
    final stops = route['stops'] as List? ?? [];
    final totalDist = (route['totalDist'] ?? 0).toDouble();
    final totalTime = (route['totalTime'] ?? 0).toDouble();
    final capacity = route['capacity'] ?? 4;
    final costPerKm = route['costPerKm'] ?? 15;
    final routeColor = Color(vehicleColorValues[widget.index % vehicleColorValues.length]);

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: routeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.local_shipping_rounded,
                            size: 18, color: routeColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  vId,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _badge(type, routeColor),
                                if (fuelType.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  _badge(fuelType, Colors.grey),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${totalDist.toStringAsFixed(1)} km  •  ${totalTime.toStringAsFixed(0)} min  •  ${stops.length} stops',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Colors.black.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Vehicle details strip
                  Row(
                    children: [
                      _detailChip('₹$costPerKm/km', isDark),
                      const SizedBox(width: 6),
                      _detailChip('Cap: $capacity', isDark),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Expanded: Stop table
          if (_expanded && stops.isNotEmpty)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.02)
                    : Colors.black.withValues(alpha: 0.02),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  horizontalMargin: 16,
                  headingRowHeight: 36,
                  dataRowMinHeight: 32,
                  dataRowMaxHeight: 40,
                  headingTextStyle: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.black.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                  dataTextStyle: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  columns: const [
                    DataColumn(label: Text('TYPE')),
                    DataColumn(label: Text('REQ')),
                    DataColumn(label: Text('EMPLOYEE')),
                    DataColumn(label: Text('ARRIVAL')),
                    DataColumn(label: Text('WAIT')),
                  ],
                  rows: stops.map<DataRow>((stop) {
                    final s = stop as Map<String, dynamic>;
                    final sType =
                        (s['type'] == 'pickup' || s['type'] == 'P')
                            ? '🏠 Pickup'
                            : (s['type'] == 'dropoff' || s['type'] == 'D')
                                ? '🏢 Dropoff'
                                : s['type'] ?? '-';
                    return DataRow(cells: [
                      DataCell(Text(sType)),
                      DataCell(Text('${s['reqId'] ?? '-'}')),
                      DataCell(Text(
                          s['employeeId']?.toString() ?? '-')),
                      DataCell(Text(formatTime(s['arrivalTime']))),
                      DataCell(Text(
                        (s['waitTime'] != null &&
                                (s['waitTime'] as num) > 0)
                            ? '${(s['waitTime'] as num).toStringAsFixed(1)}m'
                            : '-',
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _detailChip(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isDark
              ? Colors.white.withValues(alpha: 0.4)
              : Colors.black.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
