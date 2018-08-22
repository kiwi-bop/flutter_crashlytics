import 'package:flutter/material.dart';
import 'package:flutter_crashlytics/flutter_crashlytics.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) async {
    await FlutterCrashlytics().onError(details, forceCrash: false);
  };
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Center(
              child: RaisedButton(
                onPressed: () {
                  final crash = List()[20];
                  debugPrint(crash);
                },
                child: Text('Crash'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
