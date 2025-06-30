import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:organify/sqlite/database_helper.dart';

class GrafikBatang extends StatefulWidget {
  final DateTime weekStart;
  final DateTime weekEnd;

  const GrafikBatang({
    Key? key,
    required this.weekStart,
    required this.weekEnd,
  }) : super(key: key);

  @override
  State<GrafikBatang> createState() => _GrafikBatangState();
}

class _GrafikBatangState extends State<GrafikBatang> {
  List<double> barValues = List.filled(7, 0); // Senin - Minggu
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGrafikData();
  }

  @override
  void didUpdateWidget(covariant GrafikBatang oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weekStart != widget.weekStart || oldWidget.weekEnd != widget.weekEnd) {
      fetchGrafikData();
    }
  }

  Future<void> fetchGrafikData() async {
    setState(() {
      isLoading = true;
    });

    final token = await DatabaseHelper.instance.getToken(1);
    if (token == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://supabase-organify.vercel.app/catatan'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        final start = widget.weekStart;
        final end = widget.weekEnd;

        List<double> countPerDay = List.filled(7, 0);

        for (var item in data) {
          if (item['status'] == true && item['tanggal_deadline'] != null) {
            final deadline = DateTime.parse(item['tanggal_deadline']).toLocal();
            if (!deadline.isBefore(start) && !deadline.isAfter(end)) {
              int dayIndex = deadline.weekday - 1; // Senin = 0
              countPerDay[dayIndex] += 1;
            }
          }
        }

        setState(() {
          barValues = countPerDay;
          isLoading = false;
        });
      } else {
        print("❌ Gagal fetch data grafik: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("❌ Error grafik fetch: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return Container(
      height: 150,
      padding: const EdgeInsets.all(10),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: List.generate(7, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: barValues[i],
                  color: const Color(0xFF89A8B2),
                  width: 15,
                ),
              ],
            );
          }),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(show: false),
          barTouchData: BarTouchData(enabled: false),
        ),
      ),
    );
  }
}
