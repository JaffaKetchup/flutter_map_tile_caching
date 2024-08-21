import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../shared/components/url_selector.dart';
import '../../shared/misc/shared_preferences.dart';
import '../../shared/misc/store_metadata_keys.dart';
import '../../shared/state/general_provider.dart';

class StoreEditorPopup extends StatefulWidget {
  const StoreEditorPopup({super.key});

  static const String route = '/storeEditor';

  @override
  State<StoreEditorPopup> createState() => _StoreEditorPopupState();
}

class _StoreEditorPopupState extends State<StoreEditorPopup> {
  final formKey = GlobalKey<FormState>();

  late final String? existingStoreName;
  late final Future<Map<String, String>>? existingMetadata;
  late final Future<int?>? existingMaxLength;
  late final Future<Iterable<String>> existingStores;

  String? newName;
  String? newUrlTemplate;
  int? newMaxLength;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    existingStoreName = ModalRoute.of(context)!.settings.arguments as String?;
    existingMetadata = existingStoreName == null
        ? null
        : FMTCStore(existingStoreName!).metadata.read;
    existingMaxLength = existingStoreName == null
        ? null
        : FMTCStore(existingStoreName!).manage.maxLength;

    existingStores =
        FMTCRoot.stats.storesAvailable.then((l) => l.map((s) => s.storeName));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            existingStoreName == null
                ? 'Create New Store'
                : "Edit '$existingStoreName'",
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Scrollbar(
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    FutureBuilder(
                      initialData: const <String>[],
                      future: existingStores,
                      builder: (context, snapshot) => TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Store Name',
                          prefixIcon: Icon(Icons.text_fields),
                          filled: true,
                        ),
                        validator: (input) => input == null || input.isEmpty
                            ? 'Required'
                            : snapshot.data!.contains(input) &&
                                    input != existingStoreName
                                ? 'Store already exists'
                                : input == '(default)' ||
                                        input == '(custom)' ||
                                        input == '(unspecified)'
                                    ? 'Name reserved (in example app)'
                                    : null,
                        onSaved: (input) => newName = input,
                        maxLength: 64,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        initialValue: existingStoreName,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FutureBuilder(
                      future: existingMetadata,
                      builder: (context, snapshot) {
                        if (snapshot.data == null &&
                            existingStoreName != null) {
                          return const CircularProgressIndicator.adaptive();
                        }

                        return URLSelector(
                          onSelected: (input) => newUrlTemplate = input,
                          initialValue: snapshot
                                  .data?[StoreMetadataKeys.urlTemplate.key] ??
                              context.select<GeneralProvider, String>(
                                (provider) => provider.urlTemplate,
                              ),
                          helperText:
                              'In the example app, stores only contain tiles from one source',
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    FutureBuilder(
                      future: existingMaxLength,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done &&
                            existingStoreName != null) {
                          return const CircularProgressIndicator.adaptive();
                        }

                        return TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Maximum Length',
                            helperText: 'Leave empty to disable limit',
                            suffixText: 'tiles',
                            prefixIcon: Icon(Icons.disc_full),
                            hintText: '∞',
                            filled: true,
                          ),
                          validator: (input) {
                            if ((input?.isNotEmpty ?? false) &&
                                (int.tryParse(input!) ?? -1) < 0) {
                              return 'Must be empty, or greater than or equal to 0';
                            }
                            return null;
                          },
                          onSaved: (input) => newMaxLength =
                              input == null ? null : int.tryParse(input),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          initialValue: snapshot.data?.toString(),
                          textInputAction: TextInputAction.done,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            formKey.currentState!.save();

            if (existingStoreName case final existingStoreName?) {
              await FMTCStore(existingStoreName).manage.rename(newName!);
              await FMTCStore(newName!).manage.setMaxLength(newMaxLength);
              if (newUrlTemplate case final newUrlTemplate?) {
                await FMTCStore(newName!).metadata.set(
                      key: StoreMetadataKeys.urlTemplate.key,
                      value: newUrlTemplate,
                    );
              }
            } else {
              final urlTemplate =
                  newUrlTemplate ?? context.read<GeneralProvider>().urlTemplate;

              await FMTCStore(newName!).manage.create(maxLength: newMaxLength);
              await FMTCStore(newName!).metadata.set(
                    key: StoreMetadataKeys.urlTemplate.key,
                    value: urlTemplate,
                  );

              const sharedPrefsNonStoreUrlsKey = 'customNonStoreUrls';
              await sharedPrefs.setStringList(
                sharedPrefsNonStoreUrlsKey,
                (sharedPrefs.getStringList(sharedPrefsNonStoreUrlsKey) ??
                    <String>[])
                  ..remove(urlTemplate),
              );
            }

            if (!context.mounted) return;
            Navigator.of(context).pop();
          },
          child: existingStoreName == null
              ? const Icon(Icons.save)
              : const Icon(Icons.save_as),
        ),
      );
}
