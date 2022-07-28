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
                  if (input == null || input.isEmpty) return 'Required';
                  if (int.parse(input) < 1) return 'Must be 1 or more';
                  if (int.parse(input) > provider.maxZoom) {
                    return 'Must be less than maximum zoom';
                  }

                  return null;
                },
                onChanged: (input) {
                  if (input.isNotEmpty) provider.minZoom = int.parse(input);
                },
                keyboardType: TextInputType.number,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _NumericalRangeFormatter(min: 1, max: 22),
                ],
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
                  if (int.parse(input) > 22) return 'Must be 22 or less';
                  if (int.parse(input) < provider.minZoom) {
                    return 'Must be more than minimum zoom';
                  }

                  return null;
                },
                onChanged: (input) {
                  if (input.isNotEmpty) provider.maxZoom = int.parse(input);
                },
                keyboardType: TextInputType.number,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _NumericalRangeFormatter(min: 1, max: 22),
                ],
                textInputAction: TextInputAction.done,
                initialValue: provider.maxZoom.toString(),
              ),
            ],
          ),
        ),
      );
}

class _NumericalRangeFormatter extends TextInputFormatter {
  final int min;
  final int max;

  _NumericalRangeFormatter({
    required this.min,
    required this.max,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      newValue.text == ''
          ? newValue
          : int.parse(newValue.text) < min
              ? TextEditingValue.empty.copyWith(text: min.toString())
              : int.parse(newValue.text) > max
                  ? TextEditingValue.empty.copyWith(text: max.toString())
                  : newValue;
}
