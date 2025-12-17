import 'package:flutter/material.dart';
import 'dart:convert'; // Để dùng jsonDecode

// Import các file liên quan
import '../models/node_cam_bien.dart';
import '../models/mqtt_service.dart'; // <--- Import file vừa tạo
import 'chi_tiet_node_screen.dart';

class ManHinhChinh extends StatefulWidget {
  @override
  State<ManHinhChinh> createState() => _ManHinhChinhState();
}

class _ManHinhChinhState extends State<ManHinhChinh> {
  List<NodeCamBien> danhSachNode = [];
  
  // Khởi tạo dịch vụ MQTT
  final MqttService _mqttService = MqttService();

  // ĐỊA CHỈ KÊNH MÀ BẠN MUỐN NGHE (Topic)
  // Bạn có thể đổi tên này, nhưng phải khớp với MQTT Explorer
  final String topicName = "iot/nha_cua_toi/mesh_system"; 

  @override
  void initState() {
    super.initState();
    setupMqtt(); // Gọi hàm kết nối
  }

  void setupMqtt() async {
    // Kết nối đến Broker và truyền vào hàm xử lý tin nhắn
    await _mqttService.connect(topicName, (message) {
      // Hàm này chạy mỗi khi có tin nhắn mới từ MQTT Explorer gửi đến
      if (mounted) {
        xuLyDuLieuMqtt(message);
      }
    });
  }

  void xuLyDuLieuMqtt(String message) {
    try {
      // 1. Giải mã chuỗi JSON nhận được
      // Ví dụ nhận: '[{"id": "A", ...}, {"id": "B", ...}]'
      List<dynamic> listMap = jsonDecode(message);
      
      setState(() {
        // 2. Cập nhật danh sách hiển thị
        danhSachNode = listMap.map((e) => NodeCamBien.fromJson(e)).toList();
      });
      
      print("Đã cập nhật giao diện từ MQTT!");
    } catch (e) {
      print("Lỗi đọc JSON: $e");
      // Mẹo: Nếu gửi sai định dạng JSON, nó sẽ báo lỗi ở đây
    }
  }

  @override
  void dispose() {
    _mqttService.disconnect(); // Ngắt kết nối khi thoát app
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Giám Sát IoT (MQTT)"),
        backgroundColor: Colors.teal,
        actions: [
          // Icon hiển thị trạng thái kết nối
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(
              Icons.cloud_done, 
              color: _mqttService.isConnected ? Colors.greenAccent : Colors.grey
            ),
          )
        ],
      ),
      backgroundColor: Colors.grey[200],
      body: danhSachNode.isEmpty 
        ? Center(child: Text("Đang chờ dữ liệu từ MQTT Explorer...", style: TextStyle(color: Colors.grey))) 
        : ListView(
            padding: EdgeInsets.all(10),
            children: danhSachNode.map((node) {
              return Card(
                elevation: 3,
                margin: EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChiTietNodeScreen(nodeId: node.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.router, 
                                 color: node.trangThai ? Colors.green : Colors.grey, size: 30),
                            SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(node.id, 
                                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(node.trangThai ? "Online" : "Offline",
                                     style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("${node.nhietDo}°C", 
                                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                            Text("${node.doAm}%", 
                                 style: TextStyle(color: Colors.blue)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
    );
  }
}