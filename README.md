# native_exif

A simple EXIF metadata reader/writer for Flutter using native functions from iOS and Android.

## Usage

First create a EXIF reader instance by reading out an image path:

```dart
final exif = await Exif.fromPath(pickedFile!.path);
```

### Reading attributes

Now you can run either pre-defined functions or get all attributes:

```dart
final originalDate = await exif.getOriginalDate();
final latLong = await exif.getLatLong();
final attribute = await exif.getAttribute("key");
final attributes = await exif.getAttributes();
```

### Writing attributes

It is possible to write raw EXIF data of type `String` to specific EXIF keys.
The keys are limited to the EXIF keys provided by the platform. See "Platform notes" for more details.

```dart
await exif.writeAttribute("key", "value");
await exif.writeAttributes({"key1": "value1", "key2": "value2"});
```

### Close the exif interface

```dart
await exif.close();
```

## Platform notes

This plugin does **only** work on iOS and Android. Other platforms are not yet supported.

### Android

Only specific EXIF and GPS attributes are supported. Please look at [android/src/main/kotlin/com/cloudacy/native_exif/NativeExifPlugin.kt](https://github.com/cloudacy/native_exif/blob/main/android/src/main/kotlin/com/cloudacy/native_exif/NativeExifPlugin.kt) for a list of supported attributes.

All raw attribute values must be of type `String`.

Values for `GPSLatitude` and `GPSLongitude` can be written as negative values but will be returned as positive values. Use `GPSLatitudeRef` and `GPSLongitudeRef` or `getLatLong()` to determine the correct coordinates.

### iOS

Only specific EXIF and GPS attributes are supported. Please look at [EXIF dictionary keys](https://developer.apple.com/documentation/imageio/exif_dictionary_keys) and [GPS dictionary keys](https://developer.apple.com/documentation/imageio/gps_dictionary_keys) for supported attributes.

Please note that all [GPS dictionary keys](https://developer.apple.com/documentation/imageio/gps_dictionary_keys) need to be prefixed with `GPS`.
For example: `kCGImagePropertyGPSLatitude` == `"Latitude"`, which equals to `"GPSLatitude"` in `native_exif`.

Values for `GPSLatitude` and `GPSLongitude` should be of type `String` and can be written as negative values but will be returned as positive values. Use `GPSLatitudeRef` and `GPSLongitudeRef` or `getLatLong()` to determine the correct coordinates.

## API Docs

For code docs, you can use the [automatically generated reference on pub.dev](https://pub.dev/documentation/native_exif/latest/).

## Example

For a better usage example, see the example folder or use the [example page on pub.dev](https://pub.dev/packages/native_exif/example).
