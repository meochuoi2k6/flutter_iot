import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'mqtt_service.dart';
import '../models/node_cam_bien.dart'; // Đảm bảo bạn đã có model này

class DataRepository {
  // 1. Tạo Singleton (Để truy cập được từ mọi nơi)
  static final DataRepository _instance = DataRepository._internal();
  factory DataRepository() => _instance;
  DataRepository._internal();

  final MqttService _mqttService = MqttService();
  
  // 2. StreamController: Cái loa phát thanh để báo cho UI cập nhật
  final _nodeStreamController = StreamController<List<NodeCamBien>>.broadcast();
  Stream<List<NodeCamBien>> get nodeStream => _nodeStreamController.stream;

  // Topic cần nghe
  final String topicName = "flutter_iot/meochuoi2k6/sensor/temp";

  // Hàm khởi động (Gọi 1 lần duy nhất ở main.dart)
  Future<void> khoiDong() async {
    print("Repository: Đang khởi động...");
    
    // A. Load dữ liệu cũ từ JSON lên Stream ngay lập tức (để app không trắng trơn)
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

    // B. Kết nối MQTT và lắng nghe dữ liệu mới
    await _mqttService.connect(topicName, (message) async {
      await _xuLyVaLuuTru(message);
    });
  }

  // Hàm quan trọng: Nhận MQTT -> Lưu JSON -> Đẩy ra UI
  // ... (Phần trên giữ nguyên) ...

  // HÀM XỬ LÝ THÔNG MINH (MERGE DATA)
  Future<void> _xuLyVaLuuTru(String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Lấy danh sách ĐANG CÓ trong máy ra trước
      String? oldData = prefs.getString('latest_nodes_json');
      List<dynamic> currentList = oldData != null ? jsonDecode(oldData) : [];

      // 2. Lấy danh sách MỚI vừa nhận được từ MQTT
      List<dynamic> incomingList = jsonDecode(message);

      // 3. THUẬT TOÁN GỘP (MERGE):
      // Duyệt qua từng node mới nhận được
      for (var newNode in incomingList) {
        String newId = newNode['id'];
        
        // Tìm xem node này đã có trong danh sách cũ chưa?
        int index = currentList.indexWhere((oldNode) => oldNode['id'] == newId);

        if (index != -1) {
          // A. NẾU CÓ RỒI -> CẬP NHẬT SỐ LIỆU MỚI VÀO VỊ TRÍ CŨ
          currentList[index] = newNode;
        } else {
          // B. NẾU CHƯA CÓ -> THÊM MỚI VÀO DANH SÁCH
          currentList.add(newNode);
        }

        // --- LƯU LỊCH SỬ BIỂU ĐỒ CHO NODE NÀY (Giữ nguyên logic cũ) ---
        await _luuLichSuNode(newNode, prefs);
      }

      // 4. Lưu danh sách ĐÃ GỘP ngược lại vào bộ nhớ
      String mergedJson = jsonEncode(currentList);
      await prefs.setString('latest_nodes_json', mergedJson);

      // 5. Bắn ra giao diện
      List<NodeCamBien> nodes = currentList.map((e) => NodeCamBien.fromJson(e)).toList();
      _nodeStreamController.add(nodes);
      
      print("Repository: Đã cập nhật node ${incomingList[0]['id']}");

    } catch (e) {
      print("Repository Lỗi: $e");
    }
  }

  Future<void> xoaNode(String idCanXoa) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Lấy danh sách hiện tại ra
    String? oldData = prefs.getString('latest_nodes_json');
    if (oldData != null) {
      List<dynamic> list = jsonDecode(oldData);
      
      // 2. Xóa phần tử có ID trùng khớp
      list.removeWhere((item) => item['id'] == idCanXoa);

      // 3. Lưu danh sách mới lại vào bộ nhớ
      await prefs.setString('latest_nodes_json', jsonEncode(list));

      // 4. Cập nhật ngay lập tức ra màn hình
      List<NodeCamBien> nodes = list.map((e) => NodeCamBien.fromJson(e)).toList();
      _nodeStreamController.add(nodes);
      
      // (Tùy chọn) Xóa luôn lịch sử biểu đồ của nó cho sạch máy
      await prefs.remove('history_$idCanXoa');
    }
  }

  // Tách hàm lưu lịch sử ra cho gọn
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
}