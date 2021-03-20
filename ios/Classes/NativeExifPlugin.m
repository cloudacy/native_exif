#import "NativeExifPlugin.h"
#if __has_include(<native_exif/native_exif-Swift.h>)
#import <native_exif/native_exif-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "native_exif-Swift.h"
#endif

@implementation NativeExifPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftNativeExifPlugin registerWithRegistrar:registrar];
}
@end
