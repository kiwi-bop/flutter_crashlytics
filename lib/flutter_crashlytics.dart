import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlutterCrashlytics {
  static const MethodChannel _channel = const MethodChannel('flutter_crashlytics');
  static final FlutterCrashlytics _singleton = FlutterCrashlytics._internal();

  factory FlutterCrashlytics() => _singleton;

  FlutterCrashlytics._internal();

  final regexp = RegExp(
    '([a-zA-Z ]+)(?:\\.(.*))?\\([a-zA-Z:/_]+\\/([0-9a-zA-Z_-]+.dart):([0-9]+):',
    caseSensitive: false,
    multiLine: false,
  );
  final regexpName = RegExp(
    '([a-zA-Z]+) ',
    caseSensitive: false,
    multiLine: false,
  );

  Future<void> onError(FlutterErrorDetails details) async {
    final trace = details.toString().split('\n');
    final name = regexpName.firstMatch(trace[1]).group(0).trim();
    final results = [];

    for (var i = 2; i < trace.length; ++i) {
      var line = trace[i];
      final matches = regexp.allMatches(line).toList();
      if (matches.length == 1) {
        final traceClass = matches[0].group(1)?.trim();
        final traceMethod = matches[0].group(2)?.trim();
        final traceFile = matches[0].group(3)?.trim();
        final traceLine = int.tryParse(matches[0].group(4)) ?? 0;
        results.add([traceClass, traceMethod, traceFile, traceLine]);
      }
    }
    final data = {'name': name, 'cause': trace[1], 'message': trace[0], 'trace': results};
    return await _channel.invokeMethod('reportCrash', data);
  }

  Future<void> log(String msg, {int priority, String tag}) async {
    if (priority == null && tag == null) {
      await _channel.invokeMethod('log', msg);
    } else {
      await _channel.invokeMethod('log', [priority, tag, msg]);
    }
  }

  Future<void> setInfo(String key, dynamic info) async {
    return await _channel.invokeMethod('setInfo', {"key":key, "value": info});
  }

  Future<void> setUserInfo(String identifier, String email, String name) async {
    return await _channel.invokeMethod('setUserInfo', {"id": identifier, "email": email, "name": name});
  }
}
