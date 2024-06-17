package com.cloudacy.native_exif

import androidx.exifinterface.media.ExifInterface
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlin.math.absoluteValue

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

  private fun setAttributes(exif: ExifInterface, values: Map<String, Any>) {
    if (
      values.containsKey(ExifInterface.TAG_GPS_LATITUDE) ||
      values.containsKey(ExifInterface.TAG_GPS_LONGITUDE)
    ) {
      var lat = values[ExifInterface.TAG_GPS_LATITUDE] ?: exif.latLong?.get(0)
      var long = values[ExifInterface.TAG_GPS_LONGITUDE] ?: exif.latLong?.get(1)
      if (lat is String) {
        lat = lat.toDouble()
      } else if (lat !is Double) {
        throw NumberFormatException("Invalid " + ExifInterface.TAG_GPS_LATITUDE + " value given. Must be of type Double or String.")
      }
      if (long is String) {
        long = long.toDouble()
      } else if (long !is Double) {
        throw NumberFormatException("Invalid " + ExifInterface.TAG_GPS_LONGITUDE + " value given. Must be of type Double or String.")
      }

      exif.setLatLong(lat, long)
    }

    for (value in values) {
      if (value.key == ExifInterface.TAG_GPS_LATITUDE || value.key == ExifInterface.TAG_GPS_LONGITUDE) {
        continue
      }

      exif.setAttribute(value.key, value.value as String)
    }
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

          if (tag == ExifInterface.TAG_GPS_LATITUDE) {
            result.success(exif.latLong?.get(0)?.absoluteValue)
          } else if (tag == ExifInterface.TAG_GPS_LONGITUDE) {
            result.success(exif.latLong?.get(1)?.absoluteValue)
          } else {
            result.success(exif.getAttribute(tag))
          }
        }
        "getAttributes" -> {
          val id = call.argument<Int>("id")

          if (id == null) {
            result.error("BAD_ARGUMENTS", "Bad arguments were given to this method.", null)
            return
          }

          val exif = interfaces[id]

          if (exif == null) {
            result.error("NOT_FOUND", "Exif with given id was not found in memory", null)
            return
          }

          /// As all relevant fields are private for the exif interface, we have to list all common tags here. To be extended..
          val tags = arrayOf(
            ExifInterface.TAG_ARTIST,
            ExifInterface.TAG_APERTURE_VALUE,
            ExifInterface.TAG_CUSTOM_RENDERED,
            ExifInterface.TAG_DATETIME,
            ExifInterface.TAG_DATETIME_DIGITIZED,
            ExifInterface.TAG_DATETIME_ORIGINAL,
            ExifInterface.TAG_DIGITAL_ZOOM_RATIO,
            ExifInterface.TAG_EXPOSURE_TIME,
            ExifInterface.TAG_EXPOSURE_PROGRAM,
            ExifInterface.TAG_F_NUMBER,
            ExifInterface.TAG_FLASH,
            ExifInterface.TAG_FOCAL_LENGTH,
            ExifInterface.TAG_GPS_ALTITUDE,
            ExifInterface.TAG_GPS_ALTITUDE_REF,
            ExifInterface.TAG_GPS_DATESTAMP,
            ExifInterface.TAG_GPS_IMG_DIRECTION,
            ExifInterface.TAG_GPS_IMG_DIRECTION_REF,
            ExifInterface.TAG_GPS_LATITUDE_REF,
            ExifInterface.TAG_GPS_LONGITUDE_REF,
            ExifInterface.TAG_GPS_PROCESSING_METHOD,
            ExifInterface.TAG_GPS_TIMESTAMP,
            ExifInterface.TAG_IMAGE_LENGTH,
            ExifInterface.TAG_IMAGE_UNIQUE_ID,
            ExifInterface.TAG_IMAGE_WIDTH,
            ExifInterface.TAG_ISO_SPEED_RATINGS,
            ExifInterface.TAG_MAKE,
            ExifInterface.TAG_MODEL,
            ExifInterface.TAG_ORIENTATION,
            ExifInterface.TAG_SOFTWARE,
            ExifInterface.TAG_SUBSEC_TIME,
            ExifInterface.TAG_SUBSEC_TIME_ORIGINAL,
            ExifInterface.TAG_SUBSEC_TIME_DIGITIZED,
            ExifInterface.TAG_USER_COMMENT,
            ExifInterface.TAG_WHITE_BALANCE
          )

          val attributeMap = HashMap<String, Any>()

          for (tag in tags)
            exif.getAttribute(tag)?.let { attributeMap[tag] = it }

          val latLong = exif.latLong
          if (latLong != null) {
            attributeMap[ExifInterface.TAG_GPS_LATITUDE] = latLong[0].absoluteValue
            attributeMap[ExifInterface.TAG_GPS_LONGITUDE] = latLong[1].absoluteValue
          }

          result.success(attributeMap)
        }
        "setAttribute" -> {
          val id = call.argument<Int>("id")
          val tag = call.argument<String>("tag")
          val value = call.argument<String>("value")

          if (id == null || tag == null || value == null) {
            result.error("BAD_ARGUMENTS", "Bad arguments were given to this method.", null)
            return
          }

          val exif = interfaces[id]

          if (exif == null) {
            result.error("NOT_FOUND", "Exif with given id was not found in memory", null)
            return
          }

          setAttributes(exif, mapOf<String, Any>(tag to value))
          exif.saveAttributes()

          result.success(null)
        }
        "setAttributes" -> {
          val id = call.argument<Int>("id")
          val values = call.argument<Map<String, Any>>("values")

          if (id == null || values == null) {
            result.error("BAD_ARGUMENTS", "Bad arguments were given to this method.", null)
            return
          }

          val exif = interfaces[id]

          if (exif == null) {
            result.error("NOT_FOUND", "Exif with given id was not found in memory", null)
            return
          }

          setAttributes(exif, values)
          exif.saveAttributes()

          result.success(null)
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
