import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../viewmodels/analytics_view_model.dart';

class AnalyticsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AnalyticsViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: RefreshIndicator(
        onRefresh: () => viewModel.loadAnalytics(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildStatsCard(context, viewModel),
            const SizedBox(height: 16),
            _buildWeeklyDistanceChart(context, viewModel),
            const SizedBox(height: 16),
            _buildPersonalRecordsCard(context, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, AnalyticsViewModel viewModel) {
    final stats = viewModel.stats;
    if (stats == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Stats',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              children: [
                _buildStatItem(
                  'Total Runs',
                  stats.totalRuns.toString(),
                  Icons.directions_run,
                ),
                _buildStatItem(
                  'Total Distance',
                  '${stats.totalDistance.toStringAsFixed(1)} km',
                  Icons.route,
                ),
                _buildStatItem(
                  'Avg Pace',
                  '${stats.averagePace} /km',
                  Icons.speed,
                ),
                _buildStatItem(
                  'Longest Run',
                  '${stats.longestRun.toStringAsFixed(1)} km',
                  Icons.flag,
                ),
                _buildStatItem(
                  'Fastest Pace',
                  '${stats.fastestPace} /km',
                  Icons.timer,
                ),
                _buildStatItem(
                  'Total Time',
                  _formatDuration(stats.totalDuration),
                  Icons.access_time,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyDistanceChart(BuildContext context, AnalyticsViewModel viewModel) {
    final weeklySummaries = viewModel.weeklySummaries;
    if (weeklySummaries.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Progress',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()} km');
                        },
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= weeklySummaries.length) {
                            return const SizedBox.shrink();
                          }
                          final week = weeklySummaries[value.toInt()];
                          return Text(
                            '${week.weekStart.day}/${week.weekStart.month}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: weeklySummaries
                          .asMap()
                          .entries
                          .map((entry) => FlSpot(
                        entry.key.toDouble(),
                        entry.value.totalDistance,
                      ))
                          .toList(),
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalRecordsCard(BuildContext context, AnalyticsViewModel viewModel) {
    final records = viewModel.personalRecords;
    if (records.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Records',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return ListTile(
                  title: Text(record.category),
                  subtitle: Text(_formatDate(record.achievedDate)),
                  trailing: Text(
                    record.displayValue,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}