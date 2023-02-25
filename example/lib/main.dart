import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:native_exif/native_exif.dart';

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({
    Key? key,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final picker = ImagePicker();

  XFile? pickedFile;
  Exif? exif;
  Map<String, Object>? attributes;
  DateTime? shootingDate;
  ExifLatLong? coordinates;

  @override
  void initState() {
    super.initState();
  }

  Future<void> showError(Object e) async {
    debugPrintStack(label: e.toString(), stackTrace: e is Error ? e.stackTrace : null);

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text(e.toString()),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future getImage() async {
    pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      return;
    }

    exif = await Exif.fromPath(pickedFile!.path);
    attributes = await exif!.getAttributes();
    shootingDate = await exif!.getOriginalDate();
    coordinates = await exif!.getLatLong();

    setState(() {});
  }

  Future closeImage() async {
    await exif?.close();
    shootingDate = null;
    attributes = {};
    exif = null;
    coordinates = null;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pickedFile == null)
              const Text("Please open an image.")
            else
              Column(
                children: [
                  Text("The selected image has ${attributes?.length ?? 0} attributes."),
                  Text("It was taken at ${shootingDate.toString()}"),
                  Text(attributes?["UserComment"]?.toString() ?? ''),
                  Text("Attributes: $attributes"),
                  Text("Coordinates: $coordinates"),
                  TextButton(
                    onPressed: () async {
                      try {
                        final dateFormat = DateFormat('yyyy:MM:dd HH:mm:ss');
                        await exif!.writeAttribute('DateTimeOriginal', dateFormat.format(DateTime.now()));

                        shootingDate = await exif!.getOriginalDate();
                        attributes = await exif!.getAttributes();

                        setState(() {});
                      } catch (e) {
                        showError(e);
                      }
                    },
                    child: const Text('Update date attribute'),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        // Get original attributes.
                        final attrs = await exif!.getAttributes();

                        debugPrint('Original attributes of ${pickedFile!.path}:');
                        debugPrint(attrs.toString());

                        final dateFormat = DateFormat('yyyy:MM:dd HH:mm:ss');
                        debugPrint('Write DateTimeOriginal ${dateFormat.format(DateTime.now())}');
                        await exif!.writeAttribute('DateTimeOriginal', dateFormat.format(DateTime.now()));

                        await exif!.writeAttributes({
                          'GPSLatitude': '1.0',
                          'GPSLatitudeRef': 'N',
                          'GPSLongitude': '2.0',
                          'GPSLongitudeRef': 'W',
                        });

                        shootingDate = await exif!.getOriginalDate();
                        attributes = await exif!.getAttributes();

                        debugPrint('New attributes:');
                        debugPrint(shootingDate.toString());
                        debugPrint(attributes.toString());

                        final dir = await getApplicationDocumentsDirectory();
                        final newPath = p.join(dir.path, p.basename(pickedFile!.path));

                        debugPrint('New path:');
                        debugPrint(newPath);

                        final newFile = File(newPath);
                        await newFile.writeAsBytes(await pickedFile!.readAsBytes());

                        pickedFile = XFile(newPath);
                        exif = await Exif.fromPath(newPath);
                        attributes = await exif!.getAttributes();
                        shootingDate = await exif!.getOriginalDate();
                        coordinates = await exif!.getLatLong();

                        debugPrint('Attributes of $newPath:');
                        debugPrint(shootingDate.toString());
                        debugPrint(coordinates.toString());
                        debugPrint(attributes.toString());

                        setState(() {});
                      } catch (e) {
                        showError(e);
                      }
                    },
                    child: const Text('Update, store and reload attributes'),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        await exif!.writeAttribute('Orientation', '1');

                        attributes = await exif!.getAttributes();

                        setState(() {});
                      } catch (e) {
                        showError(e);
                      }
                    },
                    child: const Text('Set orientation to 1'),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        await exif!.writeAttributes({
                          'GPSLatitude': '1.0',
                          'GPSLatitudeRef': 'N',
                          'GPSLongitude': '2.0',
                          'GPSLongitudeRef': 'W',
                        });

                        shootingDate = await exif!.getOriginalDate();
                        attributes = await exif!.getAttributes();
                        coordinates = await exif!.getLatLong();

                        setState(() {});
                      } catch (e) {
                        showError(e);
                      }
                    },
                    child: const Text('Update GPS attributes'),
                  ),
                  ElevatedButton(
                    onPressed: closeImage,
                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.red)),
                    child: const Text('Close image'),
                  )
                ],
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: getImage,
              child: const Text('Open image'),
            ),
            if (pickedFile != null)
              ElevatedButton(
                onPressed: () async {
                  try {
                    final file = File(p.join(Directory.systemTemp.path, 'tempimage.jpg'));
                    final imageBytes = await pickedFile!.readAsBytes();
                    await file.create();
                    await file.writeAsBytes(imageBytes);
                    final _attributes = await exif?.getAttributes() ?? {};
                    final newExif = await Exif.fromPath(file.path);

                    _attributes['DateTimeOriginal'] = '2021:05:15 13:00:00';
                    _attributes['UserComment'] = "This file is user generated!";

                    await newExif.writeAttributes(_attributes);

                    shootingDate = await newExif.getOriginalDate();
                    attributes = await newExif.getAttributes();
                    coordinates = await newExif.getLatLong();

                    setState(() {});
                  } catch (e) {
                    showError(e);
                  }
                },
                child: const Text("Create file and write exif data"),
              ),
          ],
        ),
      ),
    );
  }
}
