import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuItems extends StatefulWidget {
  final Color selectedColor;
  final Function(Color) onColorSelected;

  const MenuItems({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  State<MenuItems> createState() => _MenuItemsState();
}

class _MenuItemsState extends State<MenuItems> {
  late Color selectedFlagColor;

  @override
  void initState() {
    super.initState();
    selectedFlagColor = widget.selectedColor;
  }

  void _onFlagSelected(Color color) {
    setState(() {
      selectedFlagColor = color;
    });
    widget.onColorSelected(color); // Panggil callback untuk update parent
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mark with symbol',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF222831),
                ),
              ),
              Icon(
                Icons.flag,
                color: selectedFlagColor,
                size: 24,
              ),
            ],
          ),

          const SizedBox(height: 16),
          Text('Flag',
              style: GoogleFonts.poppins(
                  fontSize: 12
              )
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Ganti ke spaceEvenly
            children: [
              _buildSelectableFlagIcon(Colors.black),
              _buildSelectableFlagIcon(Colors.pink),
              _buildSelectableFlagIcon(Colors.amber),
              _buildSelectableFlagIcon(Colors.purple),
              _buildSelectableFlagIcon(Colors.blue),
              _buildSelectableFlagIcon(Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  // Kemudian ubah method _buildSelectableFlagIcon
  Widget _buildSelectableFlagIcon(Color color) {
    return GestureDetector(
      onTap: () => _onFlagSelected(color),
      child: Icon(
        Icons.flag,
        color: color,
        size: 24,
      ),
    );
  }
}