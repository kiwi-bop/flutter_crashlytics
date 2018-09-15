import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stack_trace/stack_trace.dart';

class FlutterCrashlytics {
  static const MethodChannel _channel = const MethodChannel('flutter_crashlytics');
  static final FlutterCrashlytics _singleton = FlutterCrashlytics._internal();

  factory FlutterCrashlytics() => _singleton;

  FlutterCrashlytics._internal();

  Future<void> onError(FlutterErrorDetails details,
      {bool forceCrash = false}) async {
    final data = {
      'message': details.exception.toString(),
      'trace': _traces(details.stack),
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

  /// Reports an Error to Craslytics.
  /// A good rule of thumb is not to catch Errors as those are errors that occur
  /// in the development phase.
  ///
  /// This method provides the option In case you want to catch them anyhow.
  ///
  ///
  /// ```dart
  /// try {
  ///     // Code throwing an error
  /// } on Error catch (e) {
  ///     FlutterCrashlytics().logError(e);
  /// }
  /// ```
  Future<void> logError(Error error) async {
    assert(error != null);

    final data = {
      'message': error.toString(),
      'trace': _traces(error.stackTrace),
    };

    return await _channel.invokeMethod('logException', data);
  }

  /// Reports an Exception to Craslytics together with the stacktrace.
  /// Both fields are mandatory.
  ///
  /// ```dart
  /// try {
  ///     // Code throwing an exception
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
