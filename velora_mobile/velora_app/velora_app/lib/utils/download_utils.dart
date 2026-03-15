import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

class DownloadUtils {
  /// Download solution as JSON file
  static Future<void> downloadJSON(
    BuildContext context,
    Map<String, dynamic>? solution,
    Map<String, dynamic>? inputData,
  ) async {
    try {
      final jsonData = {
        'routes': solution?['routes'],
        'summary': solution?['data']?['summary'],
        'unassigned': solution?['unassigned'],
        'requestDetails': solution?['requestDetails'],
        'constraintAnalysis': solution?['data']?['constraintAnalysis'],
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(jsonData);
      final bytes = utf8.encode(jsonStr);

      if (kIsWeb) {
        // For web, use printing package's saveAsFile
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'velora-optimization-${DateTime.now().millisecondsSinceEpoch}.json',
        );
      } else {
        // For mobile, save to downloads
        final directory = await getApplicationDocumentsDirectory();
        final file = File(
          '${directory.path}/velora-optimization-${DateTime.now().millisecondsSinceEpoch}.json',
        );
        await file.writeAsString(jsonStr);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('JSON saved to ${file.path}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download JSON: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Download solution as PDF report
  static Future<void> downloadPDF(
    BuildContext context,
    Map<String, dynamic>? solution,
    Map<String, dynamic>? inputData,
  ) async {
    try {
      final pdf = pw.Document();
      final routes = solution?['routes'] as List? ?? [];
      final summary = solution?['data']?['summary'] as Map<String, dynamic>? ?? {};
      final constraintAnalysis = solution?['data']?['constraintAnalysis'] as List? ?? [];
      final unassigned = solution?['unassigned'] as List? ?? [];

      // Page 1: Summary
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            // Title
            pw.Header(
              level: 0,
              child: pw.Text(
                'VELORA OPTIMIZATION REPORT',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Summary Section
            pw.Header(
              level: 1,
              text: 'Optimization Summary',
              textStyle: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            
            _buildSummaryTable(summary),
            pw.SizedBox(height: 20),
            
            // Routes Overview
            pw.Header(
              level: 1,
              text: 'Routes Overview',
              textStyle: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            
            _buildRoutesTable(routes),
            pw.SizedBox(height: 20),
            
            // Employee Assignments
            pw.Header(
              level: 1,
              text: 'Employee Assignments',
              textStyle: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            
            _buildEmployeesTable(constraintAnalysis, routes),
            
            // Unassigned Requests
            if (unassigned.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Header(
                level: 1,
                text: 'Unassigned Requests',
                textStyle: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red900,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildUnassignedTable(unassigned),
            ],
            
            // Footer
            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.Text(
              'Generated on ${DateTime.now().toString().split('.')[0]}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ),
      );

      // Save or share PDF
      final bytes = await pdf.save();
      
      if (kIsWeb) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'velora-report-${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File(
          '${directory.path}/velora-report-${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        await file.writeAsBytes(bytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF saved to ${file.path}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () {
                  Printing.sharePdf(bytes: bytes, filename: 'velora-report.pdf');
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static pw.Widget _buildSummaryTable(Map<String, dynamic> summary) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        _buildPdfRow('Total Routes', summary['totalRoutes']?.toString() ?? '0', isHeader: true),
        _buildPdfRow('Total Distance', '${summary['totalDistance']?.toStringAsFixed(2) ?? '0'} km'),
        _buildPdfRow('Total Time', '${summary['totalTime']?.toStringAsFixed(2) ?? '0'} min'),
        _buildPdfRow('Total Cost', '₹${summary['totalCost']?.toStringAsFixed(2) ?? '0'}'),
        _buildPdfRow('Employees Assigned', summary['assignedRequests']?.toString() ?? '0'),
        _buildPdfRow('Unassigned', summary['unassignedCount']?.toString() ?? '0'),
      ],
    );
  }

  static pw.Widget _buildRoutesTable(List routes) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
          children: [
            _buildPdfCell('Vehicle', isHeader: true),
            _buildPdfCell('Type', isHeader: true),
            _buildPdfCell('Fuel', isHeader: true),
            _buildPdfCell('Distance', isHeader: true),
            _buildPdfCell('Stops', isHeader: true),
          ],
        ),
        ...routes.map((route) {
          final vId = route['vehicleIdStr'] ?? route['vehicleId']?.toString() ?? '-';
          final type = route['vehicleType'] ?? '4w';
          final fuelType = route['fuelType'] ?? 'petrol';
          final dist = route['totalDist']?.toStringAsFixed(1) ?? '0';
          final stops = (route['stops'] as List?)?.length ?? 0;
          
          return pw.TableRow(
            children: [
              _buildPdfCell(vId),
              _buildPdfCell(type),
              _buildPdfCell(fuelType),
              _buildPdfCell('$dist km'),
              _buildPdfCell('$stops'),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildEmployeesTable(List constraintAnalysis, List routes) {
    List<Map<String, dynamic>> employees = [];
    
    if (constraintAnalysis.isNotEmpty) {
      employees = constraintAnalysis.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      // Build from routes
      for (final route in routes) {
        final stops = route['stops'] as List? ?? [];
        for (final stop in stops) {
          final empId = stop['employeeId'] ?? 'Req-${stop['reqId']}';
          final existing = employees.firstWhere(
            (e) => e['employeeId'] == empId,
            orElse: () => {},
          );
          
          if (existing.isEmpty) {
            employees.add({
              'employeeId': empId,
              'assignedVehicleId': route['vehicleIdStr'] ?? route['vehicleId']?.toString(),
              'assignedVehicleType': route['vehicleType'] ?? '4w',
              'fuelType': route['fuelType'] ?? 'petrol',
              'overallStatus': 'on_time',
            });
          }
        }
      }
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
          children: [
            _buildPdfCell('Employee', isHeader: true),
            _buildPdfCell('Vehicle', isHeader: true),
            _buildPdfCell('Type', isHeader: true),
            _buildPdfCell('Fuel', isHeader: true),
            _buildPdfCell('Status', isHeader: true),
          ],
        ),
        ...employees.take(50).map((emp) {
          final empId = emp['employeeId'] ?? '-';
          final vId = emp['assignedVehicleId'] ?? '-';
          final type = emp['assignedVehicleType'] ?? '4w';
          final fuel = emp['fuelType'] ?? 'petrol';
          final status = emp['overallStatus'] ?? 'on_time';
          
          return pw.TableRow(
            children: [
              _buildPdfCell(empId.toString()),
              _buildPdfCell(vId.toString()),
              _buildPdfCell(type),
              _buildPdfCell(fuel),
              _buildPdfCell(status.toString().replaceAll('_', ' ').toUpperCase()),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildUnassignedTable(List unassigned) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.red50,
        border: pw.Border.all(color: PdfColors.red200),
      ),
      child: pw.Text(
        'Unassigned Requests: ${unassigned.join(', ')}',
        style: const pw.TextStyle(fontSize: 12),
      ),
    );
  }

  static pw.TableRow _buildPdfRow(String label, String value, {bool isHeader = false}) {
    return pw.TableRow(
      decoration: isHeader ? const pw.BoxDecoration(color: PdfColors.blue50) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }

  static pw.Widget _buildPdfCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 11 : 10,
        ),
      ),
    );
  }
}
