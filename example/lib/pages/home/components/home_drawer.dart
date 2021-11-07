import 'package:flutter/material.dart';
import 'package:fmtc_example/state/general_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<GeneralProvider>(
        builder: (context, provider, _) => ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.green,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'flutter_map_tile_caching Example',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          await launch('https://ko-fi.com/JaffaKetchup');
                        },
                        icon: const Icon(Icons.monetization_on),
                        label: const Text('Donate'),
                        style: ButtonStyle(
                          side: MaterialStateProperty.all(
                            const BorderSide(color: Colors.white),
                          ),
                          foregroundColor:
                              MaterialStateProperty.all(Colors.white),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await launch(
                              'https://github.com/JaffaKetchup/flutter_map_tile_caching');
                        },
                        icon: const Icon(Icons.code),
                        label: const Text('GitHub'),
                        style: ButtonStyle(
                          side: MaterialStateProperty.all(
                            const BorderSide(color: Colors.white),
                          ),
                          foregroundColor:
                              MaterialStateProperty.all(Colors.white),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                top: 16.0,
                bottom: 8.0,
              ),
              child: Text(
                'Caching Management',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.sd_storage),
              trailing: Switch.adaptive(
                value: provider.cachingEnabled,
                onChanged: (bool newVal) {
                  if (newVal) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Caching to: ${provider.currentMapCachingManager.storeName}',
                        ),
                        action: SnackBarAction(
                          label: 'Stop Caching',
                          onPressed: () {
                            provider.cachingEnabled = false;
                          },
                        ),
                      ),
                    );
                  }
                  provider.cachingEnabled = newVal;
                },
              ),
              title: const Text('Browse Caching'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Caching to: ${provider.currentMapCachingManager.storeName}',
                    ),
                    action: SnackBarAction(
                      label: 'Stop Caching',
                      onPressed: () {
                        provider.cachingEnabled = false;
                      },
                    ),
                  ),
                );
                provider.cachingEnabled = !provider.cachingEnabled;
              },
            ),
            StreamBuilder<void>(
              stream: provider.currentMapCachingManager.watchChanges,
              builder: (context, _) {
                return ListTile(
                  leading: const Icon(Icons.offline_pin),
                  trailing: Switch.adaptive(
                    value: provider.offlineMode,
                    onChanged:
                        provider.currentMapCachingManager.storeLength == 0
                            ? null
                            : (bool newVal) {
                                provider.offlineMode = newVal;
                              },
                  ),
                  title: const Text('Offline Mode'),
                  onTap: provider.currentMapCachingManager.storeLength == 0
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('No tiles present in the current store'),
                            ),
                          );
                        }
                      : () {
                          provider.offlineMode = !provider.offlineMode;
                        },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.rule_folder),
              title: const Text('Manage Stores'),
              onTap: () {},
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                top: 16.0,
                bottom: 8.0,
              ),
              child: Text(
                'Bulk Downloading',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.sd_storage),
              trailing: Switch.adaptive(
                value: provider.cachingEnabled,
                onChanged: (bool newVal) {
                  provider.cachingEnabled = newVal;
                },
              ),
              title: const Text('Configure Rules'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.rule),
              title: const Text('Manage Stores & Rules'),
              onTap: () {},
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
