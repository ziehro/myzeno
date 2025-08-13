// lib/src/screens/widgets/weight_chart_section.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/models/weight_log.dart';
import 'package:zeno/src/services/firebase_service.dart';
import 'chart_legends.dart';
import 'dart:math';

// Custom gesture recognizer for single-finger panning
class _SingleFingerPanGestureRecognizer extends OneSequenceGestureRecognizer {
  Function(DragStartDetails)? _onStart;
  Function(DragUpdateDetails)? _onUpdate;
  Function(DragEndDetails)? _onEnd;

  void setCallbacks({
    Function(DragStartDetails)? onStart,
    Function(DragUpdateDetails)? onUpdate,
    Function(DragEndDetails)? onEnd,
  }) {
    _onStart = onStart;
    _onUpdate = onUpdate;
    _onEnd = onEnd;
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer);
    resolve(GestureDisposition.accepted);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      _onUpdate?.call(DragUpdateDetails(
        globalPosition: event.position,
        localPosition: event.localPosition,
        delta: event.delta,
      ));
    } else if (event is PointerUpEvent) {
      _onEnd?.call(DragEndDetails());
      stopTrackingPointer(event.pointer);
    } else if (event is PointerDownEvent) {
      _onStart?.call(DragStartDetails(
        globalPosition: event.position,
        localPosition: event.localPosition,
      ));
    }
  }

  @override
  String get debugDescription => 'single finger pan';

  @override
  void didStopTrackingLastPointer(int pointer) {}
}

class WeightChartSection extends StatefulWidget {
  final UserProfile profile;
  final UserGoal goal;
  final Map<String, dynamic> chartData;
  final ScrollController scrollController;

  const WeightChartSection({
    super.key,
    required this.profile,
    required this.goal,
    required this.chartData,
    required this.scrollController,
  });

  @override
  State<WeightChartSection> createState() => _WeightChartSectionState();
}

class _WeightChartSectionState extends State<WeightChartSection> {
  double _zoomLevel = 1.0; // 1.0 = fully zoomed out, 0.0 = fully zoomed in
  double _panOffset = 0.0; // Horizontal pan offset
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final actualSpots = (widget.chartData['actual'] as List<FlSpot>?) ?? const <FlSpot>[];
    final theoreticalSpots = (widget.chartData['theoretical'] as List<FlSpot>?) ?? const <FlSpot>[];
    final dates = (widget.chartData['dates'] as List<DateTime>?) ?? const <DateTime>[];

    if (actualSpots.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text("Log weight for 2+ days to see a trend."),
          ),
        ),
      );
    }

    // Calculate zoom and pan parameters
    final totalDays = dates.length.toDouble();
    final minVisibleDays = 7.0; // Minimum days to show when fully zoomed in
    final visibleDays = (minVisibleDays + (totalDays - minVisibleDays) * _zoomLevel).clamp(minVisibleDays, totalDays);

    // Calculate the visible range based on pan offset
    final maxStartIndex = (totalDays - visibleDays).clamp(0.0, totalDays);
    final startIndex = (_panOffset * maxStartIndex).clamp(0.0, maxStartIndex);
    final endIndex = (startIndex + visibleDays).clamp(visibleDays, totalDays);

    // ---- Unified Y scale across both series ----
    double minYData = double.infinity;
    double maxYData = -double.infinity;

    void _scanVisibleRange(List<FlSpot> spots) {
      for (final s in spots) {
        if (s.x >= startIndex && s.x <= endIndex) {
          if (s.y < minYData) minYData = s.y;
          if (s.y > maxYData) maxYData = s.y;
        }
      }
    }

    _scanVisibleRange(actualSpots);
    _scanVisibleRange(theoreticalSpots);

    if (!minYData.isFinite || !maxYData.isFinite) {
      minYData = 0;
      maxYData = 1;
    }

    // Add headroom (5%) and pick a nice step; round min/max to step
    final range = (maxYData - minYData).abs();
    final step = _niceWeightStep(range);
    final paddedMin = minYData - range * 0.05;
    final paddedMax = maxYData + range * 0.05;

    final minY = (paddedMin / step).floor() * step;
    final maxY = (paddedMax / step).ceil() * step;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Weight Trend", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            // Chart Container with Gesture Detection
            SizedBox(
              height: 300,
              child: RawGestureDetector(
                gestures: {
                  _SingleFingerPanGestureRecognizer: GestureRecognizerFactoryWithHandlers<_SingleFingerPanGestureRecognizer>(
                        () => _SingleFingerPanGestureRecognizer(),
                        (_SingleFingerPanGestureRecognizer instance) {
                      instance.setCallbacks(
                        onStart: (details) {
                          _isDragging = true;
                        },
                        onUpdate: (details) {
                          if (_isDragging && maxStartIndex > 0) {
                            setState(() {
                              // Convert pan delta to offset change (negative for natural feel)
                              final sensitivity = 2.0 / MediaQuery.of(context).size.width;
                              _panOffset = (_panOffset - details.delta.dx * sensitivity).clamp(0.0, 1.0);
                            });
                          }
                        },
                        onEnd: (details) {
                          _isDragging = false;
                        },
                      );
                    },
                  ),
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 20, right: 12),
                  child: LineChart(
                    LineChartData(
                      minX: startIndex,
                      maxX: endIndex,
                      minY: minY,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: actualSpots,
                          isCurved: true,
                          color: Theme.of(context).colorScheme.primary,
                          barWidth: 4,
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          ),
                          dotData: FlDotData(
                            show: true,
                            checkToShowDot: (spot, barData) {
                              // Only show dots in visible range
                              return spot.x >= startIndex && spot.x <= endIndex;
                            },
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Theme.of(context).colorScheme.primary,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                        ),
                        if (theoreticalSpots.isNotEmpty)
                          LineChartBarData(
                            spots: theoreticalSpots,
                            isCurved: true,
                            color: Colors.grey,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            dashArray: [5, 5],
                          ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35,
                            interval: step,
                            getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                "${value.toInt()}",
                                textAlign: TextAlign.left,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: _calculateDateInterval(visibleDays),
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= dates.length) return const Text('');

                              final date = dates[index];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('M/d').format(date),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: step,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.3),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ),
            ),

            // Zoom Controls
            const SizedBox(height: 16),
            _buildZoomControls(visibleDays, totalDays),

            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ChartLegend(Theme.of(context).colorScheme.primary, "Actual Weight"),
              const SizedBox(width: 16),
              const ChartLegend(Colors.grey, "Theoretical Weight", isLine: true),
            ]),
            const SizedBox(height: 16),
            _buildWeightHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomControls(double visibleDays, double totalDays) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Zoom info and reset button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Showing ${visibleDays.toInt()} of ${totalDays.toInt()} days',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _zoomLevel = 1.0;
                  _panOffset = 1.0; // Start at the right (current date)
                });
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Zoom slider
        Row(
          children: [
            Icon(Icons.zoom_out, size: 20, color: Colors.grey.shade600),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                ),
                child: Slider(
                  value: 1.0 - _zoomLevel, // Invert for intuitive feel (right = zoom in)
                  onChanged: (value) {
                    setState(() {
                      _zoomLevel = 1.0 - value;
                      // Auto-pan to current date when zooming in
                      if (_zoomLevel < 0.8) {
                        _panOffset = 1.0;
                      }
                    });
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveColor: Colors.grey.shade300,
                ),
              ),
            ),
            Icon(Icons.zoom_in, size: 20, color: Colors.grey.shade600),
          ],
        ),
      ],
    );
  }

  // Calculate appropriate interval for date labels based on visible days
  double _calculateDateInterval(double visibleDays) {
    if (visibleDays <= 14) return 1.0; // Every day
    if (visibleDays <= 30) return 2.0; // Every other day
    if (visibleDays <= 60) return 7.0; // Weekly
    if (visibleDays <= 180) return 14.0; // Bi-weekly
    return 30.0; // Monthly
  }

  // Choose a pleasant tick interval for weight ranges
  double _niceWeightStep(double range) {
    if (range <= 5) return 0.5;
    if (range <= 10) return 1;
    if (range <= 25) return 2.5;
    if (range <= 60) return 5;
    if (range <= 120) return 10;
    return 20;
  }

  Widget _buildWeightHistoryList() {
    return StreamBuilder<List<WeightLog>>(
      stream: FirebaseService().weightLogStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final recentLogs = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            DropdownButtonFormField<WeightLog>(
              decoration: InputDecoration(
                labelText: "Recent Logs",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              items: recentLogs.map((log) {
                return DropdownMenuItem<WeightLog>(
                  value: log,
                  child: Text(
                    '${DateFormat('MMMM d, yyyy').format(log.date)} - ${log.weight.toStringAsFixed(1)} lbs',
                  ),
                );
              }).toList(),
              onChanged: (WeightLog? selectedLog) {
                if (selectedLog != null) {
                  // Find the index of this log in the dates array and pan to it
                  final dates = (widget.chartData['dates'] as List<DateTime>?) ?? [];
                  final logDate = DateTime(selectedLog.date.year, selectedLog.date.month, selectedLog.date.day);

                  for (int i = 0; i < dates.length; i++) {
                    final chartDate = DateTime(dates[i].year, dates[i].month, dates[i].day);
                    if (chartDate == logDate) {
                      setState(() {
                        // Calculate pan offset to center this date
                        final totalDays = dates.length.toDouble();
                        final minVisibleDays = 7.0;
                        final visibleDays = (minVisibleDays + (totalDays - minVisibleDays) * _zoomLevel).clamp(minVisibleDays, totalDays);
                        final maxStartIndex = (totalDays - visibleDays).clamp(0.0, totalDays);

                        if (maxStartIndex > 0) {
                          final targetStartIndex = (i - visibleDays / 2).clamp(0.0, maxStartIndex);
                          _panOffset = (targetStartIndex / maxStartIndex).clamp(0.0, 1.0);
                        }
                      });
                      break;
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}