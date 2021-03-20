import 'dart:async';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Exif {
  static const MethodChannel _channel = const MethodChannel('native_exif');

  int _id;
  Exif(int id) : _id = id;

  static Future<Exif> fromPath(String path) async {
    final int id = await _channel.invokeMethod('initPath', path);

    return Exif(id);
  }

  getAttribute<T>(String tag) async {
    final dynamic result = await _channel.invokeMethod('getAttribute', {
      'id': _id,
      'tag': tag,
    });

    return result as T;
  }

  Future<DateTime?> getOriginalDate() async {
    final String dateString = await getAttribute<String>('DateTimeOriginal');
    final dateFormat = DateFormat("yyyy:MM:dd HH:mm:ss");

    try {
      return dateFormat.parse(dateString);
    } catch (e) {
      return null;
    }
  }
}
