import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditCatatanPage extends StatefulWidget {
  @override
  _EditCatatanPageState createState() => _EditCatatanPageState();
}

class _EditCatatanPageState extends State<EditCatatanPage> {
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1F0E8),
      appBar: AppBar(
        backgroundColor: Color(0xFFF1F0E8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Kembalikan nilai catatan saat tombol back diklik
            Navigator.pop(context, {
              'judul': _judulController.text,
              'catatan': _catatanController.text,
            });
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _judulController,
              maxLines: 1,
              maxLength: 60,
              decoration: InputDecoration(
                hintText: 'Judul',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF222831),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Terakhir diperbarui: 18/12/2024',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: Color(0x89222831),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _catatanController,
              maxLines: 5,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Tambah Catatan',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF222831),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}