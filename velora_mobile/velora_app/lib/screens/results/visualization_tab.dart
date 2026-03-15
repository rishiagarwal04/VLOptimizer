import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/glass_card.dart';

class VisualizationTab extends StatefulWidget {
  final Map<String, dynamic>? solution;
  final Map<String, dynamic>? inputData;

  const VisualizationTab({super.key, this.solution, this.inputData});

  @override
  State<VisualizationTab> createState() => _VisualizationTabState();
}

class _VisualizationTabState extends State<VisualizationTab>
    with AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();
  final Map<int, List<LatLng>> _routeGeometries = {};
  bool _loadingRoutes = false;
  int? _selectedRouteIndex;
  String? _selectedEmployeeId;
  int? _selectedEmployeeRouteIdx;

  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> get routes =>
      List<Map<String, dynamic>>.from(widget.solution?['routes'] ?? []);

  @override
  void initState() {
    super.initState();
    _fetchRouteGeometries();
  }

  Future<void> _fetchRouteGeometries() async {
    if (routes.isEmpty) return;
    setState(() => _loadingRoutes = true);

    final dio = Dio();

    for (int i = 0; i < routes.length; i++) {
      final stops = List<Map<String, dynamic>>.from(routes[i]['stops'] ?? []);
      if (stops.length < 2) continue;

      try {
        final coords = stops
            .map((s) => '${s['lon']},${s['lat']}')
            .join(';');
        final url =
            '$osrmBaseUrl/$coords?overview=full&geometries=geojson';
        
        print('Fetching route $i from OSRM: $url');
        final response = await dio.get(url);

        if (response.data['routes'] != null &&
            (response.data['routes'] as List).isNotEmpty) {
          final geometry =
              response.data['routes'][0]['geometry']['coordinates'] as List;
          _routeGeometries[i] = geometry
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();
          print('Route $i: Successfully fetched ${_routeGeometries[i]!.length} points');
        } else {
          print('Route $i: No routes in OSRM response');
          _routeGeometries[i] = stops
              .map((s) => LatLng(
                  (s['lat'] as num).toDouble(), (s['lon'] as num).toDouble()))
              .toList();
        }
      } catch (e) {
        print('Route $i: OSRM fetch error: $e');
        _routeGeometries[i] = stops
            .map((s) => LatLng(
                (s['lat'] as num).toDouble(), (s['lon'] as num).toDouble()))
            .toList();
      }
    }

    setState(() => _loadingRoutes = false);
  }

  LatLng _getCenter() {
    final allStops = routes.expand((r) =>
        (r['stops'] as List? ?? []).map((s) => s as Map<String, dynamic>));
    if (allStops.isEmpty) return const LatLng(28.6139, 77.2090);

    double sumLat = 0, sumLon = 0;
    int count = 0;
    for (final s in allStops) {
      final lat = (s['lat'] as num?)?.toDouble() ?? 0;
      final lon = (s['lon'] as num?)?.toDouble() ?? 0;
      if (lat != 0 && lon != 0) {
        sumLat += lat;
        sumLon += lon;
        count++;
      }
    }
    if (count == 0) return const LatLng(28.6139, 77.2090);
    return LatLng(sumLat / count, sumLon / count);
  }

  Color _getRouteColor(int index) {
    return Color(vehicleColorValues[index % vehicleColorValues.length]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _getCenter(),
            initialZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate: isDark
                  ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                  : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.velora.mobility',
              maxZoom: 19,
            ),
            PolylineLayer(
              polylines: _buildPolylines(),
            ),
            MarkerLayer(
              markers: _buildMarkers(isDark),
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  '© OpenStreetMap contributors',
                ),
                TextSourceAttribution(
                  '© CARTO',
                ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: _buildSummaryBar(isDark),
        ),
        if (_loadingRoutes)
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black87 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Loading routes...', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: _buildRouteLegend(isDark),
        ),
      ],
    );
  }

  List<Polyline> _buildPolylines() {
    final polylines = <Polyline>[];
    for (int i = 0; i < routes.length; i++) {
      if (_selectedRouteIndex != null && _selectedRouteIndex != i) continue;

      final stops = List<Map<String, dynamic>>.from(routes[i]['stops'] ?? []);
      final isThisRouteForEmployee = _selectedEmployeeRouteIdx == i;
      final hasEmployeeSelection = _selectedEmployeeId != null;

      if (hasEmployeeSelection && isThisRouteForEmployee) {
        int? pickupIdx;
        int? dropoffIdx;
        for (int j = 0; j < stops.length; j++) {
          final eid = stops[j]['employeeId']?.toString() ?? stops[j]['reqId']?.toString();
          if (eid == _selectedEmployeeId) {
            final sType = stops[j]['type'];
            if (sType == 'pickup' || sType == 'P') {
              pickupIdx = j;
            } else {
              dropoffIdx = j;
            }
          }
        }

        final geometry = _routeGeometries[i];
        if (geometry != null && geometry.isNotEmpty) {
          polylines.add(Polyline(
            points: geometry,
            color: _getRouteColor(i).withValues(alpha: 0.15),
            strokeWidth: 2,
          ));
          
          if (pickupIdx != null && dropoffIdx != null) {
            final pLat = (stops[pickupIdx]['lat'] as num).toDouble();
            final pLon = (stops[pickupIdx]['lon'] as num).toDouble();
            final dLat = (stops[dropoffIdx]['lat'] as num).toDouble();
            final dLon = (stops[dropoffIdx]['lon'] as num).toDouble();
            
            final startGeoIdx = _findClosestPointIndex(geometry, LatLng(pLat, pLon));
            final endGeoIdx = _findClosestPointIndex(geometry, LatLng(dLat, dLon));
            
            final highlightPoints = startGeoIdx < endGeoIdx 
                ? geometry.sublist(startGeoIdx, endGeoIdx + 1)
                : geometry.sublist(endGeoIdx, startGeoIdx + 1);
            
            polylines.add(Polyline(
              points: highlightPoints,
              color: _getRouteColor(i),
              strokeWidth: 6,
            ));
          }
        }
        continue;
      }

      if (hasEmployeeSelection && !isThisRouteForEmployee) {
        final geometry = _routeGeometries[i];
        if (geometry != null && geometry.isNotEmpty) {
          polylines.add(Polyline(
            points: geometry,
            color: _getRouteColor(i).withValues(alpha: 0.1),
            strokeWidth: 1.5,
          ));
        }
        continue;
      }

      final geometry = _routeGeometries[i];
      if (geometry != null && geometry.isNotEmpty) {
        polylines.add(Polyline(
          points: geometry,
          color: _getRouteColor(i),
          strokeWidth: _selectedRouteIndex == i ? 5 : 3.5,
        ));
      } else {
        if (stops.length >= 2) {
          polylines.add(Polyline(
            points: stops
                .map((s) => LatLng((s['lat'] as num).toDouble(),
                    (s['lon'] as num).toDouble()))
                .toList(),
            color: _getRouteColor(i).withValues(alpha: 0.5),
            strokeWidth: 2,
            isDotted: true,
          ));
        }
      }
    }
    return polylines;
  }

  int _findClosestPointIndex(List<LatLng> points, LatLng target) {
    int closest = 0;
    double minDist = double.infinity;
    for (int i = 0; i < points.length; i++) {
      final d = (points[i].latitude - target.latitude) *
              (points[i].latitude - target.latitude) +
          (points[i].longitude - target.longitude) *
              (points[i].longitude - target.longitude);
      if (d < minDist) {
        minDist = d;
        closest = i;
      }
    }
    return closest;
  }

  List<Marker> _buildMarkers(bool isDark) {
    final markers = <Marker>[];
    final hasEmployeeSelection = _selectedEmployeeId != null;

    for (int i = 0; i < routes.length; i++) {
      if (_selectedRouteIndex != null && _selectedRouteIndex != i) continue;

      final stops = List<Map<String, dynamic>>.from(routes[i]['stops'] ?? []);
      for (int j = 0; j < stops.length; j++) {
        final stop = stops[j];
        final lat = (stop['lat'] as num?)?.toDouble() ?? 0;
        final lon = (stop['lon'] as num?)?.toDouble() ?? 0;
        if (lat == 0 && lon == 0) continue;

        final employeeId = stop['employeeId']?.toString() ?? stop['reqId']?.toString() ?? '';
        final isPickup = stop['type'] == 'pickup' || stop['type'] == 'P';
        final isSelectedEmployee = hasEmployeeSelection && employeeId == _selectedEmployeeId;
        final isDimmed = hasEmployeeSelection && !isSelectedEmployee;

        final markerSize = isSelectedEmployee ? 38.0 : 30.0;
        final opacity = isDimmed ? 0.2 : 1.0;

        markers.add(Marker(
          point: LatLng(lat, lon),
          width: markerSize,
          height: markerSize,
          child: GestureDetector(
            onTap: () {
              if (_selectedEmployeeId == employeeId) {
                setState(() {
                  _selectedEmployeeId = null;
                  _selectedEmployeeRouteIdx = null;
                });
              } else {
                setState(() {
                  _selectedEmployeeId = employeeId;
                  _selectedEmployeeRouteIdx = i;
                });
              }
              _showStopInfo(context, stop, routes[i], i);
            },
            child: Opacity(
              opacity: opacity,
              child: Container(
                decoration: BoxDecoration(
                  color: _getRouteColor(i),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelectedEmployee ? Colors.yellowAccent : Colors.white,
                    width: isSelectedEmployee ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelectedEmployee
                          ? Colors.yellowAccent.withValues(alpha: 0.5)
                          : _getRouteColor(i).withValues(alpha: 0.4),
                      blurRadius: isSelectedEmployee ? 12 : 6,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isPickup ? '🏠' : '🏢',
                    style: TextStyle(fontSize: isSelectedEmployee ? 16 : 12),
                  ),
                ),
              ),
            ),
          ),
        ));
      }
    }
    return markers;
  }

  void _showStopInfo(BuildContext context, Map<String, dynamic> stop,
      Map<String, dynamic> route, int routeIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final type = stop['type'] == 'pickup' || stop['type'] == 'P'
        ? 'Pickup'
        : 'Dropoff';
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0C1223) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  type == 'Pickup' ? Icons.home_rounded : Icons.business_rounded,
                  color: _getRouteColor(routeIndex),
                ),
                const SizedBox(width: 10),
                Text(
                  '$type - ${stop['employeeId'] ?? 'Req ${stop['reqId']}'}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow('Vehicle',
                route['vehicleIdStr'] ?? route['vehicleId'].toString()),
            _infoRow('Arrival', formatTime(stop['arrivalTime'])),
            if (stop['waitTime'] != null && (stop['waitTime'] as num) > 0)
              _infoRow('Wait', '${(stop['waitTime'] as num).toStringAsFixed(1)} min'),
            _infoRow('Coordinates',
                '${(stop['lat'] as num).toStringAsFixed(5)}, ${(stop['lon'] as num).toStringAsFixed(5)}'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500)),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(bool isDark) {
    final summary =
        widget.solution?['data']?['summary'] as Map<String, dynamic>?;
    final totalStops = routes.fold<int>(
        0, (sum, r) => sum + ((r['stops'] as List?)?.length ?? 0));

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      borderRadius: 14,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem(Icons.location_on_rounded, '$totalStops',
              'Total Stops', isDark),
          _summaryItem(
              Icons.directions_car_rounded,
              '${summary?['vehiclesUsed'] ?? routes.length}',
              'Vehicles',
              isDark),
          _summaryItem(
              Icons.route_rounded,
              '${((summary?['totalDistance'] ?? 0) as num).toStringAsFixed(1)} km',
              'Distance',
              isDark),
        ],
      ),
    );
  }

  Widget _summaryItem(
      IconData icon, String value, String label, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.darkPrimary),
            const SizedBox(width: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 9,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.4))),
      ],
    );
  }

  Widget _buildRouteLegend(bool isDark) {
    if (routes.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: routes.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedRouteIndex = null;
                  _selectedEmployeeId = null;
                  _selectedEmployeeRouteIdx = null;
                }),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedRouteIndex == null && _selectedEmployeeId == null
                        ? AppTheme.darkPrimary.withValues(alpha: 0.2)
                        : (isDark ? Colors.black54 : Colors.white70),
                    borderRadius: BorderRadius.circular(18),
                    border: _selectedRouteIndex == null && _selectedEmployeeId == null
                        ? Border.all(color: AppTheme.darkPrimary)
                        : null,
                  ),
                  child: Text(
                    'All',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _selectedRouteIndex == null && _selectedEmployeeId == null
                          ? AppTheme.darkPrimary
                          : (isDark ? Colors.white60 : Colors.black45),
                    ),
                  ),
                ),
              ),
            );
          }

          final idx = i - 1;
          final route = routes[idx];
          final vId =
              route['vehicleIdStr'] ?? route['vehicleId']?.toString() ?? 'V$idx';
          final color = _getRouteColor(idx);
          final isSelected = _selectedRouteIndex == idx;

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () {
                  setState(() {
                    _selectedEmployeeId = null;
                    _selectedEmployeeRouteIdx = null;
                    _selectedRouteIndex = isSelected ? null : idx;
                  });
                },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.2)
                      : (isDark ? Colors.black54 : Colors.white70),
                  borderRadius: BorderRadius.circular(18),
                  border: isSelected ? Border.all(color: color) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      vId,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
