import 'dart:async';

import 'package:flutter/material.dart';

class RootTile extends StatefulWidget {
  const RootTile({
    super.key,
    required this.length,
    required this.size,
    required this.realSizeAdditional,
  });

  final Future<String> length;
  final Future<String> size;
  final Future<String> realSizeAdditional;

  @override
  State<RootTile> createState() => _RootTileState();
}

class _RootTileState extends State<RootTile> {
  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: const Text(
              'Root',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            leading: const SizedBox.square(
              dimension: 48,
              child: Icon(Icons.storage_rounded, size: 28),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatsDisplay(
                  stat: widget.length,
                  description: 'tiles',
                ),
                const SizedBox(width: 16),
                _StatsDisplay(
                  stat: widget.size,
                  description: 'size',
                ),
                const SizedBox(width: 16),
                _StatsDisplay(
                  stat: widget.realSizeAdditional,
                  description: 'db size',
                ),
              ],
            ),
          ),
        ),
      );
}

class _StatsDisplay extends StatelessWidget {
  const _StatsDisplay({
    required this.stat,
    required this.description,
  });

  final Future<String> stat;
  final String description;

  @override
  Widget build(BuildContext context) => FittedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder(
              future: stat,
              builder: (context, snapshot) {
                if (snapshot.data == null) {
                  return const CircularProgressIndicator.adaptive();
                }
                return Text(
                  snapshot.data!,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            Text(
              description,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      );
}
