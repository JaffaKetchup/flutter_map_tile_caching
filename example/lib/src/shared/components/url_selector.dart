import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../misc/shared_preferences.dart';
import '../misc/store_metadata_keys.dart';

class URLSelector extends StatefulWidget {
  const URLSelector({
    super.key,
    this.initialValue,
    this.onSelected,
    this.helperText,
  });

  final String? initialValue;
  final void Function(String)? onSelected;
  final String? helperText;

  @override
  State<URLSelector> createState() => _URLSelectorState();
}

class _URLSelectorState extends State<URLSelector> {
  static const _sharedPrefsNonStoreUrlsKey = 'customNonStoreUrls';
  static const _defaultUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  late final urlTextController = TextEditingControllerWithMatcherStylizer(
    TileProvider.templatePlaceholderElement,
    const TextStyle(fontStyle: FontStyle.italic),
    initialValue: widget.initialValue ?? _defaultUrlTemplate,
  );

  final selectableEntriesManualRefreshStream = StreamController<void>();

  late final inUseUrlsStream = (StreamGroup<void>()
        ..add(FMTCRoot.stats.watchStores(triggerImmediately: true))
        ..add(selectableEntriesManualRefreshStream.stream))
      .stream
      .asyncMap(_constructTemplatesToStoresStream);

  Map<String, List<String>> enableButtonEvaluatorMap = {};
  final enableAddUrlButton = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    urlTextController.addListener(_urlTextControllerListener);
  }

  @override
  void dispose() {
    urlTextController.removeListener(_urlTextControllerListener);
    selectableEntriesManualRefreshStream.close();
    super.dispose();
  }

  void _urlTextControllerListener() {
    enableAddUrlButton.value =
        !enableButtonEvaluatorMap.containsKey(urlTextController.text);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          width: constraints.maxWidth,
          child: StreamBuilder<Map<String, List<String>>>(
            initialData: const {
              _defaultUrlTemplate: ['(default)'],
            },
            stream: inUseUrlsStream,
            builder: (context, snapshot) {
              // Bug in `DropdownMenu` means we must force the controller to
              // update to update the state of the entries
              final oldValue = urlTextController.value;
              urlTextController
                ..value = TextEditingValue.empty
                ..value = oldValue;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownMenu<String?>(
                      controller: urlTextController,
                      width: constraints.maxWidth,
                      requestFocusOnTap: true,
                      leadingIcon: const Icon(Icons.link),
                      label: const Text('URL Template'),
                      inputDecorationTheme: const InputDecorationTheme(
                        filled: true,
                        helperMaxLines: 2,
                      ),
                      initialSelection:
                          widget.initialValue ?? _defaultUrlTemplate,
                      // Bug in `DropdownMenu` means this cannot be `true`
                      // enableFilter: true,
                      dropdownMenuEntries: _constructMenuEntries(snapshot),
                      onSelected: _onSelected,
                      helperText: 'Use standard placeholders & include protocol'
                          '${widget.helperText != null ? '\n${widget.helperText}' : ''}',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 8),
                    child: ValueListenableBuilder(
                      valueListenable: enableAddUrlButton,
                      builder: (context, enableAddUrlButton, _) =>
                          IconButton.filledTonal(
                        onPressed:
                            enableAddUrlButton ? () => _onSelected(null) : null,
                        icon: const Icon(Icons.add_link),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );

  void _onSelected(String? v) {
    if (v == null) {
      sharedPrefs.setStringList(
        _sharedPrefsNonStoreUrlsKey,
        (sharedPrefs.getStringList(_sharedPrefsNonStoreUrlsKey) ?? <String>[])
          ..add(urlTextController.text),
      );

      selectableEntriesManualRefreshStream.add(null);
    }

    widget.onSelected!(v ?? urlTextController.text);
  }

  Future<Map<String, List<String>>> _constructTemplatesToStoresStream(
    _,
  ) async {
    final storesAndTemplates = await Future.wait(
      (await FMTCRoot.stats.storesAvailable).map(
        (store) async => (
          storeName: store.storeName,
          urlTemplate: await store.metadata.read
              .then((metadata) => metadata[StoreMetadataKeys.urlTemplate.key])
        ),
      ),
    )
      ..add((storeName: '(default)', urlTemplate: _defaultUrlTemplate))
      ..addAll(
        (sharedPrefs.getStringList(_sharedPrefsNonStoreUrlsKey) ?? <String>[])
            .map((url) => (storeName: '(custom)', urlTemplate: url)),
      );

    final templateToStores = <String, List<String>>{};

    for (final st in storesAndTemplates) {
      if (st.urlTemplate == null) continue;
      (templateToStores[st.urlTemplate!] ??= []).add(st.storeName);
    }

    enableButtonEvaluatorMap = templateToStores;

    return templateToStores;
  }

  List<DropdownMenuEntry<String?>> _constructMenuEntries(
    AsyncSnapshot<Map<String, List<String>>> snapshot,
  ) =>
      snapshot.data!.entries
          .map<DropdownMenuEntry<String?>>(
            (e) => DropdownMenuEntry(
              value: e.key,
              label: e.key,
              labelWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Uri.tryParse(e.key)?.host ?? e.key),
                  Text(
                    'Used by: ${e.value.join(', ')}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              trailingIcon: e.value.contains('(custom)')
                  ? IconButton(
                      onPressed: () {
                        sharedPrefs.setStringList(
                          _sharedPrefsNonStoreUrlsKey,
                          (sharedPrefs
                                  .getStringList(_sharedPrefsNonStoreUrlsKey) ??
                              <String>[])
                            ..remove(e.key),
                        );

                        selectableEntriesManualRefreshStream.add(null);
                      },
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Remove URL from non-store list',
                    )
                  : null,
            ),
          )
          .toList()
        ..add(
          const DropdownMenuEntry(
            value: null,
            label:
                'To use another URL (without using it in a store),\nenter it, '
                'then hit enter/done/add',
            leadingIcon: Icon(Icons.add_link),
            enabled: false,
          ),
        );
}

// Inspired by https://stackoverflow.com/a/59773962/11846040
class TextEditingControllerWithMatcherStylizer extends TextEditingController {
  TextEditingControllerWithMatcherStylizer(
    this.pattern,
    this.matchedStyle, {
    String? initialValue,
  }) : super(text: initialValue);

  final Pattern pattern;
  final TextStyle matchedStyle;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<InlineSpan> children = [];

    text.splitMapJoin(
      pattern,
      onMatch: (match) {
        children.add(TextSpan(text: match[0], style: matchedStyle));
        return '';
      },
      onNonMatch: (text) {
        children.add(TextSpan(text: text, style: style));
        return '';
      },
    );

    return TextSpan(style: style, children: children);
  }
}
