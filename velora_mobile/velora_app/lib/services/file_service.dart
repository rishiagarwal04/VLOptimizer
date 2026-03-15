import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class FileService {
  Future<PlatformFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'json'],
      withData: true,
    );
    return result?.files.first;
  }

  Map<String, dynamic> readJsonFromBytes(Uint8List bytes) {
    final content = utf8.decode(bytes);
    return json.decode(content) as Map<String, dynamic>;
  }

  bool isOutputJson(Map<String, dynamic> data) {
    return data.containsKey('routes') &&
        (data.containsKey('summary') || data.containsKey('requestDetails'));
  }

  bool isSolverInputJson(Map<String, dynamic> data) {
    return data.containsKey('config') &&
        data.containsKey('vehicles') &&
        data.containsKey('requests');
  }

  bool isGenericInputJson(Map<String, dynamic> data) {
    return data.containsKey('vehicles') && data.containsKey('requests');
  }

  Map<String, dynamic> normalizeSolverInput(Map<String, dynamic> data) {
    final vehicles = (data['vehicles'] as List).map((v) {
      return {
        'vehicleId': v['vehicle_id'] ?? v['vehicleId'] ?? '',
        'capacity': v['capacity'] ?? 4,
        'costPerKm': v['costPerKm'] ?? 15,
        'startLocation': {
          'lat': v['startLoc']?['lat'] ?? 0.0,
          'lon': v['startLoc']?['lon'] ?? 0.0,
        },
        'availabilityTime': v['availabilityTime'] ?? 0,
        'speed': v['avg_speed_kmph'] ?? v['speed'] ?? 30,
        'type': v['type'] ?? v['vehicle_type'] ?? '4w',
        'category': v['category'] ?? 'normal',
        'fuelType': v['fuel_type'] ?? v['fuelType'] ?? 'petrol',
      };
    }).toList();

    final requests = (data['requests'] as List).map((r) {
      return {
        'employeeId': r['employee_id'] ?? r['employeeId'] ?? '',
        'priority': r['priority'] ?? 3,
        'pickup': {
          'lat': r['pickup']?['lat'] ?? 0.0,
          'lon': r['pickup']?['lon'] ?? 0.0,
        },
        'dropoff': {
          'lat': r['dropoff']?['lat'] ?? 0.0,
          'lon': r['dropoff']?['lon'] ?? 0.0,
        },
        'earlyTime': r['earlyTime'] ?? 0,
        'lateTime': r['lateTime'] ?? 90,
        'load': r['load'] ?? 1,
        'vehiclePreference':
            r['vehiclePreference'] ?? r['vehiclepreference'] ?? 'any',
        'sharingLimit': r['sharingLimit'] ?? 4,
      };
    }).toList();

    return {
      'vehicles': vehicles,
      'requests': requests,
      'metadata': {
        'maxDelayByPriority':
            data['config']?['tolerances'] ?? {1: 5, 2: 10, 3: 15, 4: 20, 5: 30},
      },
      'config': data['config'] ?? {},
      'baseline': data['baseline'] ?? [],
    };
  }

  Map<String, dynamic> normalizeExcelData(Map<String, dynamic> parsed) {
    final vehicles = (parsed['vehicles'] as List? ?? []).asMap().entries.map((e) {
      final v = e.value;
      final i = e.key;
      return {
        'vehicleId': v['vehicle_id'] ?? v['vehicleId'] ?? 'V${i + 1}',
        'capacity': v['capacity'] ?? 4,
        'costPerKm': v['costPerKm'] ?? 15,
        'startLocation': {
          'lat': v['startLoc']?['lat'] ?? 0.0,
          'lon': v['startLoc']?['lon'] ?? 0.0,
        },
        'availabilityTime': v['availabilityTime'] ?? 0,
        'speed': v['avg_speed_kmph'] ?? v['speed'] ?? 30,
        'type': v['type'] ?? v['vehicle_type'] ?? '4w',
        'category': v['category'] ?? 'normal',
        'fuelType': v['fuel_type'] ?? v['fuelType'] ?? 'petrol',
      };
    }).toList();

    final requests =
        (parsed['requests'] as List? ?? []).asMap().entries.map((e) {
      final r = e.value;
      final i = e.key;
      return {
        'employeeId': r['employee_id'] ?? r['employeeId'] ?? 'E${i + 1}',
        'priority': r['priority'] ?? 3,
        'pickup': {
          'lat': r['pickup']?['lat'] ?? 0.0,
          'lon': r['pickup']?['lon'] ?? 0.0,
        },
        'dropoff': {
          'lat': r['dropoff']?['lat'] ?? 0.0,
          'lon': r['dropoff']?['lon'] ?? 0.0,
        },
        'earlyTime': r['earlyTime'] ?? 0,
        'lateTime': r['lateTime'] ?? 90,
        'load': r['load'] ?? 1,
        'vehiclePreference':
            r['vehiclePreference'] ?? r['vehiclepreference'] ?? 'any',
        'sharingLimit': r['sharingLimit'] ?? 4,
      };
    }).toList();

    return {
      'vehicles': vehicles,
      'requests': requests,
      'config': parsed['config'] ?? {},
      'metadata': {
        'maxDelayByPriority': parsed['config']?['tolerances'] ??
            {1: 5, 2: 10, 3: 15, 4: 20, 5: 30},
      },
      'baseline': parsed['baseline'] ?? [],
    };
  }
}
