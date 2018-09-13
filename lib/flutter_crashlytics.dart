import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stack_trace/stack_trace.dart';

class FlutterCrashlytics {
  static const MethodChannel _channel =
  const MethodChannel('flutter_crashlytics');
  static final FlutterCrashlytics _singleton = FlutterCrashlytics._internal();

  factory FlutterCrashlytics() => _singleton;

  FlutterCrashlytics._internal();

  final regexp = RegExp(
    '([a-zA-Z ]+)(?:\\.(.*))?\\([a-zA-Z:/_]+\\/([0-9a-zA-Z_-]+.dart):([0-9]+):?',
    caseSensitive: false,
    multiLine: false,
  );
  final regexpName = RegExp(
    '([a-zA-Z]+) ',
    caseSensitive: false,
    multiLine: false,
  );

  Future<void> onError(FlutterErrorDetails details,
      {bool forceCrash = false}) async {
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
    final data = {
      'name': name,
      'cause': trace[1],
      'message': trace[0],
      'trace': results,
      'forceCrash': forceCrash
    };
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
    return await _channel.invokeMethod('setInfo', {"key": key, "value": info});
  }

  Future<void> setUserInfo(String identifier, String email, String name) async {
    return await _channel.invokeMethod(
        'setUserInfo', {"id": identifier, "email": email, "name": name});
  }

  /// Reports an Exception to Craslytics together with the stacktrace.
  /// Both fields are mandatory.
  ///
  /// As Errors should not be cougth those are not supported.
  ///
  /// ```dart
  /// try {
  ///     // Code throwing en exception
  /// } on Exception catch (e, s) {
  ///     FlutterCrashlytics().logException(e, s);
  /// }
  /// ```
  Future<void> logException(Exception exception, StackTrace stack) async {
    assert(exception != null);
    assert(stack != null);

    final data = {
      'message': exception.toString(),
      'trace': _traces(stack),
    };

    return await _channel.invokeMethod('logException', data);
  }

  List<Map<String, dynamic>> _traces(StackTrace stack) =>
      Trace
          .from(stack)
          .frames
          .map(_toTrace)
          .toList(growable: false);

  Map<String, dynamic> _toTrace(Frame frame) {
    final List<String> tokens = frame.member.split('.');

    return {
      'library': frame.library,
      'line': frame.line,
      // Gobal function might have thrown the exception.
      // So in some cases the method is the first token
      'method': tokens.length == 1 ? tokens[0] : tokens.sublist(1).join(
          '.'),
      // Gobal function might have thrown the exception.
      // So in some cases class does not exist
      'class': tokens.length == 1 ? null : tokens[0],
    };
  }

}
