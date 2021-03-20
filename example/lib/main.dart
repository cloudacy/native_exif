import 'package:flutter/material.dart';
import 'dart:async';

import 'package:image_picker/image_picker.dart';
import 'package:native_exif/native_exif.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final picker = ImagePicker();

  DateTime? shootingDate;

  @override
  void initState() {
    super.initState();
  }

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      return;
    }

    final exif = await Exif.fromPath(pickedFile.path);
    shootingDate = await exif.getOriginalDate();
    await exif.close();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(shootingDate == null
                  ? "Please open an image."
                  : "The selected image was taken at ${shootingDate.toString()}"),
              SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: getImage,
                child: Text('Open image'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
