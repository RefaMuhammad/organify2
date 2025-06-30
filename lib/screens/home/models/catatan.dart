class Catatan {
  final String id;
  final String namaList;
  final DateTime tanggalDeadline;
  final bool status;

  Catatan({
    required this.id,
    required this.namaList,
    required this.tanggalDeadline,
    required this.status,
  });

  factory Catatan.fromJson(Map<String, dynamic> json) {
    return Catatan(
      id: json['id'],
      namaList: json['nama_list'],
      tanggalDeadline: DateTime.parse(json['tanggal_deadline']),
      status: json['status'] ?? false,
    );
  }
}
