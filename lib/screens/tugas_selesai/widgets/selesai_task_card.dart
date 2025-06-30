import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SelesaiTaskCard extends StatelessWidget {
  final String namaTugas;
  final String tanggal;

  const SelesaiTaskCard({
    super.key,
    required this.namaTugas,
    required this.tanggal,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFFE4E4E0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0x80222831), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    namaTugas,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: const Color(0x80222831),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  Text(
                    tanggal,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: const Color(0x80222831),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.flag, color: Color(0x80222831), size: 24),
          ],
        ),
      ),
    );
  }
}
