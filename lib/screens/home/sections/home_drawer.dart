import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:organify/screens/sign_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class HomeDrawer extends StatefulWidget {
  final bool isLoggedIn;
  final VoidCallback onLogin;
  final VoidCallback launchEmail;
  final ValueChanged<String> onCategorySelected;

  const HomeDrawer({
    Key? key,
    required this.isLoggedIn,
    required this.onLogin,
    required this.launchEmail,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<List<dynamic>> fetchAllCatatan(String token) async {
    final response = await http.get(
      Uri.parse('https://supabase-organify.vercel.app/catatan'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return jsonData['data'];
    } else {
      print("Gagal ambil catatan. Status: ${response.statusCode}");
      return [];
    }
  }

  Future<void> fetchCategories() async {
    try {
      final Database db = await openDatabase(
        path.join(await getDatabasesPath(), 'organify.db'),
      );

      final List<Map<String, dynamic>> result = await db.query(
        'login_status',
        limit: 1,
      );

      if (result.isEmpty || result[0]['auth_token'] == null) {
        setState(() {
          categories = [];
          isLoading = false;
        });
        return;
      }

      final String token = result[0]['auth_token'];

      final List<dynamic> allCatatan = await fetchAllCatatan(token);

      final Map<String, int> jumlahPerKategori = {};
      int totalBelumSelesai = 0;

      for (var item in allCatatan) {
        final kategori = item['kategori'] ?? 'Tidak Diketahui';
        final status = item['status'] ?? false;

        if (status == false) {
          jumlahPerKategori[kategori] = (jumlahPerKategori[kategori] ?? 0) + 1;
          totalBelumSelesai++;
        }
      }

      final response = await http.get(
        Uri.parse('https://supabase-organify.vercel.app/kategori'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> kategoriList = jsonDecode(response.body)['data'];

        setState(() {
          categories = [
            {
              'kategori': 'Semua',
              'jumlahCatatan': totalBelumSelesai,
            },
            ...kategoriList.map<Map<String, dynamic>>((item) {
              final k = item['kategori'];
              return {
                'kategori': k,
                'jumlahCatatan': jumlahPerKategori[k] ?? 0,
              };
            }),
          ];
          isLoading = false;
        });
      } else {
        setState(() {
          categories = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() {
        categories = [];
        isLoading = false;
      });
    }
  }

  Future<void> createCategory(String newCategory) async {
    try {
      final Database db = await openDatabase(
        path.join(await getDatabasesPath(), 'organify.db'),
      );

      final List<Map<String, dynamic>> result = await db.query(
        'login_status',
        limit: 1,
      );

      if (result.isEmpty || result[0]['auth_token'] == null) return;

      final String token = result[0]['auth_token'];

      final response = await http.post(
        Uri.parse('https://supabase-organify.vercel.app/kategori'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'kategori': newCategory}),
      );

      if (response.statusCode == 201) {
        await fetchCategories();
      }
    } catch (e) {
      print('Error saat menambahkan kategori: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF222831)),
            child: Center(
              child: Text(
                'Organify',
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          ExpansionTile(
            leading: const Icon(Icons.grid_view, color: Colors.black),
            title: Text('Kategori', style: GoogleFonts.poppins(fontSize: 15)),
            trailing: const Icon(Icons.keyboard_arrow_up, color: Colors.black),
            children: [
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else ...[
                for (var kategori in categories)
                  _buildCategoryTile(
                    kategori['kategori'],
                    kategori['jumlahCatatan']?.toString() ?? '0',
                  ),
              ],
              ListTile(
                leading: const Icon(Icons.add, color: Colors.black),
                title: Text('Buat Baru', style: GoogleFonts.poppins(fontSize: 15)),
                onTap: _handleBuatBaru,
              ),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.feedback, color: Colors.black),
            title: const Text('Masukan'),
            onTap: widget.launchEmail,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(String title, String count) {
    return ListTile(
      title: Text(title, style: GoogleFonts.poppins(fontSize: 13)),
      trailing: Text(count, style: const TextStyle(color: Colors.black)),
      onTap: () {
        Navigator.pop(context);
        widget.onCategorySelected(title);
      },
    );
  }

  void _handleBuatBaru() {
    if (!widget.isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignPage(onLogin: widget.onLogin),
        ),
      );
    } else {
      String? newCategory;
      bool isInputFilled = false;

      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (BuildContext builderContext, StateSetter setStateDialog) {
              return AlertDialog(
                title: Text('Buat Kategori Baru', style: GoogleFonts.poppins(fontSize: 16)),
                content: TextField(
                  onChanged: (value) {
                    setStateDialog(() {
                      newCategory = value;
                      isInputFilled = value.trim().isNotEmpty;
                    });
                  },
                  maxLength: 50,
                  decoration: const InputDecoration(
                    hintText: 'Ketik disini',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: isInputFilled
                        ? () async {
                      Navigator.pop(context);
                      await createCategory(newCategory!.trim());
                    }
                        : null,
                    child: const Text('Simpan'),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }
}
