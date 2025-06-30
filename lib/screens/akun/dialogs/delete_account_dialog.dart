import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:organify/sqlite/database_helper.dart';
import 'package:organify/screens/welcome_screen.dart';

Future<void> showDeleteAccountDialog(BuildContext context) async {
  bool isDeleting = false;
  bool isButtonEnabled = false;

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      Timer(Duration(seconds: 3), () {
        isButtonEnabled = true;
        (dialogContext as Element).markNeedsBuild();
      });

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            icon: const Icon(Icons.error_outline, color: Colors.black, size: 70),
            content: Text(
              'Apakah Anda yakin ingin menghapus akun ini?\nProses ini bersifat permanen dan tidak dapat diubah.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black,
              ),
            ),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tombol Batal
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        color: const Color(0xFFB8B7B7),
                        child: TextButton(
                          onPressed: isDeleting ? null : () => Navigator.of(context).pop(),
                          child: Text(
                            'Batal',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Tombol Lanjutkan
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        color: isButtonEnabled ? Colors.red : Colors.grey,
                        child: TextButton(
                          onPressed: !isButtonEnabled || isDeleting
                              ? null
                              : () async {
                            setState(() => isDeleting = true);
                            final token = await DatabaseHelper.instance.getToken(1);
                            if (token == null) return;

                            final response = await http.delete(
                              Uri.parse('https://supabase-organify.vercel.app/delete-account'),
                              headers: {'Authorization': 'Bearer $token'},
                            );

                            if (response.statusCode == 200) {
                              await DatabaseHelper.instance.logoutUser(1);
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => WelcomeScreen()),
                                      (route) => false,
                                );
                              }
                            } else {
                              print('❌ Gagal hapus akun: ${response.body}');
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            }
                          },
                          child: isDeleting
                              ? const SizedBox(
                            height: 15,
                            width: 15,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            'Lanjutkan',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    },
  );
}
