import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChartData {
  final String x;
  final double y;
  final Color? color;
  const ChartData(this.x, this.y, [this.color]);
}

class AnalyticsData {
  final int totalPatients;
  final int totalCaregivers;
  final int totalDoctors;
  final int totalUsers;
  final int activeUsers;
  final int newUsersThisMonth;
  final double growthRate;

  AnalyticsData({
    required this.totalPatients,
    required this.totalCaregivers,
    required this.totalDoctors,
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsersThisMonth,
    required this.growthRate,
  });
}

class AdminAnalytics extends StatelessWidget {
  const AdminAnalytics({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {},
          ),
        ],
      ),
      body: const AnalyticsContent(),
    );
  }
}

class AnalyticsContent extends StatefulWidget {
  const AnalyticsContent({Key? key}) : super(key: key);

  @override
  _AnalyticsContentState createState() => _AnalyticsContentState();
}

class _AnalyticsContentState extends State<AnalyticsContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  AnalyticsData _analyticsData = AnalyticsData(
    totalPatients: 0,
    totalCaregivers: 0,
    totalDoctors: 0,
    totalUsers: 0,
    activeUsers: 0,
    newUsersThisMonth: 0,
    growthRate: 0.0,
  );
  
  List<ChartData> _monthlyGrowthData = [];
  List<ChartData> _userActivityData = [];
  List<ChartData> _platformUsageData = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      // Get counts from all collections
      final patientsSnapshot = await _firestore.collection('patients').get();
      final caregiversSnapshot = await _firestore.collection('caregivers').get();
      final doctorsSnapshot = await _firestore.collection('doctors').get();

      // Calculate analytics
      final totalPatients = patientsSnapshot.docs.length;
      final totalCaregivers = caregiversSnapshot.docs.length;
      final totalDoctors = doctorsSnapshot.docs.length;
      final totalUsers = totalPatients + totalCaregivers + totalDoctors;

      // For demo purposes - in real app, you'd calculate these from actual data
      final activeUsers = (totalUsers * 0.85).round(); // 85% active
      final newUsersThisMonth = (totalUsers * 0.15).round(); // 15% new this month
      final growthRate = totalUsers > 0 ? (newUsersThisMonth / totalUsers) * 100 : 0.0;

      // Generate chart data
      final monthlyGrowthData = _generateMonthlyGrowthData(totalUsers);
      final userActivityData = _generateUserActivityData();
      final platformUsageData = _generatePlatformUsageData();

      setState(() {
        _analyticsData = AnalyticsData(
          totalPatients: totalPatients,
          totalCaregivers: totalCaregivers,
          totalDoctors: totalDoctors,
          totalUsers: totalUsers,
          activeUsers: activeUsers,
          newUsersThisMonth: newUsersThisMonth,
          growthRate: growthRate,
        );
        _monthlyGrowthData = monthlyGrowthData;
        _userActivityData = userActivityData;
        _platformUsageData = platformUsageData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<ChartData> _generateMonthlyGrowthData(int totalUsers) {
    final base = totalUsers ~/ 6;
    return [
      ChartData('Jan', (base * 0.3).toDouble(), Colors.blue),
      ChartData('Feb', (base * 0.5).toDouble(), Colors.blue),
      ChartData('Mar', (base * 0.7).toDouble(), Colors.blue),
      ChartData('Apr', (base * 0.9).toDouble(), Colors.blue),
      ChartData('May', (base * 1.2).toDouble(), Colors.blue),
      ChartData('Jun', totalUsers.toDouble(), Colors.blue),
    ];
  }

  List<ChartData> _generateUserActivityData() {
    return [
      ChartData('Patients', _analyticsData.totalPatients.toDouble(), Colors.green),
      ChartData('Caregivers', _analyticsData.totalCaregivers.toDouble(), Colors.orange),
      ChartData('Doctors', _analyticsData.totalDoctors.toDouble(), Colors.purple),
    ];
  }

  List<ChartData> _generatePlatformUsageData() {
    return [
      ChartData('Mon', 65, Colors.blue),
      ChartData('Tue', 72, Colors.blue),
      ChartData('Wed', 68, Colors.blue),
      ChartData('Thu', 80, Colors.blue),
      ChartData('Fri', 75, Colors.blue),
      ChartData('Sat', 60, Colors.blue),
      ChartData('Sun', 55, Colors.blue),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header with overall stats
                _buildHeaderStats(),
                const SizedBox(height: 20),

                // Key Metrics Grid
                _buildMetricsGrid(),
                const SizedBox(height: 20),

                // Charts Row
                Row(
                  children: [
                    Expanded(
                      child: _buildUserDistributionChart(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildGrowthChart(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Platform Usage Chart
                _buildPlatformUsageChart(),
                const SizedBox(height: 20),

                // Detailed Analytics
                _buildDetailedAnalytics(),
              ],
            ),
          );
  }

  Widget _buildHeaderStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[700]!, Colors.blue[500]!],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Platform Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat('Total Users', _analyticsData.totalUsers, Icons.people),
              _buildHeaderStat('Active Users', _analyticsData.activeUsers, Icons.online_prediction),
              _buildHeaderStat('Growth', _analyticsData.growthRate, Icons.trending_up),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String title, dynamic value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value is double ? '${value.toStringAsFixed(1)}%' : value.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildMetricCard(
          'Patients',
          _analyticsData.totalPatients,
          Icons.sick,
          Colors.red,
          'Individuals receiving care',
        ),
        _buildMetricCard(
          'Caregivers',
          _analyticsData.totalCaregivers,
          Icons.health_and_safety,
          Colors.orange,
          'Professional caregivers',
        ),
        _buildMetricCard(
          'Doctors',
          _analyticsData.totalDoctors,
          Icons.medical_services,
          Colors.green,
          'Medical professionals',
        ),
        _buildMetricCard(
          'New This Month',
          _analyticsData.newUsersThisMonth,
          Icons.new_releases,
          Colors.purple,
          'New registrations',
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, int value, IconData icon, Color color, String subtitle) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDistributionChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'User Distribution',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 200,
              child: SfCircularChart(
                legend: const Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  overflowMode: LegendItemOverflowMode.wrap,
                ),
                series: <CircularSeries>[
                  DoughnutSeries<ChartData, String>(
                    dataSource: _userActivityData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                    ),
                    pointColorMapper: (ChartData data, _) => data.color,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Monthly Growth',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: const CategoryAxis(),
                primaryYAxis: const NumericAxis(
                  title: AxisTitle(text: 'Users'),
                ),
                series: <CartesianSeries<ChartData, String>>[
                  LineSeries<ChartData, String>(
                    dataSource: _monthlyGrowthData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    name: 'Growth',
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                    color: Colors.blue,
                    markerSettings: const MarkerSettings(isVisible: true),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformUsageChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Weekly Platform Usage',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 250,
              child: SfCartesianChart(
                primaryXAxis: const CategoryAxis(),
                primaryYAxis: const NumericAxis(
                  title: AxisTitle(text: 'Active Users'),
                ),
                series: <CartesianSeries<ChartData, String>>[
                  ColumnSeries<ChartData, String>(
                    dataSource: _platformUsageData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    name: 'Daily Active Users',
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                    color: Colors.blue,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedAnalytics() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detailed Analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildAnalyticsRow('Total Platform Users', _analyticsData.totalUsers.toString(), Icons.people, Colors.blue),
            _buildAnalyticsRow('Active Users (30 days)', '${_analyticsData.activeUsers} (${((_analyticsData.activeUsers / _analyticsData.totalUsers) * 100).toStringAsFixed(1)}%)', Icons.online_prediction, Colors.green),
            _buildAnalyticsRow('New Users This Month', _analyticsData.newUsersThisMonth.toString(), Icons.new_releases, Colors.orange),
            _buildAnalyticsRow('Monthly Growth Rate', '${_analyticsData.growthRate.toStringAsFixed(1)}%', Icons.trending_up, Colors.purple),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'User Type Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildUserTypeBreakdown('Patients', _analyticsData.totalPatients, Colors.red),
            _buildUserTypeBreakdown('Caregivers', _analyticsData.totalCaregivers, Colors.orange),
            _buildUserTypeBreakdown('Doctors', _analyticsData.totalDoctors, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsRow(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeBreakdown(String type, int count, Color color) {
    final percentage = _analyticsData.totalUsers > 0 
        ? (count / _analyticsData.totalUsers) * 100 
        : 0.0;
        
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              type,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$count (${percentage.toStringAsFixed(1)}%)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}