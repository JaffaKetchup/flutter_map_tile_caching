import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:validators/validators.dart' as validators;

import '../../shared/components/loading_indicator.dart';
import '../../shared/misc/store_metadata_keys.dart';
import '../../shared/state/general_provider.dart';
import '../../shared/components/url_selector.dart';

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

  late final Future<Iterable<String>> existingStores;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    existingStoreName = ModalRoute.of(context)!.settings.arguments as String?;
    existingMetadata = existingStoreName == null
        ? null
        : FMTCStore(existingStoreName!).metadata.read;

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
                                : input == '(default)' || input == '(custom)'
                                    ? 'Name reserved (in example app)'
                                    : null,
                        //onSaved: (input) => _newValues['storeName'] = input!,
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
                          onSelected: (_) {},
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
                  ],
                ),
              ),
            ),
          ),
        ),
        /*body: Consumer<GeneralProvider>(
        builder: (context, provider, _) => Padding(
          padding: const EdgeInsets.all(12),
          child: FutureBuilder<Map<String, String>?>(
            future:existingStoreName == null
                ? Future.sync(() => {})
                : FMTCStore(existingStoreName!).metadata.read,
            builder: (context, metadata) {
              if (!metadata.hasData || metadata.data == null) {
                return const LoadingIndicator('Retrieving Settings');
              }
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Store Name',
                          prefixIcon: Icon(Icons.text_fields),
                          isDense: true,
                        ),
                        onChanged: (input) async {
                          _storeNameIsDuplicate =
                              (await FMTCRoot.stats.storesAvailable)
                                  .contains(FMTCStore(input));
                          setState(() {});
                        },
                        validator: (input) => input == null || input.isEmpty
                            ? 'Required'
                            : _storeNameIsDuplicate
                                ? 'Store already exists'
                                : null,
                        onSaved: (input) => _newValues['storeName'] = input!,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        textCapitalization: TextCapitalization.words,
                        initialValue: widget.existingStoreName,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Map Source URL',
                          helperText:
                              "Use '{x}', '{y}', '{z}' as placeholders. Include protocol. Omit subdomain.",
                          prefixIcon: Icon(Icons.link),
                          isDense: true,
                        ),
                        onChanged: (i) async {
                          final uri = Uri.tryParse(
                            NetworkTileProvider().getTileUrl(
                              const TileCoordinates(0, 0, 0),
                              TileLayer(urlTemplate: i),
                            ),
                          );

                          if (uri == null) {
                            setState(
                              () => _httpRequestFailed = 'Invalid URL',
                            );
                            return;
                          }

                          _httpRequestFailed = await http.get(uri).then(
                                (res) => res.statusCode == 200
                                    ? null
                                    : 'HTTP Request Failed',
                                onError: (_) => 'HTTP Request Failed',
                              );
                          setState(() {});
                        },
                        validator: (i) {
                          final String input = i ?? '';

                          if (!validators.isURL(
                            input,
                            protocols: ['http', 'https'],
                            requireProtocol: true,
                          )) {
                            return 'Invalid URL';
                          }
                          if (!input.contains('{x}') ||
                              !input.contains('{y}') ||
                              !input.contains('{z}')) {
                            return 'Missing placeholder(s)';
                          }

                          return _httpRequestFailed;
                        },
                        onSaved: (input) => _newValues['sourceURL'] = input!,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        keyboardType: TextInputType.url,
                        initialValue: metadata.data!.isEmpty
                            ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
                            : metadata.data!['sourceURL'],
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Valid Cache Duration',
                          helperText: 'Use 0 to disable expiry',
                          suffixText: 'days',
                          prefixIcon: Icon(Icons.timelapse),
                          isDense: true,
                        ),
                        validator: (input) {
                          if (input == null ||
                              input.isEmpty ||
                              int.parse(input) < 0) {
                            return 'Must be 0 or more';
                          }
                          return null;
                        },
                        onSaved: (input) =>
                            _newValues['validDuration'] = input!,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        initialValue: metadata.data!.isEmpty
                            ? '14'
                            : metadata.data!['validDuration'],
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Maximum Length',
                          helperText: 'Use 0 to disable limit',
                          suffixText: 'tiles',
                          prefixIcon: Icon(Icons.disc_full),
                          isDense: true,
                        ),
                        validator: (input) {
                          if (input == null ||
                              input.isEmpty ||
                              int.parse(input) < 0) {
                            return 'Must be 0 or more';
                          }
                          return null;
                        },
                        onSaved: (input) => _newValues['maxLength'] = input!,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        initialValue: metadata.data!.isEmpty
                            ? '100000'
                            : metadata.data!['maxLength'],
                        textInputAction: TextInputAction.done,
                      ),
                      Row(
                        children: [
                          const Text('Cache Behaviour:'),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _useNewCacheModeValue
                                  ? _cacheModeValue!
                                  : metadata.data!.isEmpty
                                      ? 'cacheFirst'
                                      : metadata.data!['behaviour'],
                              onChanged: (newVal) => setState(
                                () {
                                  _cacheModeValue = newVal ?? 'cacheFirst';
                                  _useNewCacheModeValue = true;
                                },
                              ),
                              items: [
                                'cacheFirst',
                                'onlineFirst',
                                'cacheOnly',
                              ]
                                  .map<DropdownMenuItem<String>>(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),*/
      );
}
