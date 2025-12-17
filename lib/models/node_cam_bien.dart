class NodeCamBien {
  final String id;
  final double nhietDo;
  final double doAm;
  final bool trangThai;

  NodeCamBien({
    required this.id,
    required this.nhietDo,
    required this.doAm,
    required this.trangThai,
  });

  // Factory để chuyển đổi từ JSON (Map) sang Object
  factory NodeCamBien.fromJson(Map<String, dynamic> json) {
    return NodeCamBien(
      id: json['id'],
      // .toDouble() để tránh lỗi nếu server gửi số nguyên (VD: 30)
      nhietDo: (json['temp']).toDouble(),
      doAm: (json['hum']).toDouble(),
      trangThai: json['status'],
    );
  }
}