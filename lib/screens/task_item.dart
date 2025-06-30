import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:organify/screens/edittask_page.dart';
import 'package:organify/sqlite/database_helper.dart';
import 'button.dart';

class TaskItem extends StatelessWidget {
  final String taskName;
  final String deadline;
  final int taskId;

  const TaskItem({
    Key? key,
    required this.taskId,
    required this.taskName,
    required this.deadline,
  }) : super(key: key);

  Future<void> _updateStatus(BuildContext context) async {
    final token = await DatabaseHelper.instance.getToken(1);
    if (token == null) return;

    final response = await http.put(
      Uri.parse('https://supabase-organify.vercel.app/catatan/$taskId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': true}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tugas ditandai sebagai selesai')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update status: ${response.statusCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditTaskPage(
              taskName: taskName,
              deadline: deadline,
              id: taskId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _updateStatus(context),
                  child: const Icon(Icons.circle_outlined, size: 24),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taskName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Image.asset('assets/catatan.png', width: 16, height: 16),
                        const SizedBox(width: 4),
                        Text(
                          deadline,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const MyButton(),
          ],
        ),
      ),
    );
  }
}
