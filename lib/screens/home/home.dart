import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:organify/screens/tugas_selesai/listTugasSelesai_page.dart';
import 'package:organify/screens/home/sections/task_section.dart';
import 'package:organify/screens/home/sections/home_appbar.dart';
import 'package:organify/screens/task_item.dart';
import '../bottom_navbar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:organify/sqlite/database_helper.dart';
import 'package:organify/screens/home/sections/home_searchbar.dart';
import 'package:organify/screens/home/sections/chip_category_row.dart';
import 'package:organify/screens/home/sections/home_drawer.dart';

import '../chatbot/chatbot_page.dart';

class Catatan {
  final int id;
  final String namaList;
  final DateTime tanggalDeadline;
  final bool status;
  final String kategori;

  Catatan({
    required this.id,
    required this.namaList,
    required this.tanggalDeadline,
    required this.status,
    required this.kategori,
  });

  factory Catatan.fromJson(Map<String, dynamic> json) {
    return Catatan(
      id: json['id'],
      namaList: json['nama_list'],
      tanggalDeadline: DateTime.parse(json['tanggal_deadline']).toLocal(),
      status: json['status'] ?? false,
      kategori: json['kategori'] ?? 'Tidak Diketahui',
    );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback onLogin;
  const HomeScreen({Key? key, required this.onLogin}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isPreviousExpanded = false;
  bool _isTodayExpanded = false;
  bool _isUpcomingExpanded = false;
  int _selectedIndex = 0;
  late final VoidCallback login;
  bool _showSearchBar = false;
  bool isLoggedIn = false;
  bool isLoading = true;
  String selectedCategory = 'Semua';

  List<Catatan> allCatatan = [];
  List<Catatan> sebelumnya = [];
  List<Catatan> hariIni = [];
  List<Catatan> akanDatang = [];
  List<Catatan> hasilPencarian = [];

  @override
  void initState() {
    super.initState();
    login = widget.onLogin;
    _loadLoginStatus();
  }

  Future<void> _loadLoginStatus() async {
    final data = await DatabaseHelper.instance.getLoginStatus(1);
    setState(() {
      isLoggedIn = data?['is_logged_in'] == 1;
      isLoading = false;
    });
    if (isLoggedIn) fetchCatatan();
  }

  Future<void> fetchCatatan() async {
    try {
      final token = await DatabaseHelper.instance.getToken(1);
      if (token == null) return;

      final response = await http.get(
        Uri.parse('https://supabase-organify.vercel.app/catatan'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> data = body['data'];
        final List<Catatan> all = data
            .map((json) => Catatan.fromJson(json))
            .where((catatan) => catatan.status == false)
            .toList();


        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        setState(() {
          allCatatan = all;
          _filterByCategory(selectedCategory);
        });
      }
    } catch (e) {
      print('❌ Error fetching catatan: $e');
    }
  }

  void _filterByCategory(String category) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<Catatan> filtered = category == 'Semua'
        ? allCatatan
        : allCatatan.where((c) => c.kategori == category).toList();

    setState(() {
      selectedCategory = category;
      sebelumnya = filtered.where((c) => c.tanggalDeadline.isBefore(today)).toList();
      hariIni = filtered.where((c) =>
      c.tanggalDeadline.year == now.year &&
          c.tanggalDeadline.month == now.month &&
          c.tanggalDeadline.day == now.day).toList();
      akanDatang = filtered.where((c) => c.tanggalDeadline.isAfter(today)).toList();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) fetchCatatan();
  }

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        hasilPencarian = [];
      }
    });
  }

  Future<void> _launchEmail() async {
    final Uri mailtoUri = Uri(
      scheme: 'mailto',
      path: 'septianworkingemail@gmail.com',
      queryParameters: {
        'subject': 'Masukan Aplikasi Organify',
        'body': 'Tulis feedback Anda di sini...',
      },
    );

    if (await canLaunchUrl(mailtoUri)) {
      await launchUrl(mailtoUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka aplikasi email.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F0E8),
      appBar: const HomeAppBar(),
      drawer: HomeDrawer(
        isLoggedIn: isLoggedIn,
        onLogin: () {
          setState(() {
            login();
            _loadLoginStatus();
          });
        },
        launchEmail: _launchEmail,
        onCategorySelected: (selected) {
          if (_showSearchBar) {
            setState(() {
              _showSearchBar = false;
              hasilPencarian = [];
            });
          }
          _filterByCategory(selected);
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _showSearchBar
                ? HomeSearchBar(
              onClose: _toggleSearchBar,
              onSearch: (String value) {
                final query = value.toLowerCase();
                final filtered = allCatatan
                    .where((catatan) => catatan.namaList.toLowerCase().contains(query))
                    .toList();
                setState(() {
                  hasilPencarian = filtered;
                });
              },
            )
                : ChipCategoryRow(
              onSearchTap: _toggleSearchBar,
              onCategorySelected: _filterByCategory,
              selectedCategory: selectedCategory,
            ),

            // SECTION HASIL PENCARIAN
            if (_showSearchBar)
              TaskSection(
                title: 'Hasil Pencarian',
                isExpanded: true,
                onTap: () {},
                tasks: hasilPencarian
                    .map((catatan) => TaskItem(
                  taskId: catatan.id,
                  taskName: catatan.namaList,
                  deadline: catatan.tanggalDeadline.toIso8601String().split('T').first,
                ))
                    .toList(),
              )
            else ...[
              // SECTION SEBELUMNYA
              TaskSection(
                title: 'Sebelumnya',
                isExpanded: _isPreviousExpanded,
                onTap: () => setState(() => _isPreviousExpanded = !_isPreviousExpanded),
                tasks: sebelumnya
                    .map((catatan) => TaskItem(
                  taskName: catatan.namaList,
                  taskId: catatan.id,
                  deadline: catatan.tanggalDeadline.toIso8601String().split('T').first,
                ))
                    .toList(),
              ),

              // SECTION HARI INI
              TaskSection(
                title: 'Hari Ini',
                isExpanded: _isTodayExpanded,
                onTap: () => setState(() => _isTodayExpanded = !_isTodayExpanded),
                tasks: hariIni
                    .map((catatan) => TaskItem(
                  taskId: catatan.id,
                  taskName: catatan.namaList,
                  deadline: catatan.tanggalDeadline.toIso8601String().split('T').first,
                ))
                    .toList(),
              ),

              // SECTION AKAN DATANG
              TaskSection(
                title: 'Yang Akan Datang',
                isExpanded: _isUpcomingExpanded,
                onTap: () => setState(() => _isUpcomingExpanded = !_isUpcomingExpanded),
                tasks: akanDatang
                    .map((catatan) => TaskItem(
                  taskId: catatan.id,
                  taskName: catatan.namaList,
                  deadline: catatan.tanggalDeadline.toIso8601String().split('T').first,
                ))
                    .toList(),
              ),
            ],

            // LINK TUGAS SELESAI
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TugasSelesaiPage()),
                ),
                child: Text(
                  "Periksa semua tugas yang telah selesai",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w400,
                    fontSize: 10,
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.solid,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4E6167),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatbotScreen()),
          );
        },
        child: Image.asset(
          'assets/chatbot.png',
          width: 50,
          height: 50,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
