import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../config/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppTheme.darkBg,
                        const Color(0xFF0F172A),
                        AppTheme.darkBg,
                      ]
                    : [
                        AppTheme.lightBg,
                        const Color(0xFFFFF5E6),
                        AppTheme.lightBg,
                      ],
              ),
            ),
          ),
          Positioned(
            top: -size.width * 0.3,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.darkPrimary.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -size.width * 0.2,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.6,
              height: size.width * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.darkSecondary.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: IconButton(
              onPressed: () => themeProvider.toggleTheme(),
              icon: Icon(
                isDark ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.1),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/app_icon.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'VELORA',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 12,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [
                                  AppTheme.darkPrimary,
                                  AppTheme.darkSecondary,
                                ],
                              ).createShader(
                                  const Rect.fromLTWH(0, 0, 300, 60)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'VELORA MOBITECH',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Driven by Possibility',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? AppTheme.darkAccent.withValues(alpha: 0.7)
                                : AppTheme.lightAccent.withValues(alpha: 0.7),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          'Employee Transport\nRoute Planner',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Upload your employee pickup/drop data and get optimized routes automatically using advanced algorithms.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 48),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/upload'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.darkPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor:
                                  AppTheme.darkPrimary.withValues(alpha: 0.4),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'BEGIN OPTIMIZATION',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Icon(Icons.arrow_forward_rounded, size: 22),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 56),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: [
                            _FeatureItem(
                              icon: Icons.local_shipping_rounded,
                              label: 'Multi-Vehicle',
                              isDark: isDark,
                            ),
                            _FeatureItem(
                              icon: Icons.access_time_rounded,
                              label: 'Time Windows',
                              isDark: isDark,
                            ),
                            _FeatureItem(
                              icon: Icons.bar_chart_rounded,
                              label: 'Analytics',
                              isDark: isDark,
                            ),
                            _FeatureItem(
                              icon: Icons.gps_fixed_rounded,
                              label: 'Optimized',
                              isDark: isDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 28,
            color: AppTheme.darkPrimary,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
