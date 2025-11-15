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
  List<dynamic> _doctorData = [];
  List<dynamic> _caregiverData = [];

  // Sample data - replace with your actual data
  final List<ChartData> chartData = const [
    ChartData('Jan', 35),
    ChartData('Feb', 28),
    ChartData('Mar', 34),
    ChartData('Apr', 32),
    ChartData('May', 40)
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      var doctorSnapshot = await _firestore.collection('doctors').get();
      var caregiverSnapshot = await _firestore.collection('caregivers').get();
      
      setState(() {
        _doctorData = doctorSnapshot.docs;
        _caregiverData = caregiverSnapshot.docs;
      });
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // First chart
          Container(
            height: 300,
            child: SfCartesianChart(
              primaryXAxis: const CategoryAxis(),
              title: const ChartTitle(text: 'Monthly Statistics'),
              legend: const Legend(isVisible: true),
              series: <CartesianSeries<ChartData, String>>[
                LineSeries<ChartData, String>(
                  dataSource: chartData,
                  xValueMapper: (ChartData data, _) => data.x,
                  yValueMapper: (ChartData data, _) => data.y,
                  name: 'Statistics',
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Second chart
          Container(
            height: 300,
            child: SfCartesianChart(
              primaryXAxis: const CategoryAxis(),
              title: const ChartTitle(text: 'User Distribution'),
              legend: const Legend(isVisible: true),
              series: <CartesianSeries<ChartData, String>>[
                ColumnSeries<ChartData, String>(
                  dataSource: chartData,
                  xValueMapper: (ChartData data, _) => data.x,
                  yValueMapper: (ChartData data, _) => data.y,
                  name: 'Users',
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                )
              ],
            ),
          ),
          
          // Display loaded data count
          const SizedBox(height: 20),
          Card(
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Data Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  // These will be dynamic in your actual implementation
                  Text('Doctors: Loading...'),
                  Text('Caregivers: Loading...'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}