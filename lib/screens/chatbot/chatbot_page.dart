import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  DateTime? _lastRequestTime;

  // URL Railway API Anda
  static const String railwayApiUrl = 'https://organify-chatbot-production.up.railway.app';

  // --- PERUBAHAN 1: Definisikan jawaban hardcoded untuk Organify ---
  static const String organifyAnswer = "Organify adalah aplikasi to do list yang dapat membantu hari hari anda menjadi lebih mudah dengan fitur yang dapat anda atur sesuai dengan keinginan. Organify hadir dengan fitur-fitur utama seperti manajemen akun, pengelolaan tugas berdasarkan kategori, ringkasan mingguan, serta perencanaan tujuh hari ke depan.";

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      message: "Halo! Saya Organify Bot 🤖\n\nSelamat datang di Organify - aplikasi terbaik untuk mengatur waktu dan meningkatkan produktivitas Anda! Ada yang bisa saya bantu?",
      isBot: true,
      time: _getCurrentTime(),
    ));
    _checkApiHealth();
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _checkApiHealth() async {
    // ... (fungsi ini tidak diubah)
    try {
      final response = await http.get(
        Uri.parse('$railwayApiUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] != 'healthy' || !data['model_loaded']) {
          if (mounted) {
            setState(() {
              _messages.add(ChatMessage(
                message: "⚠️ Model sedang loading. Silakan tunggu sebentar dan coba lagi.",
                isBot: true,
                time: _getCurrentTime(),
              ));
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            message: "⚠️ Koneksi ke server bermasalah. Pastikan internet Anda stabil.",
            isBot: true,
            time: _getCurrentTime(),
          ));
        });
      }
    }
  }

  // --- PERUBAHAN 2: Fungsi _sendMessage dibuat lebih pintar ---
  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Tambahkan pesan pengguna ke UI terlebih dahulu
    setState(() {
      _messages.add(ChatMessage(
        message: message,
        isBot: false,
        time: _getCurrentTime(),
      ));
    });
    _scrollToBottom();
    _messageController.clear();

    // --- Logika Khusus untuk Shortcut ---
    // Jika user mengklik "Apa itu Organify?"
    if (message == "Apa itu Organify?") {
      // Langsung tampilkan jawaban hardcoded tanpa loading
      setState(() {
        _messages.add(ChatMessage(
          message: organifyAnswer,
          isBot: true,
          time: _getCurrentTime(),
        ));
      });
      _scrollToBottom();
      return; // Hentikan fungsi di sini, jangan panggil API
    }

    // Rate limiting
    if (_lastRequestTime != null &&
        DateTime.now().difference(_lastRequestTime!).inSeconds < 3) {
      setState(() {
        _messages.add(ChatMessage(
          message: "Silakan tunggu sebentar sebelum mengirim pesan berikutnya.",
          isBot: true,
          time: _getCurrentTime(),
        ));
      });
      _scrollToBottom();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _lastRequestTime = DateTime.now();

    // --- Logika Terjemahan untuk Shortcut Lain ---
    String promptToSend = message; // Defaultnya, kirim pesan asli
    if (message == "Sekarang tanggal berapa?") {
      promptToSend = "What date is it today?";
    } else if (message == "Quotes of the day!") {
      promptToSend = "Give me a quote of the day about productivity";
    }

    try {
      // Kirim prompt yang sudah dimodifikasi (jika ada) ke API
      final response = await sendMessageToRailway(promptToSend);

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            message: response,
            isBot: true,
            time: _getCurrentTime(),
          ));
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          String errorMessage;
          if (e.toString().contains('TimeoutException')) {
            errorMessage = "⏰ Maaf, server membutuhkan waktu terlalu lama untuk merespons.";
          } else {
            errorMessage = "❌ Terjadi kesalahan: ${e.toString()}";
          }
          _messages.add(ChatMessage(
            message: errorMessage,
            isBot: true,
            time: _getCurrentTime(),
          ));
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _scrollToBottom();
    }
  }

  Future<String> sendMessageToRailway(String message) async {
    // ... (fungsi ini tidak diubah)
    try {
      print('Sending request to: $railwayApiUrl/chat');
      print('Message: $message');
      final response = await http.post(
        Uri.parse('$railwayApiUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      ).timeout(const Duration(seconds: 60));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('response')) {
          String botResponse = data['response'].toString().trim();
          if (botResponse.isEmpty) return "Maaf, saya tidak bisa merespons itu.";
          return botResponse;
        } else {
          return "Maaf, terjadi kesalahan dalam memahami respons.";
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
      throw Exception(e.toString());
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- PERUBAHAN 3: Widget baru untuk menampilkan tombol shortcut ---
  Widget _buildShortcutChips() {
    final shortcuts = [
      "Apa itu Organify?",
      "Sekarang tanggal berapa?",
      "Quotes of the day!",
    ];

    return Container(
      height: 50.0, // Kita beri tinggi yang pasti untuk list horizontal ini
      child: ListView.builder(
        scrollDirection: Axis.horizontal, // Properti kunci: membuat list bisa digeser ke samping
        padding: const EdgeInsets.only(left: 12.0), // Beri sedikit padding di awal list
        itemCount: shortcuts.length,
        itemBuilder: (context, index) {
          final text = shortcuts[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0), // Jarak antar tombol
            child: ActionChip(
              label: Text(text),
              onPressed: () => _sendMessage(text),
              backgroundColor: const Color(0xFFE0E0E0),
              labelStyle: const TextStyle(color: Colors.black87, fontSize: 13), // Ukuran font sedikit dikecilkan
              padding: const EdgeInsets.symmetric(horizontal: 12.0), // Padding di dalam tombol
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F0E8),
      appBar: AppBar(
        // ... (bagian ini tidak diubah)
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Organify Bot"),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _isLoading ? Colors.orange : Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFB3C8CF),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkApiHealth,
            tooltip: 'Check API Status',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              // ... (bagian ini tidak diubah)
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.isBot
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    decoration: BoxDecoration(
                      color: message.isBot
                          ? const Color(0xFF1E1E2D)
                          : const Color(0xFFB3C8CF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.message,
                          style: TextStyle(
                            color: message.isBot ? Colors.white : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message.time,
                          style: TextStyle(
                            color: message.isBot
                                ? Colors.white70
                                : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // --- PERUBAHAN 4: Tambahkan shortcut chips di atas input bar ---
          _buildShortcutChips(),
          if (_isLoading)
          // ... (bagian ini tidak diubah)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E1E2D)),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Bot sedang mengetik...",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.only(
                left: 16, right: 8, top: 8, bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: _isLoading
                          ? "Tunggu response..."
                          : "Ketik pesan...",
                      filled: true,
                      fillColor: const Color(0xFFF1F0E8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (value) => _sendMessage(value),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.send_rounded,
                    color: _isLoading
                        ? Colors.grey
                        : const Color(0xFF1E1E2D),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () => _sendMessage(_messageController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String message;
  final bool isBot;
  final String time;

  ChatMessage({
    required this.message,
    required this.isBot,
    required this.time,
  });
}