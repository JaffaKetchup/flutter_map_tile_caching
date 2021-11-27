import 'package:flutter/material.dart';

List<Step> stepBuilder({
  required List<String> titles,
  required List<String> subtitles,
  required List<Widget?> contents,
  required int currentStep,
}) {
  assert(
    titles.length == subtitles.length && subtitles.length == contents.length,
    'Length of input lists must be the same',
  );

  return List.generate(
    titles.length,
    (i) => Step(
      title: Text(titles[i]),
      subtitle: Text(subtitles[i]),
      content: contents[i] ?? Container(),
      isActive: currentStep == i,
      state: currentStep == i
          ? StepState.editing
          : currentStep < i
              ? StepState.indexed
              : StepState.complete,
    ),
  );
}
