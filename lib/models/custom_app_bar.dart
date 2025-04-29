import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget{
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Brightness.light == Theme.of(context).brightness ? const Color.fromARGB(100, 255, 255, 255) : const Color.fromARGB(99, 0, 0, 0),
      padding: const EdgeInsets.fromLTRB(20, 10, 5, 10),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Photos',
              style: TextStyle(
                color: Brightness.light == Theme.of(context).brightness ? Colors.black : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}