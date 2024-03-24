import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class PathPicker extends StatelessWidget {
  const PathPicker({
    super.key,
    required this.pathController,
    required this.onPathChanged,
  });

  final TextEditingController pathController;
  final void Function({required bool forceOverrideExisting}) onPathChanged;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Theme.of(context).platform == TargetPlatform.linux ||
        Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.macOS;

    return IntrinsicWidth(
      child: Column(
        children: [
          if (isDesktop)
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await FilePicker.platform.saveFile(
                      type: FileType.custom,
                      allowedExtensions: ['fmtc'],
                      dialogTitle: 'Export To File',
                    );
                    if (picked != null) {
                      pathController.value = TextEditingValue(
                        text: picked,
                        selection: TextSelection.collapsed(
                          offset: picked.length,
                        ),
                      );
                      onPathChanged(forceOverrideExisting: true);
                    }
                  },
                  icon: const Icon(Icons.file_upload_outlined),
                  label: const Text('Export'),
                ),
                const SizedBox.square(dimension: 8),
                SizedBox.square(
                  dimension: 32,
                  child: IconButton.outlined(
                    onPressed: () async {
                      final picked = await FilePicker.platform.getDirectoryPath(
                        dialogTitle: 'Export To Directory',
                      );
                      if (picked != null) {
                        final finalPath = path.join(picked, 'archive.fmtc');

                        pathController.value = TextEditingValue(
                          text: finalPath,
                          selection: TextSelection.collapsed(
                            offset: finalPath.length,
                          ),
                        );

                        onPathChanged(forceOverrideExisting: true);
                      }
                    },
                    iconSize: 16,
                    icon: Icon(
                      Icons.folder,
                      color: Theme.of(context)
                          .buttonTheme
                          .colorScheme!
                          .primaryFixed,
                    ),
                  ),
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: () async {
                if (isDesktop) {
                  final picked = await FilePicker.platform.saveFile(
                    type: FileType.custom,
                    allowedExtensions: ['fmtc'],
                    dialogTitle: 'Export',
                  );
                  if (picked != null) {
                    pathController.value = TextEditingValue(
                      text: picked,
                      selection: TextSelection.collapsed(
                        offset: picked.length,
                      ),
                    );

                    onPathChanged(forceOverrideExisting: true);
                  }
                } else {
                  final picked = await FilePicker.platform.getDirectoryPath(
                    dialogTitle: 'Export',
                  );
                  if (picked != null) {
                    final finalPath = path.join(picked, 'archive.fmtc');

                    pathController.value = TextEditingValue(
                      text: finalPath,
                      selection: TextSelection.collapsed(
                        offset: finalPath.length,
                      ),
                    );

                    onPathChanged(forceOverrideExisting: true);
                  }
                }
              },
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Export'),
            ),
          const SizedBox.square(dimension: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final picked = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['fmtc'],
                  dialogTitle: 'Import',
                );
                if (picked != null) {
                  pathController.value = TextEditingValue(
                    text: picked.files.single.path!,
                    selection: TextSelection.collapsed(
                      offset: picked.files.single.path!.length,
                    ),
                  );

                  onPathChanged(forceOverrideExisting: false);
                }
              },
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Import'),
            ),
          ),
        ],
      ),
    );
  }
}
