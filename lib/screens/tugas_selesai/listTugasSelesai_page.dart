import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:organify/sqlite/database_helper.dart';
import 'widgets/selesai_task_section.dart';

class TugasSelesaiPage extends StatefulWidget {
  const TugasSelesaiPage({super.key});

  @override
  State<TugasSelesaiPage> createState() => _TugasSelesaiPageState();
}

class _TugasSelesaiPageState extends State<TugasSelesaiPage> {
  List<Map<String, dynamic>> tugasSelesaiList = [];
  List<int> idTugasSelesai = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTugasSelesai();
  }

  Future<void> fetchTugasSelesai() async {
    final token = await DatabaseHelper.instance.getToken(1);
    if (token == null) return;

    final response = await http.get(
      Uri.parse('https://supabase-organify.vercel.app/catatan'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'] as List;

      final selesai = data.where((item) => item['status'] == true).toList()
        ..sort((a, b) => b['tanggal_deadline'].compareTo(a['tanggal_deadline']));

      final Map<String, List<Map<String, dynamic>>> grouped = {};

      idTugasSelesai.clear();
      for (var item in selesai) {
        final tanggal = item['tanggal_deadline'].split('T').first;
        grouped.putIfAbsent(tanggal, () => []);
        grouped[tanggal]!.add({'nama': item['nama_list']});
        idTugasSelesai.add(item['id']);
      }

      setState(() {
        tugasSelesaiList = grouped.entries.map((e) => {
          'tanggal': e.key,
          'tugas': e.value,
        }).toList();
        isLoading = false;
      });
    } else {
      print("❌ Gagal ambil data selesai: ${response.statusCode}");
      setState(() => isLoading = false);
    }
  }

  Future<void> hapusSemuaTugasSelesai() async {
    final token = await DatabaseHelper.instance.getToken(1);
    if (token == null) return;

    for (int id in idTugasSelesai) {
      final response = await http.delete(
        Uri.parse('https://supabase-organify.vercel.app/catatan/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        print('❌ Gagal hapus catatan id $id: ${response.statusCode}');
      }
    }

    // Refresh halaman
    fetchTugasSelesai();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F0E8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF222831)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFF222831)),
            onPressed: () async {
              final konfirmasi = await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Konfirmasi Hapus'),
                  content: const Text('Yakin ingin menghapus semua tugas yang selesai?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
                  ],
                ),
              );
              if (konfirmasi == true) {
                await hapusSemuaTugasSelesai();
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            "Tugas Selesai",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4E6167),
            ),
          ),
          const SizedBox(height: 15),
          if (tugasSelesaiList.isEmpty)
            Center(
              child: Text(
                "Belum ada tugas selesai.",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            )
          else
            for (var tugasSelesai in tugasSelesaiList)
              SelesaiTaskSection(
                title: tugasSelesai['tanggal'],
                tasks: tugasSelesai['tugas'],
              ),
        ],
      ),
    );
  }
}
