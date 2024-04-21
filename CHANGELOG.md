## [0.6.0] - 2024-04-21

- iOS!: Set minimum iOS version to 12.0
- Set environment constraints to sdk ^3.3.0 and flutter >3.19.0
- Updated dependencies

## [0.5.0] - 2023-08-25

- Android!: Set `minSdkVersion` to `19` and `compileSdkVersion` and `targetSdkVersion` to `33`.
- Android: updated android related files for better consistency with the current flutter plugin template
- Android: set JVM target to 1.8 to fix compatibility issues (See [#19](https://github.com/cloudacy/native_exif/issues/19#issuecomment-1645544695) for more details) (Thanks @TiffApps for your contribution)
- Android: AGP update to version 7.4.2
- Android: removed `.idea` files
- Android: add optional namespace to be compatible with AGP < 4.2 (Thanks @TiffApps for your contribution)

## [0.4.1] - 2023-03-18

- Updated dependencies
- Migrated gradle repository from jcenter to mavencentral (Thanks @alvarisi for your contribution)

## [0.4.0]

- Android: Set `compileSdkVersion` and `targetSdkVersion` to `31`.
- Android: Updated dependencies.

## [0.3.0]

- Switched to androidx ExifInterface.
- Unified `GPSLatitude` and `GPSLongitude` behaviour.

## [0.2.1]

- Add support for the [Orientation](https://developer.apple.com/documentation/imageio/cgimagepropertyorientation) property on iOS devices.

## [0.2.0]

- Add support for [GPS attributes](https://developer.apple.com/documentation/imageio/gps_dictionary_keys) on iOS devices.
- Extended README.md.
- Extended example app.

## [0.1.2]

- Added simple README.md

## [0.1.1]

- Add user comment tag for android
- Fix writing on generated files not working

## [0.1.0]

- Add write functionality for android and ios
- Add more tags for android to fetch more information

## [0.0.3]

- Improve null safety

## [0.0.2]

- Example null safety
- Added `close` method, which should always be called to free up memory.

## [0.0.1]

- First working alpha version.
