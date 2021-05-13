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

  int attributeCount = 0;
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
    final attributes = await exif.getAttributes();
    attributeCount = attributes?.length ?? 0;
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
              if (shootingDate == null)
                Text("Please open an image.")
              else
                Column(
                  children: [
                    Text("The selected image has $attributeCount attributes."),
                    Text("It was taken at ${shootingDate.toString()}"),
                  ],
                ),
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
