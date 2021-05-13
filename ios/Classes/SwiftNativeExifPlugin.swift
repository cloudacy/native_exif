import Flutter
import UIKit

public class SwiftNativeExifPlugin: NSObject, FlutterPlugin {
  private var interfaces: [Int: CFDictionary] = [:]
  private var classId = 0
  
  struct NativeExifError: Error {
    let code: String
    let message: String
    let details: Any?
    
    init(code: String, message: String, details: Any?) {
      self.code = code
      self.message = message
      self.details = details
    }
    
    static func badArguments(message: String, details: Any?) -> NativeExifError {
      return NativeExifError(code: "BAD_ARGUMENTS", message: message, details: details)
    }
    
    func toFlutterError() -> FlutterError {
      return FlutterError(code: self.code, message: self.message, details: self.details)
    }
  }
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "native_exif", binaryMessenger: registrar.messenger())
    let instance = SwiftNativeExifPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
  
  private func getArguments(_ callArguments: Any?) throws -> Dictionary<String, Any> {
    guard let arguments = callArguments as? Dictionary<String, Any> else {
      throw NativeExifError.badArguments(message: "Argument must be a dictionary", details: nil)
    }
    
    return arguments
  }
  
  private func getExifData(_ arguments: Dictionary<String, Any>) throws -> NSDictionary {
    guard let id = arguments["id"] as? Int else {
      throw NativeExifError.badArguments(message: "id field must be of type integer.", details: nil)
    }
    
    guard let interface = interfaces[id] else {
      throw NativeExifError(code: "NOT_FOUND", message: "No ExifInterface was found with given id", details: nil)
    }
    
    guard let exif = (interface as NSDictionary)["{Exif}"] as? NSDictionary else {
      throw NativeExifError(code: "NO_EXIF_DATA", message: "No Exif data was found on this image.", details: nil)
    }
    
    return exif
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
      do {
        let arguments = try getArguments(call.arguments)
        let exif = try getExifData(arguments)
        
        guard let tag = arguments["tag"] as? String else {
          result(FlutterError(code: "BAD_ARGUMENTS", message: "tag field must be of type string.", details: nil))
          return
        }
        
        result(exif[tag])
      } catch let error as NativeExifError {
        result(error.toFlutterError())
      } catch {
        result(FlutterError())
      }
    case "getAttributes":
      do {
        let arguments = try getArguments(call.arguments)
        let exif = try getExifData(arguments)
        
        result(exif)
      } catch let error as NativeExifError {
        result(error.toFlutterError())
      } catch {
        result(FlutterError())
      }
    case "close":
      do {
        let arguments = try getArguments(call.arguments)
        
        guard let id = arguments["id"] as? Int else {
          result(FlutterError(code: "BAD_ARGUMENTS", message: "id field must be of type integer.", details: nil))
          return
        }
        
        interfaces[id] = nil
        
        result(nil)
      } catch let error as NativeExifError {
        result(error.toFlutterError())
      } catch {
        result(FlutterError())
      }
    default:
      result(FlutterError(code: "NOT_IMPLEMENTED", message: "The given method is not implemented!", details: nil))
    }
  }
}
