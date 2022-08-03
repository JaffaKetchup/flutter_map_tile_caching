import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/state/download_provider.dart';

class Header extends StatefulWidget {
  const Header({
    Key? key,
  }) : super(key: key);

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  bool cancelled = false;

  @override
  Widget build(BuildContext context) => Consumer<DownloadProvider>(
        builder: (context, provider, _) => Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Downloading',
                    style: GoogleFonts.openSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    'Downloading To: ${provider.selectedStore?.storeName ?? '<in test mode>'}',
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            IconButton(
              icon: const Icon(Icons.cancel),
              tooltip: 'Cancel Download',
              onPressed: cancelled
                  ? null
                  : () async {
                      await FMTC
                          .instance(provider.selectedStore!.storeName)
                          .download
                          .cancel();
                      setState(() => cancelled = true);
                    },
            ),
          ],
        ),
      );
}
