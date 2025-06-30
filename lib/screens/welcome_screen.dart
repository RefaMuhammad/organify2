import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home/home.dart';


class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFF1F0E8), // Warna latar belakang
        child: Padding(
          padding: const EdgeInsets.only(top: 50.0), // Jarak dari atas layar
          child: Column(
            mainAxisSize: MainAxisSize.max, // Kolom hanya selebar kontennya
            crossAxisAlignment: CrossAxisAlignment.center, // Pusatkan secara horizontal
            children: [
              const SizedBox(height: 20),
              Text(
                'Organify',
                style: GoogleFonts.poppins(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20), // Jarak antar elemen
              Image.asset('assets/filling_survey.png'),
              const SizedBox(height: 20), // Jarak antar elemen
              Text(
                'Selamat Datang di Organify',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10), // Jarak antar elemen
              Container(
                margin: const EdgeInsets.only(left: 50.0, right: 50.0),
                child: Text(
                  'Atur, rencanakan dan capai tujuanmu dengan mudah. Hidup lebih terorganisasi dimulai dari sini.',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 65), // Jarak antara teks dan tombol
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(
                        onLogin: () {
                          // Tindakan ketika login berhasil
                          print("Login berhasil di HomeScreen");
                        },
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF222831), // Warna tombol
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40.0, vertical: 12.0), // Ukuran tombol
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Ayo Mulai!',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Warna teks tombol
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
