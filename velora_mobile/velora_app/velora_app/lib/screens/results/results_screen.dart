import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/optimization_provider.dart';
import '../../config/theme.dart';
import '../../utils/download_utils.dart';
import 'visualization_tab.dart';
import 'analytics_tab.dart';
import 'employees_tab.dart';
import 'routes_tab.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final optProvider = Provider.of<OptimizationProvider>(context);
    final isDark = themeProvider.isDark;
    final solution = optProvider.solution;

    if (solution == null || solution['status'] != 'completed') {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Processing optimization...',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, isDark, themeProvider, optProvider),
            // Tab bar
            _buildTabBar(isDark),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  VisualizationTab(
                    solution: solution,
                    inputData: optProvider.inputData,
                  ),
                  AnalyticsTab(
                    solution: solution,
                    inputData: optProvider.inputData,
                  ),
                  EmployeesTab(
                    solution: solution,
                    inputData: optProvider.inputData,
                  ),
                  RoutesTab(
                    solution: solution,
                    inputData: optProvider.inputData,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark,
      ThemeProvider themeProvider, OptimizationProvider optProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              optProvider.goBackToEdit();
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppTheme.darkPrimary, AppTheme.darkSecondary],
                  ).createShader(bounds),
                  child: const Text(
                    'VELORA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  'Optimization Intelligence',
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
          // Download PDF button
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 22),
            tooltip: 'Download PDF',
            onPressed: () {
              DownloadUtils.downloadPDF(
                context,
                optProvider.solution,
                optProvider.inputData,
              );
            },
          ),
          // Download JSON button
          IconButton(
            icon: const Icon(Icons.code_rounded, size: 22),
            tooltip: 'Download JSON',
            onPressed: () {
              DownloadUtils.downloadJSON(
                context,
                optProvider.solution,
                optProvider.inputData,
              );
            },
          ),
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

  Widget _buildTabBar(bool isDark) {
    final tabs = [
      const Tab(icon: Icon(Icons.map_rounded, size: 18), text: 'Map'),
      const Tab(
          icon: Icon(Icons.bar_chart_rounded, size: 18), text: 'Analytics'),
      const Tab(icon: Icon(Icons.people_rounded, size: 18), text: 'Employees'),
      const Tab(icon: Icon(Icons.list_alt_rounded, size: 18), text: 'Routes'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.darkPrimary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: AppTheme.darkPrimary,
        unselectedLabelColor:
            isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5),
        labelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        tabs: tabs,
        dividerColor: Colors.transparent,
      ),
    );
  }
}
