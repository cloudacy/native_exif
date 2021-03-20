package com.cloudacy.native_exif

import android.media.ExifInterface
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

/** NativeExifPlugin */
class NativeExifPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private var classId = 0

  private var interfaces = mutableMapOf<Int, ExifInterface>()

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "native_exif")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
        "initPath" -> {
          val exif = ExifInterface(call.arguments as String)
          val id = classId++
          interfaces[id] = exif

          result.success(id)
        }
        "getAttribute" -> {
          val id = call.argument<Int>("id")
          val tag = call.argument<String>("tag")

          if (id == null || tag == null) {
            result.error("BAD_ARGUMENTS", "Bad arguments were given to this method.", null)
            return
          }

          val exif = interfaces[id]

          if (exif == null) {
            result.error("NOT_FOUND", "Exif with given id was not found in memory", null)
            return
          }

          result.success(exif.getAttribute(tag))
        }
        "close" -> {
          val id = call.argument<Int>("id")

          if (id == null) {
            result.error("BAD_ARGUMENTS", "Bad arguments were given to this method.", null)
            return
          }

          interfaces.remove(id)

          result.success(null)
        }
        else -> {
          result.notImplemented()
        }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
