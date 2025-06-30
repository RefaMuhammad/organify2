import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:organify/sqlite/database_helper.dart';

class CategoryMenu extends StatefulWidget {
  final Function(String) onCategorySelected;

  const CategoryMenu({
    super.key,
    required this.onCategorySelected,
  });

  @override
  State<CategoryMenu> createState() => _CategoryMenuState();
}

class _CategoryMenuState extends State<CategoryMenu> {
  List<String> kategoriList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchKategori();
  }

  Future<void> fetchKategori() async {
    try {
      final token = await DatabaseHelper.instance.getToken(1);
      if (token == null) return;

      final response = await http.get(
        Uri.parse('https://supabase-organify.vercel.app/kategori'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        setState(() {
          kategoriList = data.map((item) => item['kategori'] as String).toList();
          isLoading = false;
        });
      } else {
        print('Gagal mengambil kategori: ${response.body}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetchKategori: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFF1F0E8).withOpacity(0.2),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...kategoriList.map((kategori) => ListTile(
              title: Text(kategori),
              onTap: () {
                widget.onCategorySelected(kategori);
                Navigator.of(context).pop();
              },
            )),
            ListTile(
              leading: const Icon(Icons.add, color: Colors.black),
              title: Text(
                'Buat Baru',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF222831),
                ),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    String? newCategory;
                    bool isInputFilled = false;

                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return AlertDialog(
                          title: Text(
                            'Buat Kategori Baru',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF222831),
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                onChanged: (value) {
                                  setState(() {
                                    newCategory = value;
                                    isInputFilled = newCategory != null && newCategory!.trim().isNotEmpty;
                                  });
                                },
                                maxLength: 50,
                                decoration: InputDecoration(
                                  hintText: 'Ketik disini',
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w300,
                                    color: const Color(0xFF222831),
                                  ),
                                  border: const OutlineInputBorder(),
                                  counterText: '',
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                'Batal',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF222831),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: isInputFilled
                                  ? () async {
                                if (newCategory != null && newCategory!.trim().isNotEmpty) {
                                  final token = await DatabaseHelper.instance.getToken(1);
                                  if (token == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Token tidak ditemukan')),
                                    );
                                    return;
                                  }

                                  try {
                                    final response = await http.post(
                                      Uri.parse('https://supabase-organify.vercel.app/kategori'),
                                      headers: {
                                        'Authorization': 'Bearer $token',
                                        'Content-Type': 'application/json',
                                      },
                                      body: jsonEncode({'kategori': newCategory!.trim()}),
                                    );

                                    if (response.statusCode == 201) {
                                      Navigator.of(context).pop();
                                      await fetchKategori(); // Refresh list kategori
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Kategori berhasil ditambahkan')),
                                      );
                                    } else {
                                      final error = jsonDecode(response.body);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Gagal menambahkan: ${error['message']}')),
                                      );
                                    }
                                  } catch (e) {
                                    print('Error saat kirim kategori: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Terjadi kesalahan')),
                                    );
                                  }
                                }
                              }
                                  : null,
                              child: Text(
                                'Simpan',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF222831),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
