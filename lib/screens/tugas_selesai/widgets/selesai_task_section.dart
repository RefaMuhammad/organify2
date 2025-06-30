import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'selesai_task_card.dart';

class SelesaiTaskSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> tasks;

  const SelesaiTaskSection({
    super.key,
    required this.title,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Opacity(
              opacity: 0.65,
              child: Icon(Icons.radio_button_checked),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4E6167),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final tugas = tasks[index];
            return SelesaiTaskCard(
              namaTugas: tugas['nama'],
              tanggal: title, // atau bisa ambil dari `tugas` jika berbeda
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
