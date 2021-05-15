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

  Exif? exif;
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

    exif = await Exif.fromPath(pickedFile.path);
    final attributes = await exif!.getAttributes();
    attributeCount = attributes?.length ?? 0;
    shootingDate = await exif!.getOriginalDate();

    setState(() {});
  }

  Future closeImage() async {
    await exif!.close();
    shootingDate = null;
    attributeCount = 0;

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
                            {'DateTimeOriginal': dateFormat.format(DateTime.now()), 'Software': 'Native Exif'});

                        shootingDate = await exif!.getOriginalDate();
                        final attributes = await exif!.getAttributes();

                        print(attributes);
                        attributeCount = attributes?.length ?? 0;

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
            ],
          ),
        ),
      ),
    );
  }
}
