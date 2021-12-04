import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../state/general_provider.dart';
import 'components/map.dart';
import 'components/exit.dart';

class StoreEditor extends StatefulWidget {
  const StoreEditor({Key? key}) : super(key: key);

  @override
  _StoreEditorState createState() => _StoreEditorState();
}

class _StoreEditorState extends State<StoreEditor> {
  // A map of all editable options for a store, with prefilled defaults assuming a default new store
  final Map<String, List<dynamic>> options = {
    'storeName': [
      null,
      null,
    ],
    'sourceURL': [
      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
    ],
    'cacheBehaviour': [
      'cacheFirst',
      'cacheFirst',
    ],
    'validDuration': [
      16,
      16,
    ],
    'maxTiles': [
      20000,
      20000,
    ],
  };

  T optNewFallback<T>(String opt) =>
      (options[opt]![1] ?? options[opt]![0]) as T;
  void updateOpt<T>(String opt, dynamic newVal) => setState(
      () => options[opt]![1] = T == String && newVal.isEmpty ? null : newVal);

  late final MapCachingManager? mcm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    mcm = ModalRoute.of(context)!.settings.arguments as MapCachingManager?;

    final GeneralProvider provider =
        Provider.of<GeneralProvider>(context, listen: false);

    if (mcm != null) {
      options['storeName'] = [
        mcm?.storeName ?? 'Default Store',
        mcm?.storeName ?? 'Default Store'
      ];

      final String? _sourceURL =
          provider.persistent!.getString('${mcm!.storeName}: sourceURL');
      if (_sourceURL != null) {
        options['sourceURL'] = [_sourceURL, _sourceURL];
      }

      final String? _cacheBehaviour =
          provider.persistent!.getString('${mcm!.storeName}: cacheBehaviour');
      if (_cacheBehaviour != null) {
        options['cacheBehaviour'] = [_cacheBehaviour, _cacheBehaviour];
      }

      final int? _validDuration =
          provider.persistent!.getInt('${mcm!.storeName}: validDuration');
      if (_validDuration != null) {
        options['validDuration'] = [_validDuration, _validDuration];
      }

      final int? _maxTiles =
          provider.persistent!.getInt('${mcm!.storeName}: maxTiles');
      if (_maxTiles != null) options['maxTiles'] = [_maxTiles, _maxTiles];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GeneralProvider>(
      builder: (context, provider, _) {
        return WillPopScope(
          onWillPop: () => exit(context, options),
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                mcm == null && options['storeName']![1] == null
                    ? 'Create New Store'
                    : 'Edit \'${optNewFallback<String>('storeName')}\'',
              ),
            ),
            body: Consumer<GeneralProvider>(
              builder: (context, provider, _) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 300,
                        child: MapView(
                          source: optNewFallback<String>('sourceURL'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: options['storeName']![0],
                        onChanged: (newVal) =>
                            updateOpt<String>('storeName', newVal),
                        decoration:
                            const InputDecoration(labelText: 'Store Name'),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        initialValue: options['sourceURL']![0],
                        onChanged: (newVal) =>
                            updateOpt<String>('sourceURL', newVal),
                        decoration: const InputDecoration(
                          labelText: 'Source URL',
                          helperText:
                              'You must abide by your tile server\'s Terms Of Service',
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 5),
                      const Divider(),
                      const SizedBox(height: 5),
                      TextFormField(
                        initialValue: options['validDuration']![0].toString(),
                        onChanged: (newVal) => updateOpt<int>(
                            'validDuration', int.tryParse(newVal) ?? 16),
                        decoration: const InputDecoration(
                          labelText: 'Valid Duration (days)',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                        ],
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        initialValue: options['maxTiles']![0].toString(),
                        onChanged: (newVal) => updateOpt<int>(
                            'maxTiles', int.tryParse(newVal) ?? 16),
                        decoration: const InputDecoration(
                          labelText: 'Max Tiles',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Text('Cache Behaviour:'),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButton<String>(
                              value: optNewFallback<String>('cacheBehaviour'),
                              onChanged: (newVal) =>
                                  updateOpt<String>('cacheBehaviour', newVal),
                              items: <String>[
                                'cacheFirst',
                                'onlineFirst',
                                'cacheOnly'
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
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
      },
    );
  }
}
