import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:organify/screens/home/home.dart';
import 'package:organify/sqlite/database_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';



class SignPage extends StatefulWidget {
  final VoidCallback onLogin;

  const SignPage({
    Key? key,
    required this.onLogin,
  }) : super(key: key);

  @override
  _SignPageState createState() => _SignPageState();
}

class _SignPageState extends State<SignPage> {
  bool isLoggedIn = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLoginStatus();
  }

  Future<void> _loadLoginStatus() async {
    final data = await DatabaseHelper.instance.getLoginStatus(1);
    setState(() {
      isLoggedIn = data?['is_logged_in'] == 1;
      isLoading = false;
    });
  }


  void toggleSignInSignUp() {
    setState(() {
      isLoggedIn = !isLoggedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF1F0E8),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF1F0E8),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: !isLoggedIn
              ? SignInWidget(
            onSwitch: toggleSignInSignUp,
            onLoginSuccess: (bool success) {
              if (success) {
                widget.onLogin();// panggil fungsi login dari MyApp
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(onLogin: () {}),
                  ),
                );
              }
            },
          )
              : SignUpWidget(onSwitch: toggleSignInSignUp),
        ),
      ),
    );
  }
}

class SignInWidget extends StatelessWidget {
  final VoidCallback onSwitch;
  final Function(bool) onLoginSuccess;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();


  SignInWidget({
    Key? key,
    required this.onSwitch,
    required this.onLoginSuccess,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF222831),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Login Form',
            style: GoogleFonts.poppins(
              color: Color(0xFFF1F0E8),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFF1F0E8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF4E6167),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text(
                        'Login',
                        style: GoogleFonts.poppins(
                          color: Color(0xFFF1F0E8),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onSwitch,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F0E8),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: Text(
                          'Sign Up',
                          style: GoogleFonts.poppins(
                            color: Color(0xFF4E6167),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: emailController,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF4F4F4),
              hintText: 'Email',
              hintStyle: GoogleFonts.poppins(
                color: Color(0xFF4E6167),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF4F4F4),
              hintText: 'Password',
              hintStyle: GoogleFonts.poppins(
                color: Color(0xFF4E6167),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              final email = emailController.text.trim();
              final password = passwordController.text.trim();

              final response = await http.post(
                Uri.parse('https://supabase-organify.vercel.app/login'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'email': email,
                  'password': password,
                }),
              );

              if (response.statusCode == 200) {
                final data = jsonDecode(response.body);
                final token = data['token']; // Simpan token jika perlu untuk login sesi selanjutnya

                // Simpan ke SQLite, termasuk token
                await DatabaseHelper.instance.upsertLoginStatus(
                  1,
                  true,
                  false,
                  authToken: token,
                );
                onLoginSuccess(true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Login gagal! Periksa email dan password')),
                );
              }
            },
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF4E6167),
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Center(
                child: Text(
                  'Login',
                  style: GoogleFonts.poppins(
                    color: Color(0xFFF1F0E8),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SignUpWidget extends StatefulWidget {
  final VoidCallback onSwitch;

  const SignUpWidget({Key? key, required this.onSwitch}) : super(key: key);

  @override
  State<SignUpWidget> createState() => _SignUpWidgetState();
}

class _SignUpWidgetState extends State<SignUpWidget> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> handleSignUp() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Semua field wajib diisi, dan password minimal 6 karakter")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse('https://supabase-organify.vercel.app/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nama': name,
        'email': email,
        'password': password,
      }),
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sign up berhasil! Silakan cek email untuk verifikasi dan lanjut login.")),
      );
      widget.onSwitch(); // Switch ke halaman login
    } else {
      final message = jsonDecode(response.body)['message'] ?? 'Terjadi kesalahan saat sign up';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF222831),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sign Up Form',
                  style: GoogleFonts.poppins(
                    color: Color(0xFFF1F0E8),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Tab switch
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF1F0E8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: widget.onSwitch,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F0E8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: Text(
                                'Login',
                                style: GoogleFonts.poppins(
                                  color: Color(0xFF4E6167),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF4E6167),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: Text(
                              'Sign Up',
                              style: GoogleFonts.poppins(
                                color: Color(0xFFF1F0E8),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Nama
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF4F4F4),
                    hintText: 'Nama Lengkap',
                    hintStyle: GoogleFonts.poppins(
                      color: Color(0xFF4E6167),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // Email
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF4F4F4),
                    hintText: 'Email',
                    hintStyle: GoogleFonts.poppins(
                      color: Color(0xFF4E6167),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // Password
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF4F4F4),
                    hintText: 'Password',
                    hintStyle: GoogleFonts.poppins(
                      color: Color(0xFF4E6167),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Button
                GestureDetector(
                  onTap: isLoading ? null : handleSignUp,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4E6167),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Center(
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                        'Sign Up',
                        style: GoogleFonts.poppins(
                          color: Color(0xFFF1F0E8),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}