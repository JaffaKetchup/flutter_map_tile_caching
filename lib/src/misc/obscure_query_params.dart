// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:meta/meta.dart';

/// Removes all matches of [obscuredQueryParams] from [url] after the query
/// delimiter '?'
@internal
String obscureQueryParams({
  required String url,
  required Iterable<RegExp> obscuredQueryParams,
}) {
  if (!url.contains('?') || obscuredQueryParams.isEmpty) return url;

  String secondPartUrl = url.split('?')[1];
  for (final matcher in obscuredQueryParams) {
    secondPartUrl = secondPartUrl.replaceAll(matcher, '');
  }

  return '${url.split('?')[0]}?$secondPartUrl';
}
