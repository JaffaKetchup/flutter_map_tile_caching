part of 'button.dart';

class _ExportingNameInputDialog extends StatefulWidget {
  const _ExportingNameInputDialog({
    required this.defaultName,
    required this.tempDir,
  });

  final String defaultName;
  final String tempDir;

  @override
  State<_ExportingNameInputDialog> createState() =>
      _ExportingNameInputDialogState();
}

class _ExportingNameInputDialogState extends State<_ExportingNameInputDialog> {
  final inputController = TextEditingController();

  bool invalidFilename = false;

  @override
  Widget build(BuildContext context) => AlertDialog.adaptive(
        icon: const Icon(Icons.send_and_archive),
        title: const Text('Choose archive name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: inputController,
              decoration: InputDecoration(
                hintText: widget.defaultName,
                suffixText: '.fmtc',
                errorText: invalidFilename ? 'Invalid filename' : null,
              ),
              onChanged: (_) => setState(() => invalidFilename = false),
              onFieldSubmitted: (_) => _validateAndFinish(),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            const Text(
              "Once we're done, we'll let you share the exported archive "
              'elsewhere.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _validateAndFinish,
            child: const Text('Export'),
          ),
        ],
      );

  Future<void> _validateAndFinish() async {
    if (inputController.text.isEmpty) {
      Navigator.of(context).pop(widget.defaultName);
      return;
    }

    final file = File(
      p.join(widget.tempDir, '${inputController.text}.fmtc.tmp'),
    );
    try {
      await file.create();
      await file.delete();
    } on FileSystemException {
      setState(() => invalidFilename = true);
      return;
    }

    if (mounted) Navigator.of(context).pop(inputController.text);
  }
}
