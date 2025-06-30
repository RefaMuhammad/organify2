import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:organify/sqlite/database_helper.dart';
import 'package:organify/screens/edit_catatan.dart';

class EditTaskPage extends StatefulWidget {
  final int id;
  final String taskName;
  final String deadline;

  const EditTaskPage({
    Key? key,
    required this.id,
    required this.taskName,
    required this.deadline,
  }) : super(key: key);

  @override
  _EditTaskPageState createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  String? _namaTodo;     // nama_list dari todo
  String? _judul;        // judul dari catatan
  String? _catatan;      // isi dari catatan
  String? _kategori;
  String? _deadline;
  bool isLoading = true;
  List<String> kategoriList = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchDetailCatatan();
  }

  Future<void> _fetchCategories() async {
    final token = await DatabaseHelper.instance.getToken(1);
    if (token == null) return;

    final resp = await http.get(
      Uri.parse('https://supabase-organify.vercel.app/kategori'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body)['data'] as List;
      setState(() {
        kategoriList = data.map((e) => e['kategori'].toString()).toSet().toList(); // ✅ FIX
      });
    } else {
      print('❌ Gagal ambil kategori: ${resp.statusCode}');
    }
  }


  Future<void> _simpanPerubahan() async {
    final token = await DatabaseHelper.instance.getToken(1);
    if (token == null) return;

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // 1. Simpan catatan
    try {
      final todoItemUrl = Uri.parse('https://supabase-organify.vercel.app/catatan/${widget.id}/todoItem');
      final todoItemBody = jsonEncode({
        'judul': _judul ?? '',
        'isi': _catatan ?? '',
      });

      final todoResponse = await http.post(
        todoItemUrl,
        headers: headers,
        body: todoItemBody,
      );

      if (todoResponse.statusCode == 200 || todoResponse.statusCode == 201) {
        print('✅ Catatan berhasil disimpan');
      } else {
        print('❌ Gagal menyimpan catatan: ${todoResponse.statusCode}');
      }
    } catch (e) {
      print('❌ Error simpan catatan: $e');
    }

    // 2. Simpan kategori
    try {
      final updateUrl = Uri.parse('https://supabase-organify.vercel.app/catatan/${widget.id}');
      final updateBody = jsonEncode({
        'kategori': _kategori ?? 'Lainnya',
      });

      final putResponse = await http.put(
        updateUrl,
        headers: headers,
        body: updateBody,
      );

      if (putResponse.statusCode == 200) {
        print('✅ Kategori berhasil diperbarui');
      } else {
        print('❌ Gagal update kategori: ${putResponse.statusCode}');
      }
    } catch (e) {
      print('❌ Error update kategori: $e');
    }
  }



  Future<void> _fetchDetailCatatan() async {
    final token = await DatabaseHelper.instance.getToken(1);
    if (token == null) return;

    final url = Uri.parse('https://supabase-organify.vercel.app/catatan/${widget.id}');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];

      setState(() {
        _namaTodo = data['nama_list'];
        _kategori = data['kategori'];
        _deadline = data['tanggal_deadline']?.split('T').first;
        _judul = data['todo_item']?['judul'];
        _catatan = data['todo_item']?['isi'];
        isLoading = false;
      });
    } else {
      print("❌ Gagal ambil detail catatan: ${response.statusCode}");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || kategoriList.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFF1F0E8),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F0E8),
        elevation: 0,
        leading: BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Dropdown Kategori
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFB3C8CF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _kategori,
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                  dropdownColor: Colors.white,
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  items: kategoriList.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _kategori = newValue!;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ✅ Nama Todo (bukan judul catatan)
            Text(
              _namaTodo ?? widget.taskName,
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const Divider(thickness: 1, color: Color(0xFFB8B7B7)),
            const SizedBox(height: 16),

            // ✅ Deadline
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF222831)),
                    const SizedBox(width: 8),
                    Text(
                      'Tenggat Waktu',
                      style: GoogleFonts.poppins(fontSize: 13, color: Color(0xFF222831)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB3C8CF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _deadline ?? widget.deadline,
                    style: GoogleFonts.poppins(fontSize: 13, color: Color(0xFF222831)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(thickness: 1, color: Color(0xFFB8B7B7)),

            // ✅ Catatan Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.note_alt, color: Color(0xFF222831)),
                    const SizedBox(width: 8),
                    Text(
                      'Catatan',
                      style: GoogleFonts.poppins(fontSize: 13, color: Color(0xFF222831)),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditCatatanPage()),
                    );
                    if (result != null) {
                      setState(() {
                        _judul = result['judul'];
                        _catatan = result['catatan'];
                      });
                    }
                  },
                  child: Text(
                    'Tambah',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF222831),
                    ),
                  ),
                ),
              ],
            ),

            // ✅ Tampilkan judul dan isi catatan
            if (_judul != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_judul!, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            if (_catatan != null)
              Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_catatan!, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400))),

            const Divider(thickness: 1, color: Color(0xFFB8B7B7)),
            const SizedBox(height: 16),

            // ✅ Tombol Aksi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(
                          'Konfirmasi',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        content: Text(
                          'Apakah kamu yakin ingin menghapus catatan ini?',
                          style: GoogleFonts.poppins(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('Batal', style: GoogleFonts.poppins()),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text('Hapus', style: GoogleFonts.poppins(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final token = await DatabaseHelper.instance.getToken(1);
                      if (token == null) return;

                      final response = await http.delete(
                        Uri.parse('https://supabase-organify.vercel.app/catatan/${widget.id}'),
                        headers: {
                          'Authorization': 'Bearer $token',
                        },
                      );

                      if (response.statusCode == 200) {
                        // Berhasil menghapus
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Catatan berhasil dihapus')),
                        );
                        Navigator.pop(context); // Kembali ke halaman sebelumnya
                      } else {
                        // Gagal menghapus
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal menghapus: ${response.statusCode}')),
                        );
                      }
                    }
                  },
                  child: Text(
                    'HAPUS',
                    style: GoogleFonts.poppins(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),

                Row(
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: Text('BATAL', style: GoogleFonts.poppins(color: const Color(0x694E6167), fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _simpanPerubahan();
                        Navigator.pop(context);
                      },
                      child: Text('SELESAI', style: GoogleFonts.poppins(color: const Color(0xFF4E6167), fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
