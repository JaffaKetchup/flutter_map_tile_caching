import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Header extends StatelessWidget {
  const Header({
    Key? key,
    required this.title,
  }) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: GoogleFonts.openSans(
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      );
}
