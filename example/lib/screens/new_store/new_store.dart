import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:http/http.dart' as http;
import 'package:validators/validators.dart' as validators;

class NewStorePopup extends StatefulWidget {
  const NewStorePopup({Key? key}) : super(key: key);

  @override
  State<NewStorePopup> createState() => _NewStorePopupState();
}

class _NewStorePopupState extends State<NewStorePopup> {
  String? _httpRequestFailed;
  String? _cacheModeValue;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Create New Store'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Store Name',
                    prefixIcon: Icon(Icons.text_fields),
                    isDense: true,
                  ),
                  validator: FMTCSafeFilesystemString.validator,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
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
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  initialValue:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Text('Cache Behaviour:'),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _cacheModeValue,
                        onChanged: (newVal) =>
                            setState(() => _cacheModeValue = newVal),
                        items:
                            <String>['cacheFirst', 'onlineFirst', 'cacheOnly']
                                .map<DropdownMenuItem<String>>(
                                  (String value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
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
      );
}
