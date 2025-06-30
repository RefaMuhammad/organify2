import 'package:flutter/material.dart';
import 'package:popover/popover.dart';
import 'package:google_fonts/google_fonts.dart';
import 'category_menu.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:organify/sqlite/database_helper.dart';

class CategoryButton extends StatefulWidget {
  final bool isEditPage;
  final Function(String)? onCategoryChanged;

  const CategoryButton({
    super.key,
    this.isEditPage = false,
    this.onCategoryChanged,
  });

  @override
  State<CategoryButton> createState() => _CategoryButtonState();
}

class _CategoryButtonState extends State<CategoryButton> {
  String selectedCategory = '';

  void updateCategory(String category) {
    setState(() {
      selectedCategory = category;
    });

    if (widget.onCategoryChanged != null) {
      widget.onCategoryChanged!(category);
    }
  }

  Future<void> fetchDefaultKategori() async {
    try {
      final token = await DatabaseHelper.instance.getToken(1);
      if (token == null) return;

      final response = await http.get(
        Uri.parse('https://supabase-organify.vercel.app/kategori'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        if (data is List && data.isNotEmpty) {
          final defaultCategory = data.first['kategori'];
          updateCategory(defaultCategory);
        }
      } else {
        print('Gagal ambil kategori default: ${response.body}');
      }
    } catch (e) {
      print('Error fetchDefaultKategori: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDefaultKategori();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showPopover(
        context: context,
        bodyBuilder: (context) => CategoryMenu(
          onCategorySelected: updateCategory,
        ),
        direction: PopoverDirection.bottom,
        width: 200,
        height: 150,
        arrowHeight: 10,
        arrowWidth: 20,
      ),
      child: Container(
        padding: widget.isEditPage
            ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isEditPage
              ? const Color(0xFFB3C8CF)
              : const Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedCategory,
              style: GoogleFonts.poppins(
                fontSize: widget.isEditPage ? 12 : 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF222831),
              ),
            ),
            if (widget.isEditPage) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: Color(0xFF222831),
              ),
            ],
          ],
        ),
      ),
    );
  }
}