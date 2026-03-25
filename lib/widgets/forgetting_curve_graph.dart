import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/revision_item.dart';

class ForgettingCurveGraph extends StatelessWidget {
  final List<RevisionItem> items; // Now supports multiple items for aggregate curves
  final bool isDarkMode;

  const ForgettingCurveGraph({super.key, required this.items, required this.isDarkMode});

  // Constructor for individual items for backward compatibility
  ForgettingCurveGraph.individual({super.key, required RevisionItem item, required this.isDarkMode})
      : items = [item];

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text("No data for this bunch.", style: TextStyle(color: Colors.grey)),
      );
    }

    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) => Text("${val.toInt()}%", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      reservedSize: 35,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: _calculateInterval(),
                      getTitlesWidget: (val, meta) {
                        DateTime earliest = items.map((i) => i.createdAt).reduce((a, b) => a.isBefore(b) ? a : b);
                        DateTime date = earliest.add(Duration(minutes: (val * 24 * 60).toInt()));
                        
                        // Only show at major intervals to prevent overlapping
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('MM/dd').format(date),
                            style: const TextStyle(fontSize: 9, color: Colors.white38),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  _generateCurveData(),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.green,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          "Retention: ${spot.y.toStringAsFixed(1)}%",
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          if (items.length == 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: Colors.green, label: "Success"),
                const SizedBox(width: 16),
                _LegendItem(color: Colors.red, label: "Forgot"),
              ],
            )
          ]
        ],
      ),
    );
  }

  double _calculateInterval() {
    DateTime earliest = items.map((i) => i.createdAt).reduce((a, b) => a.isBefore(b) ? a : b);
    DateTime latest = _getDynamicEndTime();
    int days = latest.difference(earliest).inDays + 1;
    if (days <= 7) return 1;
    if (days <= 14) return 2;
    if (days <= 30) return 5;
    if (days <= 60) return 10;
    return 15;
  }

  DateTime _getDynamicEndTime() {
    DateTime now = DateTime.now();
    if (items.isEmpty) return now.add(const Duration(days: 7));
    
    // Find the furthest possible revision date among all items
    DateTime maxRevisionDate = items.map((i) => i.nextRevisionDate).reduce((a, b) => a.isAfter(b) ? a : b);
    
    // Ensure we show at least 3 days into future to see the curve dip
    DateTime prospectiveEnd = maxRevisionDate.isAfter(now) ? maxRevisionDate.add(const Duration(days: 2)) : now.add(const Duration(days: 5));
    
    return prospectiveEnd;
  }

  LineChartBarData _generateCurveData() {
    if (items.length == 1) {
      return _generateIndividualCurve(items.first);
    }
    
    // Aggregate Logic: Mean of all curves at discrete steps
    DateTime earliest = items.map((i) => i.createdAt).reduce((a, b) => a.isBefore(b) ? a : b);
    DateTime latest = _getDynamicEndTime();
    double totalDays = latest.difference(earliest).inMinutes / (24 * 60);
    
    List<FlSpot> spots = [];
    int steps = 40;
    double dayStep = totalDays / steps;

    for (int i = 0; i <= steps; i++) {
        double currentDayOffset = dayStep * i;
        DateTime pointDate = earliest.add(Duration(minutes: (currentDayOffset * 24 * 60).toInt()));
        
        double sumRetention = 0;
        int activeCount = 0;

        for (var item in items) {
          if (pointDate.isBefore(item.createdAt)) continue; // Card didn't exist yet
          sumRetention += _getRetentionAtDate(item, pointDate);
          activeCount++;
        }

        if (activeCount > 0) {
          spots.add(FlSpot(currentDayOffset, sumRetention / activeCount));
        }
    }

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      preventCurveOverShooting: true,
      color: Colors.greenAccent,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false), // No dots for aggregate
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            Colors.greenAccent.withOpacity(0.2),
            Colors.greenAccent.withOpacity(0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  double _getRetentionAtDate(RevisionItem item, DateTime targetDate) {
    if (targetDate.isBefore(item.createdAt)) return 100;
    
    // Find the last revision before targetDate
    List<RevisionHistoryEntry> pastHistory = item.revisionHistory
        .where((h) => h.date.isBefore(targetDate))
        .toList()
      ..sort((a,b) => b.date.compareTo(a.date)); // Newest first

    DateTime lastRevision = item.createdAt;
    double strength = 1.0;
    
    if (pastHistory.isNotEmpty) {
        lastRevision = pastHistory.first.date;
        // Approximation of strength based on success count before targetDate
        int successes = pastHistory.where((h) => h.isSuccess).length;
        List<int> intervals = [1, 3, 7, 14, 30, 60, 90, 180, 365];
        strength = intervals[min(successes, intervals.length - 1)].toDouble();
        
        // If last revision was a failure, strength is reset
        if (!pastHistory.first.isSuccess) strength = 1.0;
    }

    double tDays = targetDate.difference(lastRevision).inMinutes / (24 * 60);
    return exp(-tDays / (strength * 2)) * 100;
  }

  LineChartBarData _generateIndividualCurve(RevisionItem item) {
    List<FlSpot> spots = [];
    List<RevisionHistoryEntry> history = List.from(item.revisionHistory)..sort((a,b) => a.date.compareTo(b.date));
    DateTime startTime = item.createdAt;
    DateTime now = DateTime.now();
    DateTime endTime = item.nextRevisionDate.isAfter(now) ? item.nextRevisionDate : now.add(const Duration(days: 3));

    double currentStrength = 1.0; 
    DateTime lastRevision = startTime;
    spots.add(FlSpot(0, 100));

    double daysSinceStart(DateTime date) => date.difference(startTime).inMinutes / (24 * 60);

    for (var entry in history) {
      double xRevision = daysSinceStart(entry.date);
      _addDecayPoints(spots, daysSinceStart(lastRevision), xRevision, currentStrength);
      
      if (entry.isSuccess) {
        spots.add(FlSpot(xRevision, 100));
        int index = history.indexOf(entry);
        List<int> intervals = [1, 3, 7, 14, 30, 60, 90, 180, 365];
        currentStrength = intervals[min(index, intervals.length - 1)].toDouble();
      } else {
        double retention = _calculateRetention(xRevision - daysSinceStart(lastRevision), currentStrength);
        spots.add(FlSpot(xRevision, retention));
        currentStrength = 1.0; 
      }
      lastRevision = entry.date;
    }

    _addDecayPoints(spots, daysSinceStart(lastRevision), daysSinceStart(endTime), currentStrength);

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      preventCurveOverShooting: true,
      color: Colors.greenAccent,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          for (var entry in history) {
            double x = daysSinceStart(entry.date);
            if ((spot.x - x).abs() < 0.001) {
              return FlDotCirclePainter(
                radius: 5, color: entry.isSuccess ? Colors.greenAccent : Colors.redAccent,
                strokeWidth: 2, strokeColor: Colors.white,
              );
            }
          }
          return FlDotCirclePainter(radius: 0); 
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [Colors.greenAccent.withOpacity(0.2), Colors.greenAccent.withOpacity(0)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  double _calculateRetention(double tDays, double strength) {
    return exp(-tDays / (strength * 2)) * 100;
  }

  void _addDecayPoints(List<FlSpot> spots, double startX, double endX, double strength) {
    if (startX >= endX) return;
    int samples = 5;
    double step = (endX - startX) / samples;
    for (int i = 1; i <= samples; i++) {
        double x = startX + (step * i);
        double retention = _calculateRetention(x - startX, strength);
        spots.add(FlSpot(x, max(retention, 10))); 
    }
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
