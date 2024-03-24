import 'package:flutter/material.dart';

class DirectorySelected extends StatelessWidget {
  const DirectorySelected({super.key});

  @override
  Widget build(BuildContext context) => const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.snippet_folder_rounded, size: 48),
          Text(
            'Input/select a file (not a directory)',
            style: TextStyle(fontSize: 15),
          ),
        ],
      );
}
