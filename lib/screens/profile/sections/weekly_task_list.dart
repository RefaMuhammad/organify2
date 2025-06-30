import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:organify/sqlite/database_helper.dart';

class WeeklyTaskList extends StatefulWidget {
  const WeeklyTaskList({super.key});

  @override
  State<WeeklyTaskList> createState() => _WeeklyTaskListState();
}

class _WeeklyTaskListState extends State<WeeklyTaskList> {
  List<Map<String, String>> upcomingTasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUpcomingTasks();
  }

  Future<void> fetchUpcomingTasks() async {
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
        final now = DateTime.now();
        final sevenDaysLater = now.add(const Duration(days: 7));

        final tasks = data
            .where((item) =>
        item['status'] == false &&
            item['tanggal_deadline'] != null &&
            DateTime.parse(item['tanggal_deadline']).isAfter(now.subtract(const Duration(days: 1))) &&
            DateTime.parse(item['tanggal_deadline']).isBefore(sevenDaysLater))
            .map<Map<String, String>>((item) {
          final deadline = DateTime.parse(item['tanggal_deadline']).toLocal();
          final formattedDate = '${deadline.day.toString().padLeft(2, '0')}-${deadline.month.toString().padLeft(2, '0')}';

          return {
            'task': item['nama_list'] ?? 'Tugas',
            'date': formattedDate,
          };
        }).toList();

        setState(() {
          upcomingTasks = tasks;
          isLoading = false;
        });
      } else {
        print("❌ Gagal fetch catatan: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("❌ Error fetchUpcomingTasks: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (upcomingTasks.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada tugas dalam 7 hari ke depan.',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: upcomingTasks.map((taskData) {
        return ListTile(
          leading: Image.asset('assets/button_kalender.png', width: 24, height: 24),
          title: Text(taskData['task']!, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF222831))),
          trailing: Text(taskData['date']!, style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w500)),
        );
      }).toList(),
    );
  }
}
