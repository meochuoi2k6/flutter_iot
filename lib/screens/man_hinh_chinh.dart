import 'package:flutter/material.dart';
import 'dart:async'; // Để dùng Timer
import '../models/node_cam_bien.dart';
import '../models/data_repository.dart';
import 'chi_tiet_node_screen.dart';

class ManHinhChinh extends StatefulWidget {
  @override
  State<ManHinhChinh> createState() => _ManHinhChinhState();
}

class _ManHinhChinhState extends State<ManHinhChinh> {
  Timer? _timerKiemTraOffline;

  @override
  void initState() {
    super.initState();
    DataRepository().khoiDong();
    
    // --- TẠO BỘ ĐẾM THỜI GIAN ---
    // Cứ 5 giây là bắt màn hình vẽ lại 1 lần để kiểm tra ai Offline
    _timerKiemTraOffline = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) setState(() {}); 
    });
  }

  @override
  void dispose() {
    _timerKiemTraOffline?.cancel(); // Hủy timer khi thoát
    super.dispose();
  }

  // Hàm kiểm tra xem Node còn sống không?
  // Nếu quá 10 giây không có dữ liệu mới -> Coi như chết (Offline)
  bool kiemTraOnline(NodeCamBien node) {
    final now = DateTime.now();
    final difference = now.difference(node.thoiGianCapNhat).inSeconds;
    return difference < 10; // Còn sống nếu mới cập nhật dưới 10s
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("IoT Dashboard", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<NodeCamBien>>(
        stream: DataRepository().nodeStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }

          final danhSachNode = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: danhSachNode.length,
            itemBuilder: (context, index) {
              return _buildSensorCard(context, danhSachNode[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildSensorCard(BuildContext context, NodeCamBien node) {
    // --- LOGIC MỚI: TỰ ĐỘNG CHUYỂN OFFLINE ---
    bool isOnline = kiemTraOnline(node); 
    
    // Nếu Offline thì chuyển sang màu Xám/Đỏ, Online thì màu Xanh
    Color statusColor = isOnline ? Colors.green : Colors.grey;
    String statusText = isOnline ? "ONLINE" : "OFFLINE (Mất kết nối)";
    
    // Nếu Offline thì làm mờ cả cái thẻ đi chút cho dễ nhận biết
    double opacity = isOnline ? 1.0 : 0.6; 

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChiTietNodeScreen(nodeId: node.id),
            ),
          );
        },

        onLongPress: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text("Xóa thiết bị?"),
              content: Text("Bạn có chắc muốn xóa '${node.id}' khỏi danh sách không?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(), // Hủy
                  child: Text("Hủy"),
                ),
                TextButton(
                  onPressed: () {
                    // Gọi hàm xóa trong Repository
                    DataRepository().xoaNode(node.id);
                    Navigator.of(ctx).pop(); // Đóng hộp thoại
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Đã xóa ${node.id}")),
                    );
                  },
                  child: Text("Xóa", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },

        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(color: Colors.blueGrey.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          
          child: Column(
            children: [
              // HEADER CARD
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.router, color: statusColor),
                        SizedBox(width: 10),
                        Text(node.id, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    // HUY HIỆU TRẠNG THÁI
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: statusColor),
                          SizedBox(width: 5),
                          Text(statusText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              
              // BODY CARD (Nhiệt độ - Độ ẩm)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInfoColumn(
                        icon: Icons.thermostat,
                        iconColor: isOnline ? Colors.orange : Colors.grey, // Xám nếu offline
                        label: "Nhiệt độ",
                        value: "${node.nhietDo}°C",
                        valueColor: isOnline ? Colors.orange.shade700 : Colors.grey,
                      ),
                    ),
                    Container(width: 1, height: 50, color: Colors.grey.shade200),
                    Expanded(
                      child: _buildInfoColumn(
                        icon: Icons.water_drop,
                        iconColor: isOnline ? Colors.blue : Colors.grey,
                        label: "Độ ẩm",
                        value: "${node.doAm}%",
                        valueColor: isOnline ? Colors.blue.shade700 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn({required IconData icon, required Color iconColor, required String label, required String value, required Color valueColor}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(icon, size: 18, color: iconColor), SizedBox(width: 5), Text(label, style: TextStyle(color: Colors.grey, fontSize: 12))],
        ),
        SizedBox(height: 5),
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }
}