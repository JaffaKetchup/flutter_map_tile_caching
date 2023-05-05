import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/components/loading_indicator.dart';
import 'components/header.dart';

class SettingsAndAboutPage extends StatefulWidget {
  const SettingsAndAboutPage({super.key});

  @override
  State<SettingsAndAboutPage> createState() => _SettingsAndAboutPageState();
}

class _SettingsAndAboutPageState extends State<SettingsAndAboutPage> {
  final creditsScrollController = ScrollController();
  final Map<String, String> _settings = {
    'Reset FMTC On Every Startup\nDefaults to disabled': 'reset',
    "Bypass Download Threads Limitation\nBy default, only 2 simultaneous bulk download threads can be used in the example application\nEnabling this increases the number to 10, which is only to be used in compliance with the tile server's TOS":
        'bypassDownloadThreadsLimitation',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Header(
                  title: 'Settings',
                ),
                const SizedBox(height: 12),
                FutureBuilder<SharedPreferences>(
                  future: SharedPreferences.getInstance(),
                  builder: (context, prefs) => prefs.hasData
                      ? ListView.builder(
                          itemCount: _settings.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            final List<String> info =
                                _settings.keys.toList()[index].split('\n');

                            return SwitchListTile(
                              title: Text(info[0]),
                              subtitle: info.length >= 2
                                  ? Text(
                                      info.getRange(1, info.length).join('\n'),
                                    )
                                  : null,
                              onChanged: (newBool) async {
                                await prefs.data!.setBool(
                                  _settings.values.toList()[index],
                                  newBool,
                                );
                                setState(() {});
                              },
                              value: prefs.data!.getBool(
                                    _settings.values.toList()[index],
                                  ) ??
                                  false,
                            );
                          },
                        )
                      : const LoadingIndicator(
                          message: 'Loading Settings...',
                        ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Header(
                      title: 'App Credits',
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () {
                        showLicensePage(
                          context: context,
                          applicationName: 'FMTC Demo',
                          applicationVersion:
                              'for v8.0.0\n(on ${Platform().operatingSystemFormatted})',
                          applicationIcon: Image.asset(
                            'assets/icons/ProjectIcon.png',
                            height: 48,
                          ),
                        );
                      },
                      icon: const Icon(Icons.info),
                      label: const Text('Show Licenses'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    controller: creditsScrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "An example application for the 'flutter_map_tile_caching' project, built by Luka S (JaffaKetchup). Tap on the above button to show more detailed information.\n",
                        ),
                        Text(
                          "Many thanks go to all my donors, whom can be found on the documentation website. If you want to support me, any amount is appriciated! Please visit the GitHub repository for donation/sponsorship options.\n\nYou can see all the dependenices used in this application by tapping the 'Show Licenses' button above. In addition to the packages listed there, thanks also go to:\n - Nominatim: their services are used to retrieve the location of a recoverable download on the 'Recover' screen\n - OpenStreetMap: their tiles are the default throughout the application\n - Inno Setup: their software provides the installer for the Windows version of this application",
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

extension on Platform {
  String get operatingSystemFormatted {
    switch (Platform.operatingSystem) {
      case 'android':
        return 'Android';
      case 'ios':
        return 'iOS';
      case 'linux':
        return 'Linux';
      case 'macos':
        return 'MacOS';
      case 'windows':
        return 'Windows';
      default:
        return 'Unknown Operating System';
    }
  }
}
