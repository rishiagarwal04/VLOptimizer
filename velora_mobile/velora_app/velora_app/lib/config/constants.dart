// Backend API base URL
final String apiBaseUrl = 'https://velorabackend-kri-2651-ti.onrender.com/api';

// OSRM routing API
const String osrmBaseUrl = 'https://router.project-osrm.org/route/v1/driving';

// Default penalty weights (same as web)
const Map<String, double> defaultPenaltyWeights = {
  'lateArrival': 10,
  'sharingViolation': 500,
  'vehiclePrefViolation': 300,
  'unassigned': 50000,
  'hardTimeWindow': 100000,
};

// Default max delay by priority
const Map<int, int> defaultMaxDelayByPriority = {
  1: 5,
  2: 10,
  3: 15,
  4: 20,
  5: 30,
};

// Vehicle colors for map visualization
const List<int> vehicleColorValues = [
  0xFF2563EB, // Deep Blue
  0xFF7C3AED, // Deep Violet
  0xFF059669, // Forest Green
  0xFFD97706, // Burnt Orange
  0xFFDC2626, // Deep Rose
  0xFF0891B2, // Ocean Blue
  0xFFDB2777, // Deep Pink
  0xFF6366F1, // Indigo
  0xFF14B8A6, // Teal
  0xFFF59E0B, // Amber
];
