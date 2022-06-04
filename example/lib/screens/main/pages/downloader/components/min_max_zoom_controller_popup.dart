import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/state/download_provider.dart';

class MinMaxZoomControllerPopup extends StatelessWidget {
  const MinMaxZoomControllerPopup({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          top: 12,
          left: 12,
          right: 12,
          bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Consumer<DownloadProvider>(
          child: Text(
            'Change Min/Max Zoom Levels',
            style: GoogleFonts.openSans(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          builder: (context, provider, child) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              child!,
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.zoom_out),
                  label: Text('Minimum Zoom Level'),
                ),
                validator: (input) {
                  if (input == null || input.isEmpty || int.parse(input) < 1) {
                    return 'Must be 1 or more';
                  }
                  return null;
                },
                onChanged: (input) {
                  final int parsed = int.parse(input);

                  if (input.isEmpty || parsed < 1) return;
                  provider.minZoom = parsed;
                },
                keyboardType: TextInputType.number,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                initialValue: provider.minZoom.toString(),
              ),
              const SizedBox(height: 5),
              TextFormField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.zoom_in),
                  label: Text('Maximum Zoom Level'),
                ),
                validator: (input) {
                  if (input == null || input.isEmpty) return 'Required';
                  return null;
                },
                onChanged: (input) {
                  if (input.isNotEmpty) provider.maxZoom = int.parse(input);
                },
                keyboardType: TextInputType.number,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.done,
                initialValue: provider.maxZoom.toString(),
              ),
            ],
          ),
        ),
      );
}
