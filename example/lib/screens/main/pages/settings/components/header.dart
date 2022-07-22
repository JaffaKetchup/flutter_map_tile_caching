import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Header extends StatelessWidget {
  const Header({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Text(
        'App Settings',
        style: GoogleFonts.openSans(
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      );
}
