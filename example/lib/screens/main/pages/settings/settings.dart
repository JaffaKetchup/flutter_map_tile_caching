import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/components/loading_indicator.dart';
import 'components/header.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final Map<String, String> _settings = {
    'Reset FMTC On Every Startup': 'reset',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Header(),
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder<SharedPreferences>(
                    future: SharedPreferences.getInstance(),
                    builder: (context, prefs) => prefs.hasData
                        ? ListView.builder(
                            itemCount: _settings.length,
                            itemBuilder: (context, index) => SwitchListTile(
                              title: Text(_settings.keys.toList()[index]),
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
                                  true,
                            ),
                          )
                        : const LoadingIndicator(
                            message: 'Loading Settings...',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
