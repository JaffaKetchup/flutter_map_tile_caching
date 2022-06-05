import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/state/general_provider.dart';
import 'min_max_zoom_controller_popup.dart';
import 'shape_controller_popup.dart';

class Header extends StatelessWidget {
  const Header({
    Key? key,
  }) : super(key: key);

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
                    ? const Text('No store selected')
                    : Text('Downloading to ${provider.currentStore}'),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                builder: (_) => const MinMaxZoomControllerPopup(),
              );
            },
            icon: const Icon(Icons.zoom_in),
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                builder: (_) => const ShapeControllerPopup(),
              );
            },
            icon: const Icon(Icons.select_all),
          ),
        ],
      );
}
