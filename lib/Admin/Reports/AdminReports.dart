import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChartData {
  final String x;
  final double y;
  const ChartData(this.x, this.y);
}

class AdminReports extends StatelessWidget {
  const AdminReports({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Reports'),
        backgroundColor: Colors.blue,
      ),
      body: const ReportsContent(),
    );
  }
}

class ReportsContent extends StatefulWidget {
  const ReportsContent({Key? key}) : super(key: key);

  @override
  _ReportsContentState createState() => _ReportsContentState();
}

class _ReportsContentState extends State<ReportsContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  int _totalPatients = 0;
  int _totalCaregivers = 0;
  int _totalDoctors = 0;
  int _totalUsers = 0;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserCounts();
  }

  Future<void> _loadUserCounts() async {
    try {
      // Get counts from all collections
      final patientsSnapshot = await _firestore.collection('patients').get();
      final caregiversSnapshot = await _firestore.collection('caregivers').get();
      final doctorsSnapshot = await _firestore.collection('doctors').get();

      setState(() {
        _totalPatients = patientsSnapshot.docs.length;
        _totalCaregivers = caregiversSnapshot.docs.length;
        _totalDoctors = doctorsSnapshot.docs.length;
        _totalUsers = _totalPatients + _totalCaregivers + _totalDoctors;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user counts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // User distribution data for charts
  List<ChartData> get _userDistributionData {
    return [
      ChartData('Patients', _totalPatients.toDouble()),
      ChartData('Caregivers', _totalCaregivers.toDouble()),
      ChartData('Doctors', _totalDoctors.toDouble()),
    ];
  }

  // Monthly statistics sample data (you can replace this with actual time-based data)
  final List<ChartData> _monthlyStatsData = const [
    ChartData('Jan', 35),
    ChartData('Feb', 28),
    ChartData('Mar', 34),
    ChartData('Apr', 32),
    ChartData('May', 40)
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Statistics Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overall Statistics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            _buildStatRow('Total Users', _totalUsers.toString(), Icons.people),
                            const SizedBox(height: 12),
                            _buildStatRow('Total Patients', _totalPatients.toString(), Icons.sick),
                            const SizedBox(height: 12),
                            _buildStatRow('Total Caregivers', _totalCaregivers.toString(), Icons.health_and_safety),
                            const SizedBox(height: 12),
                            _buildStatRow('Total Doctors', _totalDoctors.toString(), Icons.medical_services),
                          ],
                        ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // User Distribution Chart
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'User Distribution',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 300,
                    child: SfCartesianChart(
                      primaryXAxis: const CategoryAxis(),
                      legend: const Legend(isVisible: true),
                      series: <CartesianSeries<ChartData, String>>[
                        ColumnSeries<ChartData, String>(
                          dataSource: _userDistributionData,
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y,
                          name: 'Users',
                          dataLabelSettings: const DataLabelSettings(isVisible: true),
                          color: Colors.blue,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // User Distribution Pie Chart
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'User Type Distribution',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 300,
                    child: SfCircularChart(
                      legend: const Legend(
                        isVisible: true,
                        position: LegendPosition.bottom,
                      ),
                      series: <CircularSeries>[
                        PieSeries<ChartData, String>(
                          dataSource: _userDistributionData,
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y,
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                            labelPosition: ChartDataLabelPosition.outside,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Monthly Statistics Chart
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Monthly User Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 300,
                    child: SfCartesianChart(
                      primaryXAxis: const CategoryAxis(),
                      legend: const Legend(isVisible: true),
                      series: <CartesianSeries<ChartData, String>>[
                        LineSeries<ChartData, String>(
                          dataSource: _monthlyStatsData,
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y,
                          name: 'Monthly Activity',
                          dataLabelSettings: const DataLabelSettings(isVisible: true),
                          color: Colors.green,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Detailed User Breakdown
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detailed User Breakdown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            _buildDetailedStat(
                              'Patients',
                              _totalPatients,
                              'Individuals receiving care',
                              Icons.sick,
                              Colors.red,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailedStat(
                              'Caregivers',
                              _totalCaregivers,
                              'Professional caregivers',
                              Icons.health_and_safety,
                              Colors.orange,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailedStat(
                              'Doctors',
                              _totalDoctors,
                              'Medical professionals',
                              Icons.medical_services,
                              Colors.green,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info, color: Colors.blue.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Total platform users: $_totalUsers',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String title, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedStat(String title, int count, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}