import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:organify/screens/akun/akun_page.dart';
import 'package:organify/sqlite/database_helper.dart';
import 'package:organify/screens/profile/sections/summary_card.dart';
import 'package:organify/screens/profile/sections/weekly_task_list.dart';
import 'package:organify/screens/profile/sections/chart_section.dart';
import '../bottom_navbar.dart';
import '../sign_page.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isLoggedIn = false;
  bool isLoading = true;
  int tugasSelesai = 0;
  int tugasTertunda = 0;
  bool isRingkasanLoading = true;

  String? namaUser;
  bool isUserLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLoginStatus();
    _fetchRingkasanTugas();
    _fetchUserProfile();
  }

  Future<void> _loadLoginStatus() async {
    final data = await DatabaseHelper.instance.getLoginStatus(1);
    setState(() {
      isLoggedIn = data?['is_logged_in'] == 1;
      isLoading = false;
    });
  }

  Future<void> _fetchRingkasanTugas() async {
    final token = await DatabaseHelper.instance.getToken(1);
    if (token == null) return;

    final response = await http.get(
      Uri.parse('https://supabase-organify.vercel.app/catatan'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['data'];
      final selesai = data.where((item) => item['status'] == true).length;
      final tertunda = data.where((item) => item['status'] == false).length;

      setState(() {
        tugasSelesai = selesai;
        tugasTertunda = tertunda;
        isRingkasanLoading = false;
      });
    } else {
      print("Gagal ambil data catatan: ${response.statusCode}");
    }
  }

  Future<void> _fetchUserProfile() async {
    final token = await DatabaseHelper.instance.getToken(1);
    if (token == null) return;

    final response = await http.get(
      Uri.parse('https://supabase-organify.vercel.app/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final userData = json['data'];
      setState(() {
        namaUser = userData['nama'] ?? 'Pengguna';
        isUserLoading = false;
      });
    } else {
      print("❌ Gagal ambil profil user: ${response.statusCode}");
      setState(() {
        namaUser = 'Pengguna';
        isUserLoading = false;
      });
    }
  }

  void handleLogin() {
    if (!isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignPage(
            onLogin: () {
              _loadLoginStatus();
              _fetchUserProfile();
              _fetchRingkasanTugas();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F0E8),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: isLoggedIn ? _buildLoggedInView() : _buildNotLoggedInView(context),
      ),
      bottomNavigationBar: BottomNavbar(
        selectedIndex: 1,
        onItemTapped: (int index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
      ),
    );
  }

  Widget _buildLoggedInView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AccountPage()));
                },
                child: const CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/button_plus.png'),
                ),
              ),
              const SizedBox(width: 15),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AccountPage()));
                },
                child: Text(
                  isUserLoading ? 'Memuat...' : namaUser ?? 'Pengguna',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF222831),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Ringkasan Tugas',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF222831),
              ),
            ),
          ),
          isRingkasanLoading
              ? const Center(child: CircularProgressIndicator())
              : Row(
            children: [
              SummaryCard(count: tugasSelesai.toString(), label: 'Tugas Selesai'),
              const SizedBox(width: 16),
              SummaryCard(count: tugasTertunda.toString(), label: 'Tugas Tertunda'),
            ],
          ),
          const SizedBox(height: 20),
          const ChartSection(),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Tugas dalam 7 Hari Ke Depan', style: TextStyle(fontSize: 14)),
                SizedBox(height: 10),
                WeeklyTaskList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedInView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          Row(
            children: [
              InkWell(
                onTap: handleLogin, // Panggil handleLogin saat di-tap
                child: ClipOval(
                  child: Image.asset(
                    'assets/default_pp.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Klik untuk login',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF222831),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Ringkasan Tugas',
            style: GoogleFonts.poppins(
              color: const Color(0xFF222831),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              SummaryCard(count: '0', label: 'Tugas Selesai'),
              SizedBox(width: 16),
              SummaryCard(count: '0', label: 'Tugas Tertunda'),
            ],
          ),
          SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16), // Padding di dalam container
            decoration: BoxDecoration(
              color: Colors.grey[300], // Warna latar belakang container
              borderRadius: BorderRadius.circular(10), // Ujung container melengkung
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Menempatkan teks dan tombol di ujung yang berlawanan
              children: [
                Text(
                  'Grafik Tugas Selesai',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF222831),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16), // Padding di dalam container
            decoration: BoxDecoration(
              color: Colors.grey[300], // Warna latar belakang container
              borderRadius: BorderRadius.circular(10), // Ujung container melengkung
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Menempatkan teks dan tombol di ujung yang berlawanan
              children: [
                Text(
                  'Tugas dalam 7 Hari ke Depan',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF222831),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1),
          Container(
            width: double.infinity, // Lebar container mengisi layar
            padding: const EdgeInsets.all(16), // Padding di sekitar teks
            child: GestureDetector(
              onTap: handleLogin, // Panggil fungsi handleLogin ketika teks diklik
              child: Text(
                "Login untuk fitur yang lebih lengkap",
                textAlign: TextAlign.center, // Mengatur alignment teks ke tengah
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  decoration: TextDecoration.underline, // Menambahkan garis bawah
                  color: Color(0xFF222831), // Warna teks (opsional)
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF222831)
      ),
    );
  }
}
