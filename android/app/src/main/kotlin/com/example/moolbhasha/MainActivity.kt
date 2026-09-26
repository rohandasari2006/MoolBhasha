package com.example.moolbhasha

import android.content.ContentValues
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "moolbhasha/downloads"

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "savePdfToDownloads" -> {

                    val fileName =
                        call.argument<String>("fileName")

                    val bytes =
                        call.argument<ByteArray>("bytes")

                    if (fileName == null || bytes == null) {
                        result.error(
                            "INVALID_ARGUMENTS",
                            "PDF fileName or bytes are missing.",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {

                            val contentValues =
                                ContentValues().apply {
                                    put(
                                        MediaStore.Downloads.DISPLAY_NAME,
                                        fileName
                                    )
                                    put(
                                        MediaStore.Downloads.MIME_TYPE,
                                        "application/pdf"
                                    )
                                    put(
                                        MediaStore.Downloads.RELATIVE_PATH,
                                        "Download"
                                    )
                                    put(
                                        MediaStore.Downloads.IS_PENDING,
                                        1
                                    )
                                }

                            val resolver = contentResolver

                            val uri = resolver.insert(
                                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                                contentValues
                            )

                            if (uri == null) {
                                result.error(
                                    "SAVE_FAILED",
                                    "Could not create PDF in Downloads.",
                                    null
                                )
                                return@setMethodCallHandler
                            }

                            resolver.openOutputStream(uri).use { outputStream ->

                                if (outputStream == null) {
                                    resolver.delete(uri, null, null)

                                    result.error(
                                        "SAVE_FAILED",
                                        "Could not open Downloads output stream.",
                                        null
                                    )

                                    return@setMethodCallHandler
                                }

                                outputStream.write(bytes)
                                outputStream.flush()
                            }

                            contentValues.clear()

                            contentValues.put(
                                MediaStore.Downloads.IS_PENDING,
                                0
                            )

                            resolver.update(
                                uri,
                                contentValues,
                                null,
                                null
                            )

                            result.success(
                                "Download/$fileName"
                            )

                        } else {
                            result.error(
                                "UNSUPPORTED_ANDROID",
                                "Android version below 10 is not supported.",
                                null
                            )
                        }

                    } catch (e: Exception) {
                        result.error(
                            "SAVE_FAILED",
                            e.message ?: "Unknown error while saving PDF.",
                            null
                        )
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}