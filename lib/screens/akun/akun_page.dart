import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:organify/screens/welcome_screen.dart';
import 'package:organify/screens/akun/dialogs/delete_account_dialog.dart';
import 'package:organify/sqlite/database_helper.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String nama = 'Memuat...';
  String email = 'Memuat...';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final token = await DatabaseHelper.instance.getToken(1);
    if (token == null) return;

    final response = await http.get(
      Uri.parse('https://supabase-organify.vercel.app/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      setState(() {
        nama = data['nama'] ?? 'Tidak Diketahui';
        email = data['email'] ?? 'Tidak Diketahui';
        isLoading = false;
      });
    } else {
      print("❌ Gagal ambil profil user: ${response.statusCode}");
      setState(() => isLoading = false);
    }
  }

  Future<void> _lupaPassword() async {
    final token = await DatabaseHelper.instance.getToken(1);
    if (token == null) {
      _showMessageDialog('Gagal', 'Token tidak ditemukan.');
      return;
    }

    try {
      // Ambil email dari endpoint /me
      final profileResponse = await http.get(
        Uri.parse('https://supabase-organify.vercel.app/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (profileResponse.statusCode != 200) {
        _showMessageDialog('Gagal', 'Tidak dapat mengambil email.');
        return;
      }

      final userData = jsonDecode(profileResponse.body)['data'];
      final String emailUser = userData['email'];

      // Kirim permintaan lupa password
      final forgotResponse = await http.post(
        Uri.parse('https://supabase-organify.vercel.app/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': emailUser}),
      );

      if (forgotResponse.statusCode == 200) {
        _showMessageDialog('Berhasil', 'Email reset password telah dikirim ke $emailUser.');
      } else {
        _showMessageDialog('Gagal', 'Terjadi kesalahan saat mengirim email reset password.');
      }
    } catch (e) {
      print('❌ Exception: $e');
      _showMessageDialog('Error', 'Terjadi kesalahan tak terduga.');
    }
  }

  void _showMessageDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: Text(message, style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F0E8),
      appBar: AppBar(
        title: Text(
          'Akun',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF222831),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Image.asset('assets/tombol_tiga_titik.png', width: 20, height: 20),
            offset: const Offset(0, kToolbarHeight),
            onSelected: (value) {
              if (value == 'lupa_password') {
                _lupaPassword();
              } else if (value == 'hapus_akun') {
                showDeleteAccountDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'lupa_password',
                child: Text('Lupa Password'),
              ),
              const PopupMenuItem(
                value: 'hapus_akun',
                child: Text('Hapus Akun'),
              ),
            ],
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(thickness: 1, color: Color(0xFFB8B7B7)),
            const SizedBox(height: 8),
            Text(
              'Nama',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF222831),
              ),
            ),
            Text(
              nama,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4E6167),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(thickness: 1, color: Color(0xFFB8B7B7)),
            const SizedBox(height: 8),
            Text(
              'Email',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF222831),
              ),
            ),
            Text(
              email,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4E6167),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(thickness: 1, color: Color(0xFFB8B7B7)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () async {
                  await DatabaseHelper.instance.logoutUser(1);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'LOGOUT',
                    textAlign: TextAlign.end,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF0004),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
