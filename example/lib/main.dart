import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_crashlytics/flutter_crashlytics.dart';

void main() async {
  bool isInDebugMode = false;
  profile(() {
    // isInDebugMode=true;
  });

  FlutterError.onError = (FlutterErrorDetails details) {
    if (isInDebugMode) {
      // In development mode simply print to console.
      FlutterError.dumpErrorToConsole(details);
      Zone.current.handleUncaughtError(details.exception, details.stack);
    } else {
      // In production mode report to the application zone to report to
      // Crashlytics.
      Zone.current.handleUncaughtError(details.exception, details.stack);
    }
  };

  bool optIn = true;
  if (optIn) {
    await FlutterCrashlytics().initialize();
  } else {
    // In this case Crashlytics won't send any reports.
    // Usually handling opt in/out is required by the Privacy Regulations
  }

  runZoned<Future<Null>>(() async {
    runApp(MyApp());
  }, onError: (error, stackTrace) async {
    // Whenever an error occurs, call the `reportCrash` function. This will send
    // Dart errors to our dev console or Crashlytics depending on the environment.
    debugPrint(error.toString());
    await FlutterCrashlytics().reportCrash(error, stackTrace, forceCrash: true);
  });
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
                  final crash = List()[125];
                  debugPrint(crash);
                },
                child: Text('Crash'),
              ),
            ),
            Center(
              child: RaisedButton(
                onPressed: () {
                  try {
                    final crash = List()[1555];
                    debugPrint(crash);
                  } catch (error) {
                    debugPrint(error.toString());
                    FlutterCrashlytics().logException(error, error.stackTrace);
                  }
                },
                child: Text('Manual error log'),
              ),
            ),
            Center(
              child: RaisedButton(
                onPressed: () {
                  try {
                    throw new FormatException();
                  } catch (exception, stack) {
                    debugPrint(exception.toString());
                    FlutterCrashlytics().logException(exception, stack);
                  }
                },
                child: Text('Manual exception log'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
