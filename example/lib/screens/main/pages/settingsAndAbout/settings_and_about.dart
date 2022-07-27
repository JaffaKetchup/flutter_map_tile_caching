import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/components/loading_indicator.dart';
import 'components/header.dart';

class SettingsAndAboutPage extends StatefulWidget {
  const SettingsAndAboutPage({Key? key}) : super(key: key);

  @override
  State<SettingsAndAboutPage> createState() => _SettingsAndAboutPageState();
}

class _SettingsAndAboutPageState extends State<SettingsAndAboutPage> {
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
                const Header(
                  title: 'App Information & Credits',
                ),
                const SizedBox(height: 12),
                const Text(
                  "An example application for the 'flutter_map_tile_caching' project, built by Luka S (JaffaKetchup).\n",
                ),
                const Text(
                  'Many thanks go to all my donors, including:\n - @ibrierley\n - @tonyshkurenko\nIf you want to support me, any amount is appriciated! Please visit the GitHub repository for donation/sponsorship options.',
                ),
              ],
            ),
          ),
        ),
      );
}
