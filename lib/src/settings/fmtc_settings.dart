// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:io';

import 'package:flutter/widgets.dart';

import '../internal/filesystem_sanitiser_private.dart';
import '../internal/tile_provider.dart';
import 'filesystem_sanitiser_public.dart';
import 'tile_provider_settings.dart';

/// Global 'flutter_map_tile_caching' settings
class FMTCSettings {
  /// Default settings used when creating an [FMTCTileProvider]
  ///
  /// Can be overridden on a case-to-case basis when actually creating the tile provider.
  final FMTCTileProviderSettings defaultTileProviderSettings;

  /// Method to sanitise any potentially unsafe [String] that will appear as a name of a [FileSystemEntity]
  ///
  /// Takes a single [String] input. Must return a valid [FilesystemSanitiserResult], as below.
  ///
  /// [FilesystemSanitiserResult.validOutput] must be sanitised to be safe enough to be used in the filesystem. [FilesystemSanitiserResult.errorMessages] can be empty if there were no changes to the input. Alternatively, it can be one or more messages describing the issue with the input.
  ///
  /// If the method is used internally in a validation situation, the output must be equal to the input, otherwise the error messages are thrown. This is, for example, the situation when managing stores and names. If the method is used internally in a sanitisation situation, error messages are ignored. This is, for example, the situation when storing map tiles.
  ///
  /// Defaults to [defaultFilesystemSanitiser] - not perfect, but OK for most uses. Recommended to override, for example, if you need to remove the API key from a tile filename, which is not done by default.
  final FilesystemSanitiserResult Function(String input) filesystemSanitiser;

  /// Create custom global 'flutter_map_tile_caching' settings
  FMTCSettings({
    FMTCTileProviderSettings? defaultTileProviderSettings,
    this.filesystemSanitiser = defaultFilesystemSanitiser,
  }) : defaultTileProviderSettings =
            defaultTileProviderSettings ?? FMTCTileProviderSettings();

  /// Use [filesystemSanitiser] publicly, in a validation situation such as in [FormField]
  ///
  /// This is useful to validate user-facing input for store names (such as in [FormField]s), and ensure that they:
  /// * comply with limitations of the filesystem
  /// * don't cause problems where sanitised input causes duplication
  ///
  /// Therefore, to prevent unexpected errors on construction, it is recommended to use this as a validator for user inputted store names: it can be put right in the `validator` property!
  ///
  /// A `null` output means the string is valid, otherwise appropriate error text is outputted (in English).
  String? filesystemFormFieldValidator(String? storeName) {
    try {
      filesystemSanitiseValidate(
        inputString: storeName ?? '',
        throwIfInvalid: true,
      );
      return null;
    } on InvalidFilesystemString catch (e) {
      return e.toStringUserFriendly();
    }
  }
}
