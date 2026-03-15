import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';

class EmployeesTab extends StatelessWidget {
  final Map<String, dynamic>? solution;
  final Map<String, dynamic>? inputData;

  const EmployeesTab({super.key, this.solution, this.inputData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = solution?['data'] as Map<String, dynamic>? ?? {};
    final constraintAnalysis =
        data['constraintAnalysis'] as List? ?? [];
    final routes = solution?['routes'] as List? ?? [];

    List<Map<String, dynamic>> employees;
    if (constraintAnalysis.isNotEmpty) {
      employees = constraintAnalysis.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      employees = _buildFromRoutes(routes);
    }

    employees.sort((a, b) {
      final aId = a['employeeId']?.toString() ?? '';
      final bId = b['employeeId']?.toString() ?? '';
      return aId.compareTo(bId);
    });

    if (employees.isEmpty) {
      return Center(
        child: Text(
          'No employee data available',
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      );
    }

    int onTime = 0, withinTolerance = 0, violated = 0, unassigned = 0;
    for (final e in employees) {
      switch (e['overallStatus']) {
        case 'on_time':
          onTime++;
          break;
        case 'within_tolerance':
          withinTolerance++;
          break;
        case 'violated':
          violated++;
          break;
        case 'unassigned':
          unassigned++;
          break;
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _countBadge('On Time', onTime, const Color(0xFF10B981), isDark),
              _countBadge('Tolerance', withinTolerance, const Color(0xFFF59E0B), isDark),
              _countBadge('Violated', violated, const Color(0xFFEF4444), isDark),
              if (unassigned > 0)
                _countBadge('Unassigned', unassigned, const Color(0xFF6B7280), isDark),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: employees.length,
            itemBuilder: (ctx, idx) =>
                _buildEmployeeCard(context, employees[idx], isDark, idx),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _buildFromRoutes(List routes) {
    final employees = <Map<String, dynamic>>[];
    for (final route in routes) {
      final stops = route['stops'] as List? ?? [];
      final empStops = <String, Map<String, dynamic>>{};

      for (final stop in stops) {
        final empId = stop['employeeId'] ?? 'Req-${stop['reqId']}';
        empStops.putIfAbsent(empId, () => {});
        if (stop['type'] == 'pickup' || stop['type'] == 'P') {
          empStops[empId]!['pickup'] = stop;
        } else if (stop['type'] == 'dropoff' || stop['type'] == 'D') {
          empStops[empId]!['dropoff'] = stop;
        }
      }

      for (final entry in empStops.entries) {
        employees.add({
          'employeeId': entry.key,
          'assignedVehicleId':
              route['vehicleIdStr'] ?? route['vehicleId']?.toString(),
          'assignedVehicleType': route['vehicleType'] ?? '4w',
          'fuelType': route['fuelType'] ?? '',
          'effectivePickupTime': entry.value['pickup']?['arrivalTime'],
          'dropoffArrival': entry.value['dropoff']?['arrivalTime'],
          'vehicleWaitTime': entry.value['pickup']?['waitTime'] ?? 0,
          'overallStatus': 'on_time',
          'priority': 3,
          'notes': [],
        });
      }
    }
    return employees;
  }

  Widget _countBadge(String label, int count, Color color, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeCard(
      BuildContext context, Map<String, dynamic> emp, bool isDark, int index) {
    final empId = emp['employeeId'] ?? 'Unknown';
    final vehicleId = emp['assignedVehicleId'] ?? '-';
    final vehicleType = emp['assignedVehicleType'] ?? '4w';
    final fuelType = emp['fuelType'] ?? '';
    final overallStatus = emp['overallStatus'] ?? 'on_time';
    final int priority = (emp['priority'] ?? 3) as int;
    final pickupTime = emp['effectivePickupTime'];
    final dropoffTime = emp['dropoffArrival'];
    final num waitTime = (emp['vehicleWaitTime'] ?? 0) as num;
    final earlyTime = emp['earlyTime'];
    final lateTime = emp['lateTime'];
    final notes = emp['notes'] as List? ?? [];
    final vehiclePrefViolated = emp['vehiclePrefViolated'] == true;
    final sharingViolated = emp['sharingViolated'] == true;

    double? duration;
    if (pickupTime != null && dropoffTime != null) {
      duration = (dropoffTime as num).toDouble() - (pickupTime as num).toDouble();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.darkPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      empId.toString().substring(0, empId.toString().length.clamp(0, 2)),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppTheme.darkPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        empId.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.directions_car_rounded,
                            size: 11,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vehicleId.toString(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : Colors.black.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _typeBadge(vehicleType, isDark, isVehicleType: true),
                          if (fuelType.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            _fuelTypeBadge(fuelType, isDark),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: overallStatus),
              ],
            ),
            if (vehiclePrefViolated)
              _violationBanner(
                Icons.directions_car_rounded,
                'Vehicle preference violated',
                const Color(0xFFEF4444),
                isDark,
              ),
            if (sharingViolated)
              _violationBanner(
                Icons.group_rounded,
                'Sharing limit violated',
                const Color(0xFFEF4444),
                isDark,
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _detailItem(
                    'Pickup',
                    formatTime(pickupTime),
                    earlyTime != null && lateTime != null
                        ? '${formatTime(earlyTime)} - ${formatTime(lateTime)}'
                        : null,
                    isDark,
                  ),
                ),
                Expanded(
                  child:
                      _detailItem('Dropoff', formatTime(dropoffTime), null, isDark),
                ),
                Expanded(
                  child: _detailItem(
                    'Duration',
                    duration != null ? '${duration.toStringAsFixed(0)} min' : '-',
                    null,
                    isDark,
                  ),
                ),
              ],
            ),
            if (waitTime > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.darkPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 14, color: AppTheme.darkPrimary),
                    const SizedBox(width: 6),
                    Text(
                      'Wait: ${waitTime.toStringAsFixed(1)} min',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.darkPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < priority ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 14,
                      color: i < priority
                          ? const Color(0xFFF59E0B)
                          : (isDark ? Colors.white24 : Colors.black12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'P$priority',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.4),
                  ),
                ),
                const Spacer(),
                if (emp['sharingLimit'] != null)
                  Text(
                    'Sharing: ${emp['sharingLimit']}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...notes.take(3).map((note) {
                final n = note as Map<String, dynamic>;
                final type = n['type'] ?? 'info';
                Color noteColor;
                IconData noteIcon;
                if (type == 'error') {
                  noteColor = const Color(0xFFEF4444);
                  noteIcon = Icons.error_outline_rounded;
                } else if (type == 'warning') {
                  noteColor = const Color(0xFFF59E0B);
                  noteIcon = Icons.warning_rounded;
                } else {
                  noteColor = AppTheme.darkPrimary;
                  noteIcon = Icons.info_outline_rounded;
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(noteIcon, size: 13, color: noteColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          n['text'] ?? '',
                          style: TextStyle(fontSize: 10, color: noteColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _typeBadge(String type, bool isDark, {bool isVehicleType = false}) {
    if (isVehicleType) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          type,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.5),
          ),
        ),
      );
    }
    
    IconData? icon;
    Color? badgeColor;
    
    final lowerType = type.toLowerCase();
    if (lowerType.contains('electric') || lowerType.contains('ev') || lowerType.contains('elec')) {
      icon = Icons.electric_bolt;
      badgeColor = const Color(0xFF10B981);
    } else if (lowerType.contains('petrol') || lowerType.contains('gas')) {
      icon = Icons.local_gas_station;
      badgeColor = const Color(0xFFF59E0B);
    } else if (lowerType.contains('diesel')) {
      icon = Icons.local_gas_station;
      badgeColor = const Color(0xFF8B5CF6);
    } else if (lowerType.contains('hybrid')) {
      icon = Icons.eco;
      badgeColor = const Color(0xFF06B6D4);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor?.withValues(alpha: 0.12) ?? 
            (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(6),
        border: badgeColor != null 
            ? Border.all(color: badgeColor.withValues(alpha: 0.3), width: 0.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: badgeColor),
            const SizedBox(width: 3),
          ],
          Text(
            type,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: badgeColor ?? (isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fuelTypeBadge(String fuelType, bool isDark) {
    IconData icon;
    Color badgeColor;
    String displayText;
    
    final lowerType = fuelType.toLowerCase();
    if (lowerType.contains('electric') || lowerType.contains('ev') || lowerType.contains('elec')) {
      icon = Icons.electric_bolt;
      badgeColor = const Color(0xFF10B981);
      displayText = 'Electric';
    } else if (lowerType.contains('petrol') || lowerType.contains('gas')) {
      icon = Icons.local_gas_station;
      badgeColor = const Color(0xFFF59E0B);
      displayText = 'Petrol';
    } else if (lowerType.contains('diesel')) {
      icon = Icons.local_gas_station;
      badgeColor = const Color(0xFF8B5CF6);
      displayText = 'Diesel';
    } else if (lowerType.contains('hybrid')) {
      icon = Icons.eco;
      badgeColor = const Color(0xFF06B6D4);
      displayText = 'Hybrid';
    } else {
      icon = Icons.local_gas_station;
      badgeColor = const Color(0xFF6B7280);
      displayText = fuelType;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            badgeColor.withValues(alpha: 0.15),
            badgeColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(
      String label, String value, String? subtitle, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.3),
            ),
          ),
      ],
    );
  }

  Widget _violationBanner(
      IconData icon, String text, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
