import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class ChipCategoryRow extends StatefulWidget {
  final VoidCallback onSearchTap;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const ChipCategoryRow({
    Key? key,
    required this.onSearchTap,
    required this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  State<ChipCategoryRow> createState() => _ChipCategoryRowState();
}

class _ChipCategoryRowState extends State<ChipCategoryRow> {
  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final db = await openDatabase(
        path.join(await getDatabasesPath(), 'organify.db'),
      );

      final result = await db.query(
        'login_status',
        limit: 1,
      );

      if (result.isEmpty || result[0]['auth_token'] == null) {
        print('Token tidak ditemukan di SQLite.');
        if (!mounted) return;
        setState(() {
          categories = [];
          isLoading = false;
        });
        return;
      }

      final token = result[0]['auth_token'];
      print('Token: $token');

      final response = await http.get(
        Uri.parse('https://supabase-organify.vercel.app/kategori'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['data'];

        if (!mounted) return;
        setState(() {
          categories = data
              .map<Map<String, dynamic>>((item) => {
            'kategori': item['kategori'],
          })
              .toList();
          isLoading = false;
        });
      } else {
        print('Gagal fetch kategori. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        if (!mounted) return;
        setState(() {
          categories = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
      if (!mounted) return;
      setState(() {
        categories = [];
        isLoading = false;
      });
    }
  }

  void _onCategorySelected(String label) {
    widget.onCategorySelected(label);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip(label: 'Semua'),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else
                    ...categories.map((cat) => _buildChip(label: cat['kategori'])).toList()
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Image.asset(
              'assets/tombol_tiga_titik.png',
              width: 24,
              height: 24,
            ),
            onSelected: (String value) {
              if (value == 'search') {
                widget.onSearchTap();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'search',
                  child: Text(
                    "Mencari Tugas",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF222831),
                    ),
                  ),
                ),
              ];
            },
            color: const Color(0xFFF1F0E8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.zero,
            offset: const Offset(0, 40),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({required String label}) {
    final bool isSelected = label == widget.selectedCategory;

    return Row(
      children: [
        GestureDetector(
          onTap: () => _onCategorySelected(label),
          child: Chip(
            label: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            backgroundColor: isSelected ? const Color(0xFF698791) : const Color(0xFFB3C8CF),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}
