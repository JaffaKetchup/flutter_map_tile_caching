import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../misc/shared_preferences.dart';
import '../misc/store_metadata_keys.dart';

class UrlSelector extends StatefulWidget {
  const UrlSelector({
    super.key,
    required this.initialValue,
    this.onSelected,
    this.helperText,
    this.onFocus,
    this.onUnfocus,
  });

  final String initialValue;
  final void Function(String)? onSelected;
  final String? helperText;
  final void Function()? onFocus;
  final void Function()? onUnfocus;

  @override
  State<UrlSelector> createState() => _UrlSelectorState();
}

class _UrlSelectorState extends State<UrlSelector> {
  static const _defaultUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  late final _urlTextController = TextEditingControllerWithMatcherStylizer(
    TileProvider.templatePlaceholderElement,
    const TextStyle(fontStyle: FontStyle.italic),
    initialValue: widget.initialValue,
  );

  final _selectableEntriesManualRefreshStream = StreamController<void>();

  late final _templatesToStoresStream =
      (StreamGroup<Map<String, List<String>>>()
            ..add(
              _transformToTemplatesToStoresOnTrigger(
                FMTCRoot.stats.watchStores(triggerImmediately: true),
              ),
            )
            ..add(
              _transformToTemplatesToStoresOnTrigger(
                _selectableEntriesManualRefreshStream.stream,
              ),
            ))
          .stream;

  Map<String, List<String>> _enableButtonEvaluatorMap = {};
  final _enableAddUrlButton = ValueNotifier<bool>(false);

  late final _dropdownMenuFocusNode =
      widget.onFocus != null || widget.onUnfocus != null ? FocusNode() : null;

  @override
  void initState() {
    super.initState();
    _urlTextController.addListener(_urlTextControllerListener);
    _dropdownMenuFocusNode?.addListener(_dropdownMenuFocusListener);
  }

  @override
  void dispose() {
    _urlTextController.removeListener(_urlTextControllerListener);
    _dropdownMenuFocusNode?.removeListener(_dropdownMenuFocusListener);
    _selectableEntriesManualRefreshStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<Map<String, List<String>>>(
        initialData: const {
          _defaultUrlTemplate: ['(default)'],
        },
        stream: _templatesToStoresStream,
        builder: (context, snapshot) {
          // Bug in `DropdownMenu` means we must force the controller to
          // update to update the state of the entries
          final oldValue = _urlTextController.value;
          _urlTextController
            ..value = TextEditingValue.empty
            ..value = oldValue;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownMenu<String?>(
                  controller: _urlTextController,
                  expandedInsets: EdgeInsets.zero, // full width
                  requestFocusOnTap: true,
                  leadingIcon: const Icon(Icons.link),
                  label: const Text('URL Template'),
                  inputDecorationTheme: const InputDecorationTheme(
                    filled: true,
                    helperMaxLines: 2,
                  ),
                  initialSelection: widget.initialValue,
                  // Bug in `DropdownMenu` means this cannot be `true`
                  // enableFilter: true,
                  dropdownMenuEntries: _constructMenuEntries(snapshot),
                  onSelected: _onSelected,
                  helperText: 'Use standard placeholders & include protocol'
                      '${widget.helperText != null ? '\n${widget.helperText}' : ''}',
                  focusNode: _dropdownMenuFocusNode,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 8),
                child: ValueListenableBuilder(
                  valueListenable: _enableAddUrlButton,
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
      );

  void _onSelected(String? v) {
    if (v == null) {
      sharedPrefs.setStringList(
        SharedPrefsKeys.customNonStoreUrls.name,
        (sharedPrefs.getStringList(SharedPrefsKeys.customNonStoreUrls.name) ??
            <String>[])
          ..add(_urlTextController.text),
      );

      _selectableEntriesManualRefreshStream.add(null);
    }

    widget.onSelected!(v ?? _urlTextController.text);
    _dropdownMenuFocusNode?.unfocus();
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
                          SharedPrefsKeys.customNonStoreUrls.name,
                          (sharedPrefs.getStringList(
                                SharedPrefsKeys.customNonStoreUrls.name,
                              ) ??
                              <String>[])
                            ..remove(e.key),
                        );

                        _selectableEntriesManualRefreshStream.add(null);
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

  Stream<Map<String, List<String>>> _transformToTemplatesToStoresOnTrigger(
    Stream<void> triggerStream,
  ) =>
      triggerStream.asyncMap(
        (e) async {
          final storesAndTemplates = await Future.wait(
            (await FMTCRoot.stats.storesAvailable).map(
              (s) async => (
                storeName: s.storeName,
                urlTemplate: await s.metadata.read.then(
                  (metadata) => metadata[StoreMetadataKeys.urlTemplate.key],
                )
              ),
            ),
          )
            ..add((storeName: '(default)', urlTemplate: _defaultUrlTemplate))
            ..addAll(
              (sharedPrefs.getStringList(
                        SharedPrefsKeys.customNonStoreUrls.name,
                      ) ??
                      <String>[])
                  .map((url) => (storeName: '(custom)', urlTemplate: url)),
            );

          final templateToStores = <String, List<String>>{};

          for (final st in storesAndTemplates) {
            if (st.urlTemplate == null) continue;
            (templateToStores[st.urlTemplate!] ??= []).add(st.storeName);
          }

          return _enableButtonEvaluatorMap = templateToStores;
        },
      ).distinct(mapEquals);

  void _dropdownMenuFocusListener() {
    if (widget.onFocus != null && _dropdownMenuFocusNode!.hasFocus) {
      widget.onFocus!();
    }
    if (widget.onUnfocus != null && !_dropdownMenuFocusNode!.hasFocus) {
      widget.onUnfocus!();
    }
  }

  void _urlTextControllerListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enableAddUrlButton.value =
          !_enableButtonEvaluatorMap.containsKey(_urlTextController.text);
    });
  }
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
