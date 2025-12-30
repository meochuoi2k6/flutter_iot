import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'mqtt_service.dart';
import '../models/node_cam_bien.dart'; 

class DataRepository {
  static final DataRepository _instance = DataRepository._internal();
  factory DataRepository() => _instance;
  DataRepository._internal();

  final MqttService _mqttService = MqttService();
  
  final _nodeStreamController = StreamController<List<NodeCamBien>>.broadcast();
  Stream<List<NodeCamBien>> get nodeStream => _nodeStreamController.stream;

  final String topicName = "flutter_iot/meochuoi2k6/sensor/temp";

  Future<void> khoiDong() async {
    //load du lieu cu len 
    final prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('latest_nodes_json');
    if (savedData != null) {
      try {
        List<dynamic> jsonList = jsonDecode(savedData);
        List<NodeCamBien> nodes = jsonList.map((e) => NodeCamBien.fromJson(e)).toList();
        _nodeStreamController.add(nodes); // Đẩy ra UI
      } catch (e) {
        print("Lỗi load JSON cũ: $e");
      }
    }

    // ket noi MQTT
    await _mqttService.connect(topicName, (message) async {
      await _xuLyVaLuuTru(message);
    });
  }


  //ham luu lich su
  Future<void> _luuLichSuNode(dynamic nodeJson, SharedPreferences prefs) async {
    String nodeId = nodeJson['id'];
    Map<String, dynamic> historyPoint = {
      'x': DateTime.now().millisecondsSinceEpoch.toDouble(),
      'temp': nodeJson['temp'] ?? nodeJson['nhietDo'],
      'hum': nodeJson['hum'] ?? nodeJson['doAm']
    };

    String keyHistory = 'history_$nodeId';
    String? oldHistory = prefs.getString(keyHistory);
    List<dynamic> historyList = oldHistory != null ? jsonDecode(oldHistory) : [];

    historyList.add(historyPoint);
    if (historyList.length > 20) historyList.removeAt(0); // Giới hạn 20 điểm

    await prefs.setString(keyHistory, jsonEncode(historyList));
  }
  // Ham xu ly va luu tru
  Future<void> _xuLyVaLuuTru(String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Lay danh sach cu ra truoc
      String? oldData = prefs.getString('latest_nodes_json');
      List<dynamic> currentList = oldData != null ? jsonDecode(oldData) : [];

      // 2. Lay danh sach vua nhan duoc tu MQTT
      List<dynamic> incomingList = jsonDecode(message);

      // Merging
      // Duyet qua tung node
      for (var newNode in incomingList) {
        String newId = newNode['id'];
        
        // Check xem node co nam trong ds cu ko
        int index = currentList.indexWhere((oldNode) => oldNode['id'] == newId);

        if (index != -1) { //Co
          currentList[index] = newNode;
        } else { // Chua co
          currentList.add(newNode);
        }

        //Luu lich su node
        await _luuLichSuNode(newNode, prefs);
      }

      //Luu danh sach vao du lieu 
      String mergedJson = jsonEncode(currentList);
      await prefs.setString('latest_nodes_json', mergedJson);

      // Dua ra giao dien
      List<NodeCamBien> nodes = currentList.map((e) => NodeCamBien.fromJson(e)).toList();
      _nodeStreamController.add(nodes);
      
      print("Repository: Đã cập nhật node ${incomingList[0]['id']}");

    } catch (e) {
      print("Repository Lỗi: $e");
    }
  }

  Future<void> xoaNode(String idCanXoa) async {
    final prefs = await SharedPreferences.getInstance();
    
    String? oldData = prefs.getString('latest_nodes_json');
    if (oldData != null) {
      List<dynamic> list = jsonDecode(oldData);
      
      // Xoa phan tu trung khop
      list.removeWhere((item) => item['id'] == idCanXoa);

      // Luu danh sach lai
      await prefs.setString('latest_nodes_json', jsonEncode(list));

      // Cap nhat ra man hinh luon 
      List<NodeCamBien> nodes = list.map((e) => NodeCamBien.fromJson(e)).toList();
      _nodeStreamController.add(nodes);
      
      await prefs.remove('history_$idCanXoa');
    }
  }
}