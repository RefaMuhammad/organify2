import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:organify/screens/sign_page.dart';
import 'package:organify/screens/welcome_screen.dart';
import 'package:organify/screens/home/home.dart';
import 'package:organify/screens/profile/profile_page.dart';
import 'package:organify/sqlite/database_helper.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Wajib untuk operasi async sebelum runApp

  await initializeDateFormatting('id_ID', null); // <-- Locale

  // 👇 Inisialisasi database untuk memicu onCreate jika belum ada
  await DatabaseHelper.instance.database;

  runApp(MyApp());
}


class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

bool isJwtExpired(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return true;

    final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
    final exp = payload['exp'];

    if (exp == null) return true;

    final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return DateTime.now().isAfter(expiryDate);
  } catch (e) {
    print('JWT decode error: $e');
    return true;
  }
}

class _MyAppState extends State<MyApp> {
  bool isFirstLaunch = true;
  bool isLoggedIn = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLoginStatus();
  }

  Future<void> _loadLoginStatus() async {
    try {
      await DatabaseHelper.instance.database;
      final data = await DatabaseHelper.instance.getLoginStatus(1);

      if (data != null) {
        final token = data['auth_token'] as String?;
        final tokenExpired = token == null || isJwtExpired(token);

        setState(() {
          isFirstLaunch = data['is_first_launch'] == 1;
          isLoggedIn = data['is_logged_in'] == 1 && !tokenExpired;
          _loading = false;
        });

        if (tokenExpired && data['is_logged_in'] == 1) {
          print('Token expired. Logging out...');
          await DatabaseHelper.instance.logoutUser(1);
        }
      } else {
        await DatabaseHelper.instance.upsertLoginStatus(1, false, true);
        setState(() {
          isFirstLaunch = true;
          isLoggedIn = false;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading login status: $e');
      setState(() {
        isFirstLaunch = true;
        isLoggedIn = false;
        _loading = false;
      });
    }
  }


  void login() async {
    try {
      setState(() {
        isLoggedIn = true;
      });
      await DatabaseHelper.instance.upsertLoginStatus(1, true, false);
    } catch (e) {
      print('Error during login: $e');
    }
  }

  void logout() async {
    try {
      setState(() {
        isLoggedIn = false;
      });
      await DatabaseHelper.instance.upsertLoginStatus(1, false, false);
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return MaterialApp(
        title: 'Organify App',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    print("firstLaunch: $isFirstLaunch, isLoggedIn: $isLoggedIn");

    return MaterialApp(
      title: 'Organify App',
      debugShowCheckedModeBanner: false,
      home: _getInitialScreen(),
      routes: {
        '/welcome': (context) => WelcomeScreen(),
        '/home': (context) => _buildHomeScreen(),
        '/profile': (context) => ProfilePage(),
        '/signpage': (context) => _buildSignPage(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => WelcomeScreen(),
        );
      },
    );
  }

  Widget _getInitialScreen() {
    if (isFirstLaunch) {
      return WelcomeScreen();
    } else {
      return isLoggedIn ? _buildHomeScreen() : WelcomeScreen();
    }
  }

  Widget _buildHomeScreen() {
    try {
      return HomeScreen(onLogin: logout);
    } catch (e) {
      print('Error building HomeScreen: $e');
      return Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Terjadi kesalahan saat memuat halaman home'),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/welcome'),
                child: Text('Kembali ke Welcome'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildSignPage() {
    try {
      return SignPage(onLogin: login);
    } catch (e) {
      print('Error building SignPage: $e');
      return Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Terjadi kesalahan saat memuat halaman sign'),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/welcome'),
                child: Text('Kembali ke Welcome'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
