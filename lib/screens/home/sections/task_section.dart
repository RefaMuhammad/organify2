import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskSection extends StatelessWidget {
  final String title;
  final bool isExpanded;
  final VoidCallback onTap;
  final List<Widget> tasks;

  const TaskSection({
    Key? key,
    required this.title,
    required this.isExpanded,
    required this.onTap,
    required this.tasks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Row(
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 24,
              ),
            ],
          ),
          onTap: onTap,
        ),
        if (isExpanded)
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: tasks,
          ),
      ],
    );
  }
}
