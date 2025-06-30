import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:organify/screens/grafik_batang.dart';
import 'package:intl/intl.dart';

class ChartSection extends StatefulWidget {
  const ChartSection({super.key});

  @override
  State<ChartSection> createState() => _ChartSectionState();
}

class _ChartSectionState extends State<ChartSection> {
  int weekOffset = 0;
  late DateTime weekStart;
  late DateTime weekEnd;

  @override
  void initState() {
    super.initState();
    _updateWeekRange();
  }

  void _updateWeekRange() {
    final today = DateTime.now().add(Duration(days: 7 * weekOffset));
    final start = today.subtract(Duration(days: today.weekday - 1)); // ke Senin
    final end = start.add(const Duration(days: 6)); // ke Minggu

    setState(() {
      weekStart = DateTime(start.year, start.month, start.day);
      weekEnd = DateTime(end.year, end.month, end.day);
    });
  }

  void _changeWeek(int offset) {
    setState(() {
      weekOffset += offset;
      _updateWeekRange();
    });
  }

  String get weekRangeLabel {
    final df = DateFormat('dd/MM');
    return '${df.format(weekStart)} - ${df.format(weekEnd)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dan navigasi minggu
          Row(
            children: [
              Expanded(
                child: Text(
                  'Grafik Tugas Selesai',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF222831),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_left),
                onPressed: () => _changeWeek(-1),
              ),
              Text(
                weekRangeLabel,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF222831),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_right),
                onPressed: () => _changeWeek(1),
              ),
            ],
          ),

          const SizedBox(height: 10),
          GrafikBatang(weekStart: weekStart, weekEnd: weekEnd),
          const SizedBox(height: 10),

          // Label hari
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Senin', style: TextStyle(fontSize: 12)),
              Text('Selasa', style: TextStyle(fontSize: 12)),
              Text('Rabu', style: TextStyle(fontSize: 12)),
              Text('Kamis', style: TextStyle(fontSize: 12)),
              Text('Jumat', style: TextStyle(fontSize: 12)),
              Text('Sabtu', style: TextStyle(fontSize: 12)),
              Text('Minggu', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
