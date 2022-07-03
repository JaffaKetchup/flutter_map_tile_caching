import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class BackgroundDownloadInfo extends StatefulWidget {
  const BackgroundDownloadInfo({
    Key? key,
  }) : super(key: key);

  @override
  State<BackgroundDownloadInfo> createState() => _BackgroundDownloadInfoState();
}

class _BackgroundDownloadInfoState extends State<BackgroundDownloadInfo> {
  @override
  Widget build(BuildContext context) => FutureBuilder<bool?>(
        future: FMTC.instance('').download.requestIgnoreBatteryOptimizations(
              context,
              requestIfDenied: false,
            ),
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
                children: [
                  const Text(
                    "Apps that support background downloading can request extra permissions to help prevent the background process being stopped by the system. Specifically, the 'ignore battery optimisations' permission helps most. The API has a method to manage this permission.",
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    snapshot.data == null
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
                              .requestIgnoreBatteryOptimizations(context);
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
