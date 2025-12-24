import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import '../models/data_repository.dart';

class ChiTietNodeScreen extends StatefulWidget {
  final String nodeId;
  const ChiTietNodeScreen({Key? key, required this.nodeId}) : super(key: key);

  @override
  State<ChiTietNodeScreen> createState() => _ChiTietNodeScreenState();
}

class _ChiTietNodeScreenState extends State<ChiTietNodeScreen> {
  List<FlSpot> diemDuLieuTemp = [];
  List<FlSpot> diemDuLieuHum = [];
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _loadHistoryFromDisk();
    _subscription = DataRepository().nodeStream.listen((data) {
      if (mounted) _loadHistoryFromDisk();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadHistoryFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    String? historyJson = prefs.getString('history_${widget.nodeId}');

    if (historyJson != null) {
      try {
        List<dynamic> listRaw = jsonDecode(historyJson);
        setState(() {
          diemDuLieuTemp.clear();
          diemDuLieuHum.clear();
          for (int i = 0; i < listRaw.length; i++) {
            var item = listRaw[i];
            diemDuLieuTemp.add(FlSpot(i.toDouble(), double.parse(item['temp'].toString())));
            diemDuLieuHum.add(FlSpot(i.toDouble(), double.parse(item['hum'].toString())));
          }
        });
      } catch (e) {
        print("Lỗi parse: $e");
      }
    }
  }

  // Logic thống kê
  double get maxT => diemDuLieuTemp.isEmpty ? 0 : diemDuLieuTemp.map((e) => e.y).reduce(max);
  double get minT => diemDuLieuTemp.isEmpty ? 0 : diemDuLieuTemp.map((e) => e.y).reduce(min);
  double get avgT => diemDuLieuTemp.isEmpty ? 0 : double.parse((diemDuLieuTemp.map((e) => e.y).reduce((a, b) => a + b) / diemDuLieuTemp.length).toStringAsFixed(1));

  double get maxH => diemDuLieuHum.isEmpty ? 0 : diemDuLieuHum.map((e) => e.y).reduce(max);
  double get minH => diemDuLieuHum.isEmpty ? 0 : diemDuLieuHum.map((e) => e.y).reduce(min);
  double get avgH => diemDuLieuHum.isEmpty ? 0 : double.parse((diemDuLieuHum.map((e) => e.y).reduce((a, b) => a + b) / diemDuLieuHum.length).toStringAsFixed(1));

  @override
  Widget build(BuildContext context) {
    String curT = diemDuLieuTemp.isEmpty ? "--" : "${diemDuLieuTemp.last.y}";
    String curH = diemDuLieuHum.isEmpty ? "--" : "${diemDuLieuHum.last.y}";

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nodeId, style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.teal,
        elevation: 0,
        toolbarHeight: 40,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // --- 1. THẺ THÔNG TIN (Compact) ---
            Row(
              children: [
                Expanded(
                  child: _buildCompactCard(
                    title: "NHIỆT ĐỘ (°C)",
                    currentVal: curT,
                    color: Colors.red,
                    max: maxT, min: minT, avg: avgT
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildCompactCard(
                    title: "ĐỘ ẨM (%)",
                    currentVal: curH,
                    color: Colors.blue,
                    max: maxH, min: minH, avg: avgH
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 10),

            // --- 2. BIỂU ĐỒ (Đã thêm lại đơn vị % và °C) ---
            Expanded(
              child: Container(
                padding: EdgeInsets.fromLTRB(0, 10, 10, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.red), Text(" Nhiệt", style: TextStyle(fontSize: 12)),
                        SizedBox(width: 10),
                        Icon(Icons.circle, size: 8, color: Colors.blue), Text(" Ẩm", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    SizedBox(height: 5),
                    Expanded(
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true, drawVerticalLine: true, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
                          titlesData: FlTitlesData(
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 20, getTitlesWidget: (v, m) => Text("${v.toInt()}", style: TextStyle(fontSize: 10, color: Colors.grey)))),
                            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
                          minY: 0, maxY: 100,
                          
                          // --- ĐÂY LÀ PHẦN ĐÃ SỬA LẠI ---
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
                              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                                return touchedBarSpots.map((barSpot) {
                                  final val = barSpot.y;
                                  if (barSpot.barIndex == 0) {
                                    // Index 0 là Nhiệt độ -> Thêm °C
                                    return LineTooltipItem("$val°C", const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                                  } else {
                                    // Index 1 là Độ ẩm -> Thêm %
                                    return LineTooltipItem("$val%", const TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold));
                                  }
                                }).toList();
                              },
                            ),
                          ),
                          // -------------------------------

                          lineBarsData: [
                            LineChartBarData(spots: diemDuLieuTemp, isCurved: false, color: Colors.red, barWidth: 2, dotData: FlDotData(show: false)),
                            LineChartBarData(spots: diemDuLieuHum, isCurved: false, color: Colors.blue, barWidth: 2, dotData: FlDotData(show: false)),
                          ],
                        ),
                      ),
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

  Widget _buildCompactCard({required String title, required String currentVal, required Color color, required double max, required double min, required double avg}) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
          Text(currentVal, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color)),
          Divider(color: color.withOpacity(0.3), height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStat("Max", "$max", color),
              _miniStat("Avg", "$avg", Colors.black54),
              _miniStat("Min", "$min", color),
            ],
          )
        ],
      ),
    );
  }

  Widget _miniStat(String label, String val, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey)),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}