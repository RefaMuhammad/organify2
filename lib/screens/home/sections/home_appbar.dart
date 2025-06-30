import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:organify/screens/taskCalender_page.dart';
import 'package:intl/date_symbol_data_local.dart';


class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String getTodayDate() {
    final now = DateTime.now();
    // Format: "Rabu, 23 Juni"
    return DateFormat('EEEE, d MMMM', 'id_ID').format(now);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF1F0E8),
      centerTitle: true,
      automaticallyImplyLeading: true,
      title: Text(
        getTodayDate(),
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TaskCalendar()),
            );
          },
          icon: Image.asset('assets/tombol_kalender.png', width: 40, height: 40),
        ),
      ],
    );
  }
}
