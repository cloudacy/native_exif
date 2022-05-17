# native_exif

A simple EXIF metadata reader for flutter using native functions from iOS and Android.
This plugin does **only** work on iOS and Android. Flutter Web or Windows is not yet supported.

## Usage

First create a EXIF reader instance by reading out an image path:

```dart
final exif = await Exif.fromPath(pickedFile!.path);
```

Now you can run either pre-defined functions or get all attributes:

```dart
final shootingDate = await exif.getOriginalDate();
final attributes = await exif.getAttributes();
```

## Docs

For code docs, you can use the [automatically generated reference on pub.dev](https://pub.dev/documentation/native_exif/latest/).

## Example

For a better usage example, see the example folder or use the [example page on pub.dev](https://pub.dev/packages/native_exif/example).
