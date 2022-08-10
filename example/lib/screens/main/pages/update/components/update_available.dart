import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Center buildUpdateAvailableWidget({
  required BuildContext context,
  required String availableVersion,
  required String currentVersion,
  required void Function() updateApplication,
}) =>
    Center(
      child: Flex(
        mainAxisAlignment: MainAxisAlignment.center,
        direction: MediaQuery.of(context).size.width < 400
            ? Axis.vertical
            : Axis.horizontal,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'New Version Available!',
                style: GoogleFonts.openSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                '$availableVersion > $currentVersion',
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
          const SizedBox(
            width: 30,
            height: 12,
          ),
          IconButton(
            iconSize: 38,
            icon: const Icon(
              Icons.download,
              color: Colors.green,
            ),
            onPressed: updateApplication,
          ),
        ],
      ),
    );
