import 'dart:io';

import 'package:better_open_file/better_open_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:version/version.dart';

import '../../../../shared/components/loading_indicator.dart';
import 'components/failed_to_check.dart';
import 'components/header.dart';
import 'components/up_to_date.dart';
import 'components/update_available.dart';

class UpdatePage extends StatefulWidget {
  const UpdatePage({Key? key}) : super(key: key);

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  static const String versionURL =
      'https://raw.githubusercontent.com/JaffaKetchup/flutter_map_tile_caching/main/example/currentAppVersion.txt';
  static const String windowsURL =
      'https://github.com/JaffaKetchup/flutter_map_tile_caching/blob/main/prebuiltExampleApplications/WindowsApplication.exe?raw=true';
  static const String androidURL =
      'https://github.com/JaffaKetchup/flutter_map_tile_caching/blob/main/prebuiltExampleApplications/AndroidApplication.apk?raw=true';

  bool updating = false;

  Future<void> updateApplication() async {
    setState(() => updating = true);

    final http.Response response = await http.get(
      Uri.parse(Platform.isWindows ? windowsURL : androidURL),
    );
    final File file = File(
      p.join(
        FMTC.instance.rootDirectory.access.real.path,
        'newAppVersion.${Platform.isWindows ? 'exe' : 'apk'}',
      ),
    );

    await file.create();
    await file.writeAsBytes(response.bodyBytes);

    if (Platform.isWindows) {
      await Process.start(file.absolute.path, []);
    } else {
      await OpenFile.open(file.absolute.path);
    }

    exit(0);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Header(title: 'Update App'),
                const SizedBox(height: 12),
                Expanded(
                  child: updating
                      ? const LoadingIndicator(
                          message:
                              'Downloading New Application Installer...\nThe app will automatically exit and run installer once downloaded',
                        )
                      : FutureBuilder<String>(
                          future: rootBundle.loadString(
                            'currentAppVersion.txt',
                            cache: false,
                          ),
                          builder: (context, currentVersion) => currentVersion
                                  .hasData
                              ? FutureBuilder<String>(
                                  future: http.read(Uri.parse(versionURL)),
                                  builder: (context, availableVersion) =>
                                      availableVersion.hasError
                                          ? const FailedToCheck()
                                          : availableVersion.hasData
                                              ? Version.parse(
                                                        availableVersion.data!
                                                            .trim(),
                                                      ) >
                                                      Version.parse(
                                                        currentVersion.data!
                                                            .trim(),
                                                      )
                                                  ? buildUpdateAvailableWidget(
                                                      context: context,
                                                      availableVersion:
                                                          availableVersion.data!
                                                              .trim(),
                                                      currentVersion:
                                                          currentVersion.data!
                                                              .trim(),
                                                      updateApplication:
                                                          updateApplication,
                                                    )
                                                  : const UpToDate()
                                              : const LoadingIndicator(
                                                  message:
                                                      'Checking For Updates...',
                                                ),
                                )
                              : const LoadingIndicator(
                                  message: 'Loading App Version Information...',
                                ),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
}
