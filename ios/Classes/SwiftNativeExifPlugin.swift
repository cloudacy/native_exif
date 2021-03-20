import Flutter
import UIKit

public class SwiftNativeExifPlugin: NSObject, FlutterPlugin {
  private var interfaces: [Int: CFDictionary] = [:]
  private var classId = 0
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "native_exif", binaryMessenger: registrar.messenger())
    let instance = SwiftNativeExifPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initPath":
      classId += 1
      let id = classId
      let path = call.arguments as! String
      let url = NSURL(fileURLWithPath: path)
      guard let source = CGImageSourceCreateWithURL(url, nil) else {
        result(FlutterError(code: "SRC_ERROR", message: "Error while creating source", details: nil))
        return
      }
      
      guard let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) else {
        result(FlutterError(code: "READ_ERROR", message: "Error while reading metadata from source", details: nil))
        return
      }
      
      interfaces[id] = metadata
      
      result(id)
    case "getAttribute":
      guard let arguments = call.arguments as? Dictionary<String, Any> else {
        result(FlutterError(code: "BAD_ARGUMENTS", message: "Argument must be a dictionary.", details: nil))
        return
      }
      
      guard let id = arguments["id"] as? Int else {
        result(FlutterError(code: "BAD_ARGUMENTS", message: "id field must be of type integer.", details: nil))
        return
      }
      
      guard let tag = arguments["tag"] as? String else {
        result(FlutterError(code: "BAD_ARGUMENTS", message: "tag field must be of type string.", details: nil))
        return
      }
      
      guard let interface = interfaces[id] else {
        result(FlutterError(code: "NOT_FOUND", message: "No ExifInterface was found with given id", details: nil))
        return
      }
      
      guard let exif = (interface as NSDictionary)["{Exif}"] as? NSDictionary else {
        result(FlutterError(code: "NO_EXIF_DATA", message: "No Exif data was found on this image.", details: nil))
        return
      }
      
      result(exif[tag])
    case "close":
      guard let arguments = call.arguments as? Dictionary<String, Any> else {
        result(FlutterError(code: "BAD_ARGUMENTS", message: "Argument must be a dictionary.", details: nil))
        return
      }
      
      guard let id = arguments["id"] as? Int else {
        result(FlutterError(code: "BAD_ARGUMENTS", message: "id field must be of type integer.", details: nil))
        return
      }
      
      interfaces[id] = nil
      
      result(nil)
    default:
      result(FlutterError(code: "NOT_IMPLEMENTED", message: "The given method is not implemented!", details: nil))
    }
  }
}
