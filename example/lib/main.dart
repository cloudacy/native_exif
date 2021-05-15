import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';

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

  PickedFile? pickedFile;
  Exif? exif;
  Map<String, Object>? attributes;
  DateTime? shootingDate;

  @override
  void initState() {
    super.initState();
  }

  Future getImage() async {
    pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      return;
    }

    exif = await Exif.fromPath(pickedFile!.path);
    attributes = await exif!.getAttributes();
    shootingDate = await exif!.getOriginalDate();

    setState(() {});
  }

  Future closeImage() async {
    await exif!.close();
    shootingDate = null;

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
              if (pickedFile == null)
                Text("Please open an image.")
              else
                Column(
                  children: [
                    Text("The selected image has ${attributes?.length ?? 0} attributes."),
                    Text("It was taken at ${shootingDate.toString()}"),
                    Text(attributes?["UserComment"]?.toString() ?? ''),
                    TextButton(
                      onPressed: () async {
                        final dateFormat = DateFormat('yyyy:MM:dd HH:mm:ss');
                        await exif!.writeAttribute('DateTimeOriginal', dateFormat.format(DateTime.now()));

                        shootingDate = await exif!.getOriginalDate();

                        setState(() {});
                      },
                      child: Text('Update date attribute'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final dateFormat = DateFormat('yyyy:MM:dd HH:mm:ss');
                        await exif!.writeAttributes(
                            {'DateTimeOriginal': dateFormat.format(DateTime.now()), 'ImageUniqueID': '123456'});

                        shootingDate = await exif!.getOriginalDate();
                        attributes = await exif!.getAttributes();

                        setState(() {});
                      },
                      child: Text('Update date attribute and add new attribute'),
                    ),
                    ElevatedButton(
                      onPressed: closeImage,
                      child: Text('Close image'),
                      style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.red)),
                    )
                  ],
                ),
              SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: getImage,
                child: Text('Open image'),
              ),
              if (pickedFile != null)
                ElevatedButton(
                  onPressed: () async {
                    final file = File(p.join(Directory.systemTemp.path, 'tempimage.jpg'));
                    final imageBytes = await pickedFile!.readAsBytes();
                    await file.create();
                    await file.writeAsBytes(imageBytes);
                    final _attributes = await exif!.getAttributes();
                    final newExif = await Exif.fromPath(file.path);

                    _attributes!['DateTimeOriginal'] = '2021:05:15 13:00:00';
                    _attributes['UserComment'] = "This file is user generated!";

                    await newExif.writeAttributes(_attributes);

                    shootingDate = await newExif.getOriginalDate();
                    attributes = await newExif.getAttributes();

                    setState(() {});
                  },
                  child: Text("Create file and write exif data"),
                )
            ],
          ),
        ),
      ),
    );
  }
}
