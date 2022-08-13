import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class BackgroundDownloadBatteryOptimizationsInfo extends StatefulWidget {
  const BackgroundDownloadBatteryOptimizationsInfo({
    Key? key,
  }) : super(key: key);

  @override
  State<BackgroundDownloadBatteryOptimizationsInfo> createState() =>
      _BackgroundDownloadBatteryOptimizationsInfoState();
}

class _BackgroundDownloadBatteryOptimizationsInfoState
    extends State<BackgroundDownloadBatteryOptimizationsInfo> {
  @override
  Widget build(BuildContext context) => FutureBuilder<bool?>(
        future: FMTC
            .instance('')
            .download
            .requestIgnoreBatteryOptimizations(requestIfDenied: false),
        builder: (context, snapshot) => Row(
          children: [
            Icon(
              snapshot.data == null || !snapshot.data!
                  ? Icons.warning_amber
                  : Icons.done,
              color: snapshot.data == null || !snapshot.data!
                  ? Colors.amber
                  : Colors.green,
              size: 36,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Apps that support background downloading can request extra permissions to help prevent the background process being stopped by the system. Specifically, the 'ignore battery optimisations' permission helps most. The API has a method to manage this permission.",
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    snapshot.hasError
                        ? 'This platform currently does not support this API: it is only supported on Android.'
                        : snapshot.data == null
                            ? 'Checking if this permission is currently granted to this application...'
                            : (!snapshot.data!
                                ? 'This application does not have this permission granted to it currently. Tap the button below to use the API method to request the permission.'
                                : 'This application does currently have this permission granted to it.'),
                    textAlign: TextAlign.justify,
                  ),
                  if (!(snapshot.data ?? true))
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          await FMTC
                              .instance('')
                              .download
                              .requestIgnoreBatteryOptimizations();
                          setState(() {});
                        },
                        child: const Text('Request Permission'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}
