part of 'button.dart';

class _ExportingProgressDialog extends StatelessWidget {
  const _ExportingProgressDialog();

  @override
  Widget build(BuildContext context) => const AlertDialog.adaptive(
        icon: Icon(Icons.send_and_archive),
        title: Text('Export in progress'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator.adaptive(),
            SizedBox(height: 12),
            Text(
              "Please don't close this dialog or leave the app.\nThe operation "
              "will continue if the dialog is closed.\nWe'll let you know once "
              "we're done.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
