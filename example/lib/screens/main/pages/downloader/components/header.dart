import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/state/general_provider.dart';

class Header extends StatelessWidget {
  const Header({
    super.key,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Downloader',
                style: GoogleFonts.openSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              Consumer<GeneralProvider>(
                builder: (context, provider, _) => provider.currentStore == null
                    ? const SizedBox.shrink()
                    : const Text(
                        'Existing tiles will appear in red',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
              ),
            ],
          ),
        ],
      );
}
