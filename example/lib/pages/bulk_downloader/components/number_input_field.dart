import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Expanded numberInputField({
  required String label,
  required void Function(String) onChanged,
  TextEditingController? controller,
}) {
  return Expanded(
    child: TextFormField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(signed: true, decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9\.\-]')),
      ],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    ),
  );
}
