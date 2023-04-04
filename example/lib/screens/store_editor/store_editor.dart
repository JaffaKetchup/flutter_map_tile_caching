import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:validators/validators.dart' as validators;

import '../../shared/components/loading_indicator.dart';
import '../../shared/state/download_provider.dart';
import '../../shared/state/general_provider.dart';
import 'components/header.dart';

class StoreEditorPopup extends StatefulWidget {
  const StoreEditorPopup({
    super.key,
    required this.existingStoreName,
    required this.isStoreInUse,
  });

  final String? existingStoreName;
  final bool isStoreInUse;

  @override
  State<StoreEditorPopup> createState() => _StoreEditorPopupState();
}

class _StoreEditorPopupState extends State<StoreEditorPopup> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _newValues = {};

  String? _httpRequestFailed;
  bool _storeNameIsDuplicate = false;

  bool _useNewCacheModeValue = false;
  String? _cacheModeValue;

  late final ScaffoldMessengerState scaffoldMessenger;

  @override
  void didChangeDependencies() {
    scaffoldMessenger = ScaffoldMessenger.of(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) => Consumer<DownloadProvider>(
        builder: (context, downloadProvider, _) => WillPopScope(
          onWillPop: () async {
            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text('Changes not saved')),
            );
            return true;
          },
          child: Scaffold(
            appBar: buildHeader(
              widget: widget,
              mounted: mounted,
              formKey: _formKey,
              newValues: _newValues,
              useNewCacheModeValue: _useNewCacheModeValue,
              cacheModeValue: _cacheModeValue,
              context: context,
            ),
            body: Consumer<GeneralProvider>(
              builder: (context, provider, _) => Padding(
                padding: const EdgeInsets.all(12),
                child: FutureBuilder<Map<String, String>?>(
                  future: widget.existingStoreName == null
                      ? Future.sync(() => {})
                      : FMTC
                          .instance(widget.existingStoreName!)
                          .metadata
                          .readAsync,
                  builder: (context, metadata) {
                    if (!metadata.hasData || metadata.data == null) {
                      return const LoadingIndicator(
                        message:
                            'Loading Settings...\n\nSeeing this screen for a long time?\nThere may be a misconfiguration of the\nstore. Try disabling caching and deleting\n faulty stores.',
                      );
                    }
                    return Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Store Name',
                                helperText: 'Must be valid directory name',
                                prefixIcon: Icon(Icons.text_fields),
                                isDense: true,
                              ),
                              onChanged: (input) async {
                                _storeNameIsDuplicate = (await FMTC
                                        .instance
                                        .rootDirectory
                                        .stats
                                        .storesAvailableAsync)
                                    .contains(FMTC.instance(input));
                                setState(() {});
                              },
                              validator: (input) =>
                                  input == null || input.isEmpty
                                      ? 'Required'
                                      : _storeNameIsDuplicate
                                          ? 'Store already exists'
                                          : null,
                              onSaved: (input) =>
                                  _newValues['storeName'] = input!,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              textCapitalization: TextCapitalization.words,
                              initialValue: widget.existingStoreName,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 5),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Map Source URL (protocol required)',
                                helperText:
                                    "Use '{x}', '{y}', '{z}' as placeholders. Omit subdomain.",
                                prefixIcon: Icon(Icons.link),
                                isDense: true,
                              ),
                              onChanged: (i) async {
                                _httpRequestFailed = await http
                                    .get(
                                      Uri.parse(
                                        NetworkTileProvider().getTileUrl(
                                          const TileCoordinates(1, 1, 1),
                                          TileLayer(urlTemplate: i),
                                        ),
                                      ),
                                    )
                                    .then(
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
                              onSaved: (input) =>
                                  _newValues['sourceURL'] = input!,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
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
                                helperText: 'Use 0 days for infinite duration',
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
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
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
                                helperText:
                                    'Use 0 days for infinite number of tiles',
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
                              onSaved: (input) =>
                                  _newValues['maxLength'] = input!,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              initialValue: metadata.data!.isEmpty
                                  ? '20000'
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
                                        _cacheModeValue =
                                            newVal ?? 'cacheFirst';
                                        _useNewCacheModeValue = true;
                                      },
                                    ),
                                    items: [
                                      'cacheFirst',
                                      'onlineFirst',
                                      'cacheOnly'
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
            ),
          ),
        ),
      );
}
