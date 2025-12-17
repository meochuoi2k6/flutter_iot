import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math';

class ChiTietNodeScreen extends StatefulWidget {
  final String nodeId;
  const ChiTietNodeScreen({Key? key, required this.nodeId}) : super(key: key);

  @override
  State<ChiTietNodeScreen> createState() => _ChiTietNodeScreenState();
}

class _ChiTietNodeScreenState extends State<ChiTietNodeScreen> {
  List<FlSpot> diemDuLieuTemp = [];
  List<FlSpot> diemDuLieuHum = [];
  
  final int soLuongDiemHienThi = 10;
  double xValue = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Tạo dữ liệu giả ban đầu
    for (int i = 0; i < soLuongDiemHienThi; i++) {
      diemDuLieuTemp.add(FlSpot(xValue, 30.0));
      diemDuLieuHum.add(FlSpot(xValue, 70.0));
      xValue++;
    }

    _timer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
      if (mounted) {
        setState(() {
          double tempRaw = 28 + Random().nextDouble() * 5; 
          double humRaw = 60 + Random().nextDouble() * 20;

          double tempMoi = double.parse(tempRaw.toStringAsFixed(1));
          double humMoi = double.parse(humRaw.toStringAsFixed(1));

          diemDuLieuTemp.add(FlSpot(xValue, tempMoi));
          diemDuLieuHum.add(FlSpot(xValue, humMoi));
          xValue++;

          if (diemDuLieuTemp.length > soLuongDiemHienThi) {
            diemDuLieuTemp.removeAt(0);
            diemDuLieuHum.removeAt(0);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- LOGIC TÍNH TOÁN ---
  // Nhiệt độ
  double tinhMaxTemp() => diemDuLieuTemp.isEmpty ? 0 : diemDuLieuTemp.map((e) => e.y).reduce(max);
  double tinhMinTemp() => diemDuLieuTemp.isEmpty ? 0 : diemDuLieuTemp.map((e) => e.y).reduce(min);
  double tinhTrungBinhTemp() {
    if (diemDuLieuTemp.isEmpty) return 0;
    double tong = diemDuLieuTemp.map((e) => e.y).reduce((a, b) => a + b);
    return tong / diemDuLieuTemp.length;
  }

  // Độ ẩm (Đã sửa lỗi copy nhầm biến diemDuLieuTemp)
  double tinhMaxHum() => diemDuLieuHum.isEmpty ? 0 : diemDuLieuHum.map((e) => e.y).reduce(max);
  double tinhMinHum() => diemDuLieuHum.isEmpty ? 0 : diemDuLieuHum.map((e) => e.y).reduce(min);
  double tinhTrungBinhHum() {
    if (diemDuLieuHum.isEmpty) return 0;
    double tong = diemDuLieuHum.map((e) => e.y).reduce((a, b) => a + b);
    return tong / diemDuLieuHum.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chi tiết: ${widget.nodeId}"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Biểu đồ (Nhiệt & Ẩm)", 
                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),

            // --- VẼ BIỂU ĐỒ ---
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: true),
                  titlesData: FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        interval: 20,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toStringAsFixed(1), style: TextStyle(fontSize: 11));
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.grey.withOpacity(0.8),
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          final val = barSpot.y;
                          if (barSpot.barIndex == 0) {
                            return LineTooltipItem("$val°C", const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                          } else {
                            return LineTooltipItem("$val%", const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold));
                          }
                        }).toList();
                      },
                    ),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey)),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(spots: diemDuLieuTemp, isCurved: false, color: Colors.red, barWidth: 2, dotData: FlDotData(show: true)),
                    LineChartBarData(spots: diemDuLieuHum, isCurved: false, color: Colors.blue, barWidth: 2, dotData: FlDotData(show: true)),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.remove, color: Colors.red), Text(" Nhiệt độ  "),
                Icon(Icons.remove, color: Colors.blue), Text(" Độ ẩm"),
              ],
            ),

            SizedBox(height: 30),

            // --- BẢNG 1: THỐNG KÊ NHIỆT ĐỘ (MÀU ĐỎ) ---
            Text("Thống kê Nhiệt độ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTheThongTin("Max Temp", "${tinhMaxTemp().toStringAsFixed(1)}°C", Colors.red),
                _buildTheThongTin("Avg Temp", "${tinhTrungBinhTemp().toStringAsFixed(1)}°C", Colors.orange),
                _buildTheThongTin("Min Temp", "${tinhMinTemp().toStringAsFixed(1)}°C", Colors.redAccent),
              ],
            ),
            
            SizedBox(height: 20),

            // --- BẢNG 2: THỐNG KÊ ĐỘ ẨM (MÀU XANH) ---
            Text("Thống kê Độ ẩm", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // SỬA: Đổi đơn vị thành % và màu thành Xanh
                _buildTheThongTin("Max Hum", "${tinhMaxHum().toStringAsFixed(1)}%", Colors.blue[900]!),
                _buildTheThongTin("Avg Hum", "${tinhTrungBinhHum().toStringAsFixed(1)}%", Colors.blue),
                _buildTheThongTin("Min Hum", "${tinhMinHum().toStringAsFixed(1)}%", Colors.lightBlue),
              ],
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTheThongTin(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(10),
      width: 100, // Cố định độ rộng để thẳng hàng
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          SizedBox(height: 5),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}