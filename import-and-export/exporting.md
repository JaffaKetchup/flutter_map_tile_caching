---
description: fmtc_plus_sharing Module
---

# Exporting

Exporting a store copies the internal store database, 'compresses' it slightly, then renames it appropriately. The files are in the binary format that [Isar](https://isar.dev/) uses, so they cannot easily be read or modified.

They can have any file extension applied to them - '.fmtc' is used in the example application. The name of the file dictates the name of the store that will be used when importing (without the 'export\_' prefix, if still present).

## With Platform GUI (`withGUI`)

{% embed url="https://pub.dev/documentation/fmtc_plus_sharing/latest/fmtc_plus_sharing/FMTCExportSharingModule/withGUI.html" %}

## With A Known `File` (`manual`)

{% embed url="https://pub.dev/documentation/fmtc_plus_sharing/latest/fmtc_plus_sharing/FMTCExportSharingModule/manual.html" %}
