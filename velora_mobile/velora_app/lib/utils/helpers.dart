String formatTime(num? minutes) {
  if (minutes == null) return '-';
  final hours = (minutes / 60).floor();
  final mins = (minutes % 60).floor();
  return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
}

String formatNumber(num? value, {int decimals = 0}) {
  if (value == null) return '-';
  final str = value.toStringAsFixed(decimals);
  final parts = str.split('.');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  if (parts.length > 1) return '$intPart.${parts[1]}';
  return intPart;
}

String formatCurrency(num? value) {
  if (value == null) return '₹0';
  return '₹${formatNumber(value, decimals: 0)}';
}

int getMaxDelay(int priority, Map<String, dynamic>? tolerances) {
  final defaults = {1: 5, 2: 10, 3: 15, 4: 20, 5: 30};
  final p = priority.clamp(1, 5);
  if (tolerances != null && tolerances.containsKey(p.toString())) {
    return (tolerances[p.toString()] as num).toInt();
  }
  return defaults[p] ?? 15;
}
