import Flutter
import UIKit

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

private class NativeExifInterface {
  public var path: String
  
  init(path: String) {
    self.path = path
  }
  
  func getMetadata() throws -> NSDictionary {
    let url = NSURL(fileURLWithPath: path)
    guard let source = CGImageSourceCreateWithURL(url, nil) else {
      throw NativeExifError(code: "SRC_ERROR", message: "Error while creating source", details: nil)
    }
    
    guard let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) else {
      throw NativeExifError(code: "READ_ERROR", message: "Error while reading metadata from source", details: nil)
    }
    
    return metadata as NSDictionary
  }
}

public class SwiftNativeExifPlugin: NSObject, FlutterPlugin {
  private var interfaces: [Int: NativeExifInterface] = [:]
  private var classId = 0
  
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
  
  private func getExifData(_ arguments: Dictionary<String, Any>) throws -> NSMutableDictionary {
    guard let id = arguments["id"] as? Int else {
      throw NativeExifError.badArguments(message: "id field must be of type integer.", details: nil)
    }
    
    guard let interface = interfaces[id] else {
      throw NativeExifError(code: "NOT_FOUND", message: "No ExifInterface was found with given id", details: nil)
    }
    
    let metadata = try interface.getMetadata()
    
    let exif = [:] as NSMutableDictionary
    
    if metadata[kCGImagePropertyOrientation as String] != nil {
      exif["Orientation"] = metadata[kCGImagePropertyOrientation as String] as Any
    }
    
    if metadata[kCGImagePropertyExifDictionary as String] != nil {
      exif.addEntries(from: metadata[kCGImagePropertyExifDictionary as String] as! [AnyHashable : Any])
    }
    
    if metadata[kCGImagePropertyGPSDictionary as String] != nil {
      for property in metadata[kCGImagePropertyGPSDictionary as String] as! [String : Any] {
        exif["GPS" + property.key] = property.value
      }
    }
    
    return exif
  }
  
  public func setAttributes(id: Int, attributes: Dictionary<String, AnyObject>, result: @escaping FlutterResult) throws {
    guard let interface = interfaces[id] else {
      throw NativeExifError(code: "NOT_FOUND", message: "No ExifInterface was found with given id", details: nil)
    }
    
    let url = NSURL(fileURLWithPath: interface.path)
    guard let source = CGImageSourceCreateWithURL(url, nil) else {
      throw NativeExifError(code: "SRC_ERROR", message: "Error while creating source", details: nil)
    }
    
    guard let uniformTypeIdentifier = CGImageSourceGetType(source) else {
      throw NativeExifError(code: "SRC_ERROR", message: "Error while getting source type", details: nil)
    }
    
    guard let destination = CGImageDestinationCreateWithURL(url, uniformTypeIdentifier, 1, nil) else {
      throw NativeExifError(code: "WRITE_ERROR", message: "Error while creating destination for writing metadata", details: nil)
    }
    
    guard var metadata = try interface.getMetadata() as? [String : AnyObject] else {
      throw NativeExifError(code: "READ_ERROR", message: "Metadata could not be converted to mutable dictionary", details: nil)
    }
    
    // Create exif value if it does not exist (e.g. when the file is generated.
    if (metadata[kCGImagePropertyExifDictionary as String] == nil) {
      metadata[kCGImagePropertyExifDictionary as String] = NSDictionary()
    }
    
    var exif = ((metadata[kCGImagePropertyExifDictionary as String] as? NSDictionary)?.mutableCopy() ?? [String : AnyObject]()) as! [String : AnyObject]
    var gps = ((metadata[kCGImagePropertyGPSDictionary as String] as? NSDictionary)?.mutableCopy() ?? [String : AnyObject]()) as! [String : AnyObject]
    
    for value in attributes {
      if value.key == "Orientation" {
        metadata[kCGImagePropertyOrientation as String] = value.value as AnyObject
      } else if value.key.hasPrefix("GPS") {
        let tag = String(value.key.dropFirst(3))
        gps[tag] = value.value
      } else {
        exif[value.key] = value.value
      }
    }
    
    metadata[kCGImagePropertyExifDictionary as String] = exif as AnyObject
    metadata[kCGImagePropertyGPSDictionary as String] = gps as AnyObject
    
    CGImageDestinationAddImageFromSource(destination, source, 0, metadata as CFDictionary)
    guard CGImageDestinationFinalize(destination) else {
      throw NativeExifError(code: "WRITE_ERROR", message: "Error while finalizing destination for writing metadata", details: nil)
    }
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initPath":
      classId += 1
      let id = classId
      let path = call.arguments as! String
      
      interfaces[id] = NativeExifInterface(path: path)
      
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
    case "setAttribute":
      do {
        let arguments = try getArguments(call.arguments)
        guard let id = arguments["id"] as? Int else {
          throw NativeExifError.badArguments(message: "id field must be of type integer.", details: nil)
        }
        
        guard let tag = arguments["tag"] as? String else {
          throw NativeExifError.badArguments(message: "tag field must be of type string.", details: nil)
        }
        
        guard let value = arguments["value"] as? AnyObject else {
          throw NativeExifError.badArguments(message: "value field must be given.", details: nil)
        }
        
        try setAttributes(id: id, attributes: [tag: value], result: result)
        
        result(nil)
      } catch let error as NativeExifError {
        result(error.toFlutterError())
      } catch {
        result(FlutterError())
      }
    case "setAttributes":
      do {
        let arguments = try getArguments(call.arguments)
        
        guard let id = arguments["id"] as? Int else {
          throw NativeExifError.badArguments(message: "id field must be of type integer.", details: nil)
        }
        
        guard let attributes = arguments["values"] as? Dictionary<String, AnyObject> else {
          throw NativeExifError.badArguments(message: "values field must be of type Dictionary.", details: nil)
        }
        
        try setAttributes(id: id, attributes: attributes, result: result)
        
        result(nil)
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
