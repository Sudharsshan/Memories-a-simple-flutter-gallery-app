package com.example.memories

import android.app.WallpaperManager
import android.net.Uri
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.IOException
import java.io.InputStream
import java.io.File
import kotlin.collections.emptyList

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example/wallpaper"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            if (call.method == "setWallpaper") {} else {

                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            when (call.method) {
                "setWallpaper" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        val success = setWallpaper(path)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "Path cannot be null.", null)
                    }
                }
                "listFiles" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        val files = listFilesInDirectory(path)
                        result.success(files)
                    } else {
                        result.error("INVALID_ARGUMENT", "Path cannot be null.", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setWallpaper(path: String): Boolean {
        val wallpaperManager = WallpaperManager.getInstance(applicationContext)
        val uri = Uri.parse("file://$path")
        var inputStream: InputStream? = null
        var success = false
        try {
            inputStream = contentResolver.openInputStream(uri)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                wallpaperManager.setStream(inputStream, null, true, WallpaperManager.FLAG_SYSTEM)
            } else {
                wallpaperManager.setStream(inputStream)
            }
            success = true
        } catch (e: IOException) {
            e.printStackTrace()
            success = false
        } finally {
            inputStream?.close()
        }
        return success
    }

    private fun listFilesInDirectory(path: String): List<String> {
        val directory = File(path)
        return directory.listFiles()?.map { it.name } ?: emptyList()
    }
}