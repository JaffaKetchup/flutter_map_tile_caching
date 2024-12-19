import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../shared/state/download_provider.dart';

class ConfirmCancellationDialog extends StatefulWidget {
  const ConfirmCancellationDialog({super.key});

  @override
  State<ConfirmCancellationDialog> createState() =>
      _ConfirmCancellationDialogState();
}

class _ConfirmCancellationDialogState extends State<ConfirmCancellationDialog> {
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) => AlertDialog.adaptive(
        icon: const Icon(Icons.cancel),
        title: const Text('Cancel download?'),
        content: const Text('Any tiles already downloaded will not be removed'),
        actions: _isCancelling
            ? [const CircularProgressIndicator.adaptive()]
            : [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Continue download'),
                ),
                FilledButton(
                  onPressed: () async {
                    setState(() => _isCancelling = true);
                    await context.read<DownloadingProvider>().cancel();
                    if (context.mounted) Navigator.of(context).pop(true);
                  },
                  child: const Text('Cancel download'),
                ),
              ],
      );
}
