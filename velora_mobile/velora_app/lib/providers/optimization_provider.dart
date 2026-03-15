import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/file_service.dart';
import '../config/constants.dart';
import 'package:file_picker/file_picker.dart';

class OptimizationProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FileService _fileService = FileService();

  String _status = 'idle';
  String? _fileName;
  Map<String, dynamic>? _inputData;
  Map<String, dynamic>? _solution;
  String? _solutionId;
  String? _error;
  Map<String, double> _penaltyWeights = Map.from(defaultPenaltyWeights);
  Timer? _pollTimer;

  String get status => _status;
  String? get fileName => _fileName;
  Map<String, dynamic>? get inputData => _inputData;
  Map<String, dynamic>? get solution => _solution;
  String? get error => _error;
  Map<String, double> get penaltyWeights => _penaltyWeights;

  bool get isReady =>
      _inputData != null &&
      (_inputData!['vehicles'] as List?)?.isNotEmpty == true &&
      (_inputData!['requests'] as List?)?.isNotEmpty == true;

  int get vehicleCount => (_inputData?['vehicles'] as List?)?.length ?? 0;
  int get requestCount => (_inputData?['requests'] as List?)?.length ?? 0;

  Future<void> pickAndProcessFile() async {
    final file = await _fileService.pickFile();
    if (file == null) return;

    _error = null;
    _status = 'parsing';
    _fileName = file.name;
    _solution = null;
    _solutionId = null;
    notifyListeners();

    try {
      await _processFile(file);
    } catch (e) {
      _error = e.toString();
      _inputData = null;
      _status = 'idle';
    }
    notifyListeners();
  }

  Future<void> _processFile(PlatformFile file) async {
    final bytes = file.bytes;
    if (bytes == null) throw Exception('Cannot read file bytes');

    if (file.name.endsWith('.json')) {
      final jsonData = _fileService.readJsonFromBytes(bytes);

      if (_fileService.isOutputJson(jsonData)) {
        _buildSolutionFromOutput(jsonData);
        _status = 'completed';
        notifyListeners();
        return;
      }

      if (_fileService.isSolverInputJson(jsonData)) {
        _inputData = _fileService.normalizeSolverInput(jsonData);
      } else if (_fileService.isGenericInputJson(jsonData)) {
        _inputData = {
          ...jsonData,
          'baseline': jsonData['baseline'] ?? [],
        };
      } else {
        throw Exception(
            'Invalid JSON format. Must contain vehicles and requests, or routes and summary.');
      }
    } else {
      final parsed = await _apiService.parseExcelFromBytes(bytes.toList(), file.name);
      _inputData = _fileService.normalizeExcelData(parsed);
    }

    if (_inputData!['vehicles'] == null ||
        (_inputData!['vehicles'] as List).isEmpty ||
        _inputData!['requests'] == null ||
        (_inputData!['requests'] as List).isEmpty) {
      throw Exception('Missing required fleet or employee data.');
    }

    _status = 'ready';
  }

  void _buildSolutionFromOutput(Map<String, dynamic> jsonData) {
    final routes = jsonData['routes'] as List? ?? [];
    final requestDetails = jsonData['requestDetails'] as List? ?? [];

    _inputData = {
      'requests': requestDetails.asMap().entries.map((e) {
        final r = e.value;
        final i = e.key;
        return {
          'employeeId':
              r['employeeId'] ?? r['employee_id'] ?? 'E${i + 1}',
          'priority': r['priority'] ?? 3,
          'earlyTime': r['earlyTime'] ?? 0,
          'lateTime': r['lateTime'] ?? 90,
          'sharingLimit': r['sharingLimit'] ?? 4,
          'vehiclePreference': r['vehiclePreference'] ?? 'any',
          'pickup': {'lat': 0.0, 'lon': 0.0},
          'dropoff': {'lat': 0.0, 'lon': 0.0},
        };
      }).toList(),
      'vehicles': routes.asMap().entries.map((e) {
        final route = e.value;
        final i = e.key;
        return {
          'vehicleId': route['vehicleIdStr'] ?? route['vehicleId'] ?? 'V${i + 1}',
          'type': route['vehicleType'] ?? '4w',
          'fuelType': route['fuelType'] ?? 'petrol',
          'category': route['category'] ?? 'normal',
          'capacity': route['capacity'] ?? 4,
          'costPerKm': route['costPerKm'] ?? 15,
          'speed': 30,
          'startLocation': {'lat': 0.0, 'lon': 0.0},
        };
      }).toList(),
      'metadata': {
        'maxDelayByPriority': {1: 5, 2: 10, 3: 15, 4: 20, 5: 30},
      },
    };

    _solution = _buildSolutionMap(jsonData);
  }

  Map<String, dynamic> _buildSolutionMap(Map<String, dynamic> result) {
    final routes = result['routes'] as List? ?? [];
    final summary = result['summary'] as Map<String, dynamic>? ?? {};
    final unassigned = result['unassigned'] as List? ?? [];
    final requestDetails = result['requestDetails'] as List? ?? [];

    final totalMoneyCost = (summary['totalMoneyCost'] ?? 0).toDouble();
    final totalDistance = (summary['totalDistance'] ?? 0).toDouble();
    final totalTime = (summary['totalTime'] ?? 0).toDouble();
    final vehiclesUsed = summary['vehiclesUsed'] ?? routes.length;
    final unassignedCount =
        summary['unassignedCount'] ?? unassigned.length;
    final globalCost = (summary['globalCost'] ?? totalMoneyCost).toDouble();

    return {
      'status': 'completed',
      'routes': routes,
      'unassigned': unassigned,
      'totalDistance': totalDistance,
      'totalMoneyCost': totalMoneyCost,
      'globalCost': globalCost,
      'totalTime': totalTime,
      'vehiclesUsed': vehiclesUsed,
      'requestDetails': requestDetails,
      'data': {
        'routes': routes,
        'unassigned': unassigned,
        'unassignedRequests': result['unassignedRequests'] ?? unassigned,
        'summary': {
          'totalMoneyCost': totalMoneyCost,
          'totalDistance': totalDistance,
          'totalTime': totalTime,
          'vehiclesUsed': vehiclesUsed,
          'unassignedCount': unassignedCount,
          'globalCost': globalCost,
          ...summary,
        },
        'constraintAnalysis': result['constraintAnalysis'] ?? [],
      },
      'output': {
        'summary': summary,
        'routes': routes,
      },
    };
  }

  void updatePenaltyWeight(String key, double value) {
    _penaltyWeights[key] = value;
    notifyListeners();
  }

  void resetPenaltyWeights() {
    _penaltyWeights = Map.from(defaultPenaltyWeights);
    notifyListeners();
  }

  Future<void> submitOptimization() async {
    if (!isReady) return;

    _error = null;
    _status = 'submitting';
    notifyListeners();

    try {
      final payload = {
        'config': {
          ...(_inputData!['config'] as Map<String, dynamic>? ?? {}),
          'penalty_weights': _penaltyWeights,
        },
        'vehicles': _inputData!['vehicles'],
        'requests': _inputData!['requests'],
        'metadata': _inputData!['metadata'],
        'baseline': _inputData!['baseline'] ?? [],
      };

      final response = await _apiService.submitOptimization(payload);

      if (response['status'] == 'success' && response['result'] != null) {
        _solution = _buildSolutionMap(response['result']);
        _status = 'completed';
      } else {
        _solutionId = response['solutionId'] ?? response['jobId'];
        _status = 'processing';
        _solution = {'status': response['status'] ?? 'processing'};
        _startPolling();
      }
    } catch (e) {
      _error = e.toString();
      _status = 'error';
    }
    notifyListeners();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_solutionId == null) {
        timer.cancel();
        return;
      }
      try {
        final response = await _apiService.getResults(_solutionId!);
        if (response['status'] == 'success' && response['result'] != null) {
          _solution = _buildSolutionMap(response['result']);
          _status = 'completed';
          timer.cancel();
          notifyListeners();
        }
      } catch (_) {
      }
    });
  }

  void clear() {
    _pollTimer?.cancel();
    _status = 'idle';
    _fileName = null;
    _inputData = null;
    _solution = null;
    _solutionId = null;
    _error = null;
    notifyListeners();
  }

  void goBackToEdit() {
    _status = 'ready';
    _solution = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
