import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Header extends StatelessWidget {
  const Header({
    super.key,
  });

  @override
  Widget build(BuildContext context) => Text(
        'Recovery',
        style: GoogleFonts.openSans(
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      );
}
