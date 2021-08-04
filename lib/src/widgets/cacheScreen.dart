import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

@experimental
class CacheScreen extends StatefulWidget {
  const CacheScreen({Key? key}) : super(key: key);

  @override
  _CacheScreenState createState() => _CacheScreenState();
}

class _CacheScreenState extends State<CacheScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hi'),
      ),
    );
  }
}
