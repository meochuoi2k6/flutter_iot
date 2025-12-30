class NodeCamBien {
  final String id;
  final dynamic nhietDo; 
  final dynamic doAm;
  final bool trangThai;
  final DateTime thoiGianCapNhat; 
  final int pin;

  NodeCamBien({
    required this.id,
    required this.nhietDo,
    required this.doAm,
    required this.trangThai,
    required this.thoiGianCapNhat, 
    required this.pin,
  });

  factory NodeCamBien.fromJson(Map<String, dynamic> json) {
    return NodeCamBien(
      id: json['id'] ?? 'Unknown',
      nhietDo: json['temp'] ?? 0,
      doAm: json['hum'] ?? 0,
      trangThai: json['status'] ?? false,
      thoiGianCapNhat: DateTime.now(), //lay thoi gian
      pin: json['battery']
    );
  }
}