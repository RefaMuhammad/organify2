import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:organify/screens/profile/profile_page.dart';
import 'package:organify/screens/sign_page.dart';
import 'package:organify/sqlite/database_helper.dart';
import 'category_button.dart';
import 'calendar_popup.dart';

class BottomNavbar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback? onTaskAdded;

  const BottomNavbar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.onTaskAdded,
  }) : super(key: key);

  @override
  _BottomNavbarState createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
  bool _isLoggedIn = false;
  bool _isLoading = true;

  final TextEditingController _taskController = TextEditingController();
  String selectedKategori = '';
  DateTime? selectedDeadline;
  bool isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadLoginStatus();
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _loadLoginStatus() async {
    final data = await DatabaseHelper.instance.getLoginStatus(1);
    setState(() {
      _isLoggedIn = data?['is_logged_in'] == 1;
      _isLoading = false;
    });
  }

  void _showBtmSheet(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _taskController,
                  decoration: InputDecoration(
                    hintText: 'Buat tugas baru disini',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CategoryButton(
                    onCategoryChanged: (kategori) {
                      setState(() => selectedKategori = kategori);
                    },
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDialog<DateTime>(
                        context: context,
                        builder: (_) => const CalendarPopup(),
                      );
                      if (picked != null) {
                        setState(() => selectedDeadline = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Image.asset(
                        'assets/tombol_kalender.png',
                        width: 35,
                        height: 35,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: isPosting ? null : _submitCatatan,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF828282),
                        shape: BoxShape.circle,
                      ),
                      child: isPosting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitCatatan() async {
    final taskName = _taskController.text.trim();
    if (taskName.isEmpty || selectedKategori.isEmpty || selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Isi semua field")),
      );
      return;
    }

    final token = await DatabaseHelper.instance.getToken(1);
    if (token == null) return;

    setState(() => isPosting = true);

    final response = await http.post(
      Uri.parse('https://supabase-organify.vercel.app/catatan'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'kategori': selectedKategori,
        'nama_list': taskName,
        'tanggal_deadline': selectedDeadline!.toIso8601String(),
      }),
    );

    setState(() => isPosting = false);

    if (response.statusCode == 201) {
      Navigator.pop(context);
      _taskController.clear();
      selectedDeadline = null;
      selectedKategori = '';
      widget.onTaskAdded?.call(); // ⬅️ Tambahkan ini untuk refresh HomeScreen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tugas berhasil ditambahkan")),
      );
    } else {
      final error = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal: ${error['message']}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      child: BottomNavigationBar(
        backgroundColor: const Color(0xFFB3C8CF),
        items: [
          BottomNavigationBarItem(
            icon: GestureDetector(
              onTap: () => widget.onItemTapped(0),
              child: Image.asset('assets/button_home.png', width: 50, height: 50),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: GestureDetector(
              onTap: () {
                if (!_isLoggedIn) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SignPage(
                        onLogin: () {
                          setState(() {
                            _isLoggedIn = true;
                          });
                        },
                      ),
                    ),
                  );
                } else {
                  _showBtmSheet(context);
                }
              },
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF222831),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/button_plus.png',
                  width: 70,
                  height: 70,
                  color: Color(0xFFF1F0E8),
                ),
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(),
                  ),
                );
              },
              child: Image.asset('assets/button_user.png', width: 50, height: 50),
            ),
            label: '',
          ),
        ],
        currentIndex: widget.selectedIndex,
        onTap: widget.onItemTapped,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }
}