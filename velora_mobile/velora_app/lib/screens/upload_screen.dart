import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/optimization_provider.dart';
import '../config/theme.dart';
import '../widgets/glass_card.dart';

class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final optProvider = Provider.of<OptimizationProvider>(context);
    final isDark = themeProvider.isDark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, isDark, themeProvider),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildWorkflowSteps(context, isDark, optProvider),
                    const SizedBox(height: 28),
                    _buildFileUploadCard(context, isDark, optProvider),
                    const SizedBox(height: 20),
                    _buildPenaltyConfig(context, isDark, optProvider),
                    const SizedBox(height: 20),
                    if (optProvider.fileName != null)
                      _buildActionBar(context, isDark, optProvider),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppTheme.darkPrimary, AppTheme.darkSecondary],
            ).createShader(bounds),
            child: const Text(
              'VELORA',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              isDark ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
              size: 20,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowSteps(
      BuildContext context, bool isDark, OptimizationProvider provider) {
    final steps = [
      _StepData(
        icon: Icons.storage_rounded,
        label: 'Upload',
        done: provider.fileName != null,
      ),
      _StepData(
        icon: Icons.settings_rounded,
        label: 'Optimize',
        done: provider.status == 'completed',
      ),
      _StepData(
        icon: Icons.bar_chart_rounded,
        label: 'Review',
        done: false,
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          return Container(
            width: 32,
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          );
        }
        final step = steps[i ~/ 2];
        final isActive = !step.done &&
            (i ~/ 2 == 0 || steps.take(i ~/ 2).every((s) => s.done));
        return _buildStepItem(isDark, step, isActive);
      }),
    );
  }

  Widget _buildStepItem(bool isDark, _StepData step, bool isActive) {
    Color iconColor;
    Color borderColor;
    Color bgColor;
    Color textColor;

    if (step.done) {
      iconColor = AppTheme.darkAccent;
      borderColor = AppTheme.darkAccent;
      bgColor = AppTheme.darkAccent.withValues(alpha: 0.1);
      textColor = AppTheme.darkAccent;
    } else if (isActive) {
      iconColor = AppTheme.darkPrimary;
      borderColor = AppTheme.darkPrimary;
      bgColor = AppTheme.darkPrimary.withValues(alpha: 0.1);
      textColor = AppTheme.darkPrimary;
    } else {
      iconColor = isDark 
          ? Colors.white.withValues(alpha: 0.3) 
          : Colors.black.withValues(alpha: 0.3);
      borderColor = isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.1);
      bgColor = isDark
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.black.withValues(alpha: 0.03);
      textColor = isDark 
          ? Colors.white.withValues(alpha: 0.3) 
          : Colors.black.withValues(alpha: 0.3);
    }

    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Icon(step.icon, size: 20, color: iconColor),
        ),
        const SizedBox(height: 6),
        Text(
          step.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadCard(
      BuildContext context, bool isDark, OptimizationProvider provider) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_rounded,
                  size: 22, color: AppTheme.darkPrimary),
              const SizedBox(width: 10),
              Text(
                'Upload Data File',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Upload input data (Excel/JSON) to run optimization, or upload output JSON to view pre-computed results.',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: provider.status == 'parsing'
                ? null
                : () async {
                      await provider.pickAndProcessFile();
                      if (provider.status == 'completed' &&
                          provider.solution != null &&
                          context.mounted) {
                        Navigator.pushNamed(context, '/results');
                      }
                    },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.02)
                    : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: provider.fileName != null
                      ? AppTheme.darkAccent.withValues(alpha: 0.3)
                      : isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
              child: provider.fileName == null
                  ? Column(
                      children: [
                        Icon(
                          Icons.cloud_upload_rounded,
                          size: 48,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.status == 'parsing'
                              ? 'Processing your file...'
                              : 'Tap to browse and select your file',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.black.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Excel (.xlsx, .xls), Input JSON, or Output JSON',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 48,
                          color: AppTheme.darkAccent,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          provider.fileName!,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'File loaded successfully',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.darkAccent,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (provider.fileName != null)
                TextButton.icon(
                  onPressed: () => provider.clear(),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Clear File'),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.6),
                  ),
                ),
              const Spacer(),
              if (provider.error != null)
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 16, color: Colors.red[400]),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          provider.error!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[400],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPenaltyConfig(
      BuildContext context, bool isDark, OptimizationProvider provider) {
    return GlassCard(
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: 8),
          leading: Icon(Icons.tune_rounded,
              size: 20, color: AppTheme.darkSecondary),
          title: Row(
            children: [
              Text(
                'Penalty Weights',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              if (provider.penaltyWeights.toString() !=
                  const {
                    'lateArrival': 10.0,
                    'sharingViolation': 500.0,
                    'vehiclePrefViolation': 300.0,
                    'unassigned': 50000.0,
                    'hardTimeWindow': 100000.0,
                  }.toString())
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSecondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Custom',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkSecondary,
                    ),
                  ),
                ),
            ],
          ),
          children: [
            _penaltySlider(
              isDark: isDark,
              label: 'Late Arrival (per min)',
              value: provider.penaltyWeights['lateArrival'] ?? 10,
              min: 0,
              max: 100,
              onChanged: (v) =>
                  provider.updatePenaltyWeight('lateArrival', v),
            ),
            _penaltySlider(
              isDark: isDark,
              label: 'Sharing Limit Violation',
              value: provider.penaltyWeights['sharingViolation'] ?? 500,
              min: 0,
              max: 5000,
              onChanged: (v) =>
                  provider.updatePenaltyWeight('sharingViolation', v),
            ),
            _penaltySlider(
              isDark: isDark,
              label: 'Vehicle Pref Violation',
              value:
                  provider.penaltyWeights['vehiclePrefViolation'] ?? 300,
              min: 0,
              max: 5000,
              onChanged: (v) =>
                  provider.updatePenaltyWeight('vehiclePrefViolation', v),
            ),
            _penaltySlider(
              isDark: isDark,
              label: 'Unassigned Employee',
              value: provider.penaltyWeights['unassigned'] ?? 50000,
              min: 0,
              max: 200000,
              onChanged: (v) =>
                  provider.updatePenaltyWeight('unassigned', v),
            ),
            _penaltySlider(
              isDark: isDark,
              label: 'Hard Time Window',
              value: provider.penaltyWeights['hardTimeWindow'] ?? 100000,
              min: 0,
              max: 500000,
              onChanged: (v) =>
                  provider.updatePenaltyWeight('hardTimeWindow', v),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => provider.resetPenaltyWeights(),
                child: const Text('Reset to Defaults'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _penaltySlider({
    required bool isDark,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.black.withValues(alpha: 0.6),
                ),
              ),
              Text(
                '₹${value.toInt()}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
            activeColor: AppTheme.darkPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(
      BuildContext context, bool isDark, OptimizationProvider provider) {
    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: provider.status == 'submitting' ||
                          provider.status == 'processing'
                      ? AppTheme.darkPrimary
                      : provider.status == 'completed'
                          ? AppTheme.darkAccent
                          : isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.3),
                  boxShadow: provider.status == 'submitting' ||
                          provider.status == 'processing'
                      ? [
                          BoxShadow(
                            color: AppTheme.darkPrimary.withValues(alpha: 0.5),
                            blurRadius: 8,
                          )
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                provider.status == 'ready'
                    ? 'Configuration Ready'
                    : provider.status == 'submitting' ||
                            provider.status == 'processing'
                        ? 'Optimizer Active'
                        : provider.status == 'completed'
                            ? 'Optimization Success'
                            : 'Ready',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              if (provider.isReady) ...[
                _chip(Icons.directions_car_rounded,
                    '${provider.vehicleCount} Fleet', isDark),
                const SizedBox(width: 6),
                _chip(Icons.people_rounded,
                    '${provider.requestCount} Targets', isDark),
              ],
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: provider.isReady &&
                      provider.status != 'submitting' &&
                      provider.status != 'processing'
                  ? () async {
                      await provider.submitOptimization();
                      if (provider.status == 'completed' && context.mounted) {
                        Navigator.pushNamed(context, '/results');
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: provider.status == 'submitting' ||
                      provider.status == 'processing'
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Processing...'),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rocket_launch_rounded, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'EXECUTE ENGINE',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (provider.error != null) ...[
            const SizedBox(height: 12),
            Text(
              provider.error!,
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isDark ? Colors.white54 : Colors.black45),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepData {
  final IconData icon;
  final String label;
  final bool done;

  _StepData({required this.icon, required this.label, required this.done});
}
