import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/home/home.dart';
import 'state/general_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GeneralProvider>(
      create: (context) => GeneralProvider(),
      child: MaterialApp(
        title: 'FMTC Example',
        theme: ThemeData(
          primarySwatch: Colors.orange,
        ),
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}