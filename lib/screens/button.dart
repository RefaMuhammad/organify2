import 'package:flutter/material.dart';
import 'package:popover/popover.dart';
import 'package:organify/screens/menu_items.dart';

class MyButton extends StatefulWidget {
  const MyButton({super.key});

  @override
  State<MyButton> createState() => _MyButtonState();
}

class _MyButtonState extends State<MyButton> {
  Color flagColor = Colors.black; // Default warna hitam

  void updateFlagColor(Color newColor) {
    setState(() {
      flagColor = newColor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showPopover(
        context: context,
        bodyBuilder: (context) => MenuItems(
          selectedColor: flagColor,
          onColorSelected: updateFlagColor,
        ),
        width: 250,
        height: 150,
      ),
      child: Icon(Icons.flag, color: flagColor),
    );
  }
}