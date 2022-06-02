import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:http/http.dart' as http;
import 'package:validators/validators.dart' as validators;

import 'components/header.dart';

class StoreEditorPopup extends StatefulWidget {
  const StoreEditorPopup({
    Key? key,
    required this.existingStoreName,
    required this.isStoreInUse,
  }) : super(key: key);

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
  String _cacheModeValue = 'cacheFirst';

  @override
  Widget build(BuildContext context) => WillPopScope(
        onWillPop: () async {
          ScaffoldMessenger.of(context).showSnackBar(
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
            cacheModeValue: _cacheModeValue,
            context: context,
          ),
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: Form(
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
                        _storeNameIsDuplicate = (await FMTC.instance
                                .rootDirectory.stats.storesAvailableAsync)
                            .contains(FMTC.instance(input));
                        setState(() {});
                      },
                      validator: (input) {
                        if (input == null || input.isEmpty) return 'Required';

                        final String? nameValidation =
                            FMTCSafeFilesystemString.validator(input);
                        if (nameValidation != null) return nameValidation;

                        return _storeNameIsDuplicate
                            ? 'Store already exists'
                            : null;
                      },
                      onSaved: (input) => _newValues['storeName'] = input!,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
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
                                  Coords(1, 1)..z = 1,
                                  TileLayerOptions(urlTemplate: i),
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

                        if (!validators.isURL(input, requireProtocol: true)) {
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
                      initialValue:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                      onSaved: (input) => _newValues['validDuration'] = input!,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      initialValue: '14',
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Text('Cache Behaviour:'),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _cacheModeValue,
                            onChanged: (newVal) => setState(
                              () => _cacheModeValue = newVal ?? 'cacheFirst',
                            ),
                            items: ['cacheFirst', 'onlineFirst', 'cacheOnly']
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
            ),
          ),
        ),
      );
}
