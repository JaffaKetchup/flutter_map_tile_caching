import 'package:flutter/material.dart';

class ExitDialog extends StatefulWidget {
  const ExitDialog({Key? key}) : super(key: key);

  @override
  _ExitDialogState createState() => _ExitDialogState();
}

class _ExitDialogState extends State<ExitDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Download?'),
      content: const Text(
        'Are you sure you want to cancel the download? It will not be recoverable, and any tiles that have been downloaded will remain downloaded.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text(
            'Keep Downloading',
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: const Text(
            'Cancel & Exit',
          ),
        ),
      ],
    );
  }
}
