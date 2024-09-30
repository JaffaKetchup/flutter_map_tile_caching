import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/state/download_configuration_provider.dart';

class ConfirmCancellationDialog extends StatefulWidget {
  const ConfirmCancellationDialog({super.key});

  @override
  State<ConfirmCancellationDialog> createState() =>
      _ConfirmCancellationDialogState();
}

class _ConfirmCancellationDialogState extends State<ConfirmCancellationDialog> {
  bool isCancelling = false;

  @override
  Widget build(BuildContext context) => AlertDialog.adaptive(
        icon: const Icon(Icons.cancel),
        title: const Text('Cancel download?'),
        content: const Text('Any tiles already downloaded will not be removed'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continue download'),
          ),
          if (isCancelling)
            const CircularProgressIndicator.adaptive()
          else
            FilledButton(
              onPressed: () async {
                setState(() => isCancelling = true);
                await context
                    .read<DownloadConfigurationProvider>()
                    .selectedStore!
                    .download
                    .cancel();
                if (context.mounted) Navigator.of(context).pop(true);
              },
              child: const Text('Cancel download'),
            ),
        ],
      );
}
