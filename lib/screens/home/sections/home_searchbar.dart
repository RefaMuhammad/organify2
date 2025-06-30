import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeSearchBar extends StatelessWidget {
  final VoidCallback onClose;
  final ValueChanged<String> onSearch;

  const HomeSearchBar({
    Key? key,
    required this.onClose,
    required this.onSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 5.0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: const Color(0xFFD9D9D9),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onClose,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: onSearch,
                decoration: InputDecoration(
                  hintText: "Mencari tugas...",
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  hintStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF222831),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
