import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:organify/sqlite/database_helper.dart';

class Task {
  final String title;
  final DateTime date;

  Task({required this.title, required this.date});
}

class TaskCalendar extends StatefulWidget {
  @override
  _TaskCalendarState createState() => _TaskCalendarState();
}

class _TaskCalendarState extends State<TaskCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<Task>> tasks = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    fetchTasksFromAPI();
  }

  Future<void> fetchTasksFromAPI() async {
    final token = await DatabaseHelper.instance.getToken(1);
    if (token == null) return;

    final response = await http.get(
      Uri.parse('https://supabase-organify.vercel.app/catatan'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'] as List;

      Map<DateTime, List<Task>> loadedTasks = {};

      for (var item in data) {
        if (item['status'] != false) continue; // hanya status false

        final deadlineStr = item['tanggal_deadline'];
        if (deadlineStr == null) continue;

        final deadline = DateTime.parse(deadlineStr).toLocal();
        final dateKey = DateTime(deadline.year, deadline.month, deadline.day);

        final task = Task(title: item['nama_list'], date: deadline);

        if (loadedTasks.containsKey(dateKey)) {
          loadedTasks[dateKey]!.add(task);
        } else {
          loadedTasks[dateKey] = [task];
        }
      }

      setState(() {
        tasks = loadedTasks;
      });
    } else {
      print('❌ Gagal ambil data tugas: ${response.statusCode}');
    }
  }

  List<Task> _getTasksForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return tasks[dateKey] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD9D9D9),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFD9D9D9),
            child: TableCalendar(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2026, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: _getTasksForDay,
              calendarStyle: CalendarStyle(
                markerDecoration: const BoxDecoration(
                  color: Color(0xFF4E6167),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFF4E6167),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('Pilih tanggal untuk melihat tugas'))
                : ListView(
              children: _getTasksForDay(_selectedDay!).map((task) {
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  padding: const EdgeInsets.symmetric(vertical: 1.0),
                  child: ListTile(
                    title: Text(
                      task.title,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF222831),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.flag),
                      onPressed: () {
                        _addEventToCalendar(task);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  void _addEventToCalendar(Task task) {
    final event = Event(
      title: task.title,
      description: 'Tugas untuk tanggal ${task.date.toLocal()}',
      location: 'Ruang Kelas',
      startDate: task.date,
      endDate: task.date.add(const Duration(hours: 1)),
    );

    Add2Calendar.addEvent2Cal(event).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tugas berhasil ditambahkan ke kalender')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan tugas ke kalender: $error')),
      );
    });
  }
}
