import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/state/general_provider.dart';

class Header extends StatelessWidget {
  const Header({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stores',
                style: GoogleFonts.openSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              Consumer<GeneralProvider>(
                builder: (context, provider, _) => provider.currentStore == null
                    ? const Text('Caching Disabled')
                    : Text('Current Store: ${provider.currentStore}'),
              ),
            ],
          ),
          const Spacer(),
          Consumer<GeneralProvider>(
            child: const Icon(Icons.cancel),
            builder: (context, provider, icon) => IconButton(
              icon: icon!,
              tooltip: 'Disable Caching',
              onPressed: provider.currentStore == null
                  ? null
                  : () => provider.currentStore = null,
            ),
          ),
        ],
      );
}
