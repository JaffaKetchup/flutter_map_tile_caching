import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../../../state/general_provider.dart';

class RenameModal extends StatefulWidget {
  const RenameModal({
    Key? key,
    required this.mcm,
  }) : super(key: key);

  final MapCachingManager mcm;

  @override
  State<RenameModal> createState() => _RenameModalState();
}

class _RenameModalState extends State<RenameModal> {
  String inputted = '';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  helperText: 'Enter a new store name',
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (newVal) => inputted = newVal,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      final MapCachingManager real =
                          Provider.of<GeneralProvider>(context, listen: false)
                              .currentMapCachingManager;

                      if (inputted == '') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('New name must not be empty'),
                          ),
                        );
                        return;
                      }

                      try {
                        widget.mcm.renameStore(inputted);
                        if (widget.mcm.storeName == real.storeName) {
                          real.renameStore(inputted);
                        }
                      } catch (e) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Store must have tiles to be renamed'),
                          ),
                        );
                        return;
                      }

                      MapCachingManager(widget.mcm.parentDirectory,
                          inputted); // Force creation of new cache store

                      Navigator.pop(context);
                      Navigator.popAndPushNamed(context, '/storeManager');
                    },
                    child: const Text('Rename'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
