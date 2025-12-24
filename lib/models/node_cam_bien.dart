class NodeCamBien {
  final String id;
  final dynamic nhietDo; // Dùng dynamic cho an toàn
  final dynamic doAm;
  final bool trangThai;
  final DateTime thoiGianCapNhat; // <--- THÊM BIẾN NÀY

  NodeCamBien({
    required this.id,
    required this.nhietDo,
    required this.doAm,
    required this.trangThai,
    required this.thoiGianCapNhat, // <--- THÊM VÀO CONSTRUCTOR
  });

  factory NodeCamBien.fromJson(Map<String, dynamic> json) {
    return NodeCamBien(
      id: json['id'] ?? 'Unknown',
      nhietDo: json['temp'] ?? 0,
      doAm: json['hum'] ?? 0,
      trangThai: json['status'] ?? false,
      // Khi vừa parse JSON xong là lấy giờ hiện tại luôn
      thoiGianCapNhat: DateTime.now(), // <--- QUAN TRỌNG
    );
  }
}