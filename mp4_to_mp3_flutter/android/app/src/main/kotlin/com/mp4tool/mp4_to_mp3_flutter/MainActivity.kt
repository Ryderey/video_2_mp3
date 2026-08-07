package com.mp4tool.mp4_to_mp3_flutter

import android.Manifest
import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.mp4tool.mp4_to_mp3_flutter/saf"
    private val REQUEST_PICK_TREE = 1001
    private val REQUEST_PICK_FILE = 1002
    private val REQUEST_PICK_OUTPUT_TREE = 1003
    private val REQUEST_STORAGE_PERMISSION = 1004

    private var pendingResult: MethodChannel.Result? = null
    private var pendingMethod: String? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickFolder" -> {
                        pendingResult = result
                        pendingMethod = "pickFolder"
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                            addFlags(
                                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                        Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
                            )
                        }
                        startActivityForResult(intent, REQUEST_PICK_TREE)
                    }

                    "pickFile" -> {
                        pendingResult = result
                        pendingMethod = "pickFile"
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            type = "video/mp4"
                            addCategory(Intent.CATEGORY_OPENABLE)
                            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                        }
                        startActivityForResult(intent, REQUEST_PICK_FILE)
                    }

                    "pickOutputDir" -> {
                        pendingResult = result
                        pendingMethod = "pickOutputDir"
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                            addFlags(
                                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                                        Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
                            )
                        }
                        startActivityForResult(intent, REQUEST_PICK_OUTPUT_TREE)
                    }

                    "listMp4Files" -> {
                        val treeUri = call.argument<String>("treeUri") ?: ""
                        val recursive = call.argument<Boolean>("recursive") ?: true
                        try {
                            val files = listMp4FromTree(Uri.parse(treeUri), recursive)
                            result.success(files)
                        } catch (e: Exception) {
                            result.error("LIST_ERROR", e.message, null)
                        }
                    }

                    "copyToCache" -> {
                        val contentUri = call.argument<String>("contentUri") ?: ""
                        val fileName = call.argument<String>("fileName") ?: "temp.mp4"
                        try {
                            val cachePath = copyUriToCache(Uri.parse(contentUri), fileName)
                            result.success(cachePath)
                        } catch (e: Exception) {
                            result.error("COPY_ERROR", e.message, null)
                        }
                    }

                    "writeOutputToTree" -> {
                        val treeUri = call.argument<String>("treeUri") ?: ""
                        val fileName = call.argument<String>("fileName") ?: "output.mp3"
                        val cacheFilePath = call.argument<String>("cacheFilePath") ?: ""
                        try {
                            writeCacheFileToTree(Uri.parse(treeUri), fileName, cacheFilePath)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("WRITE_ERROR", e.message, null)
                        }
                    }

                    "ensureStoragePermission" -> {
                        // API 29+ 通过 MediaStore 写入音乐目录，无需存储权限
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            result.success(true)
                        } else if (ContextCompat.checkSelfPermission(
                                this, Manifest.permission.WRITE_EXTERNAL_STORAGE
                            ) == PackageManager.PERMISSION_GRANTED) {
                            result.success(true)
                        } else if (pendingPermissionResult != null) {
                            result.error("PERMISSION_BUSY", "权限请求进行中", null)
                        } else {
                            pendingPermissionResult = result
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                                REQUEST_STORAGE_PERMISSION
                            )
                        }
                    }

                    "saveToMusicDir" -> {
                        val fileName = call.argument<String>("fileName") ?: "output.mp3"
                        val cacheFilePath = call.argument<String>("cacheFilePath") ?: ""
                        try {
                            saveCacheFileToMusicDir(fileName, cacheFilePath)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("MUSIC_ERROR", e.message, null)
                        }
                    }

                    "getDisplayName" -> {
                        val uri = call.argument<String>("uri") ?: ""
                        try {
                            val name = getDisplayNameFromUri(Uri.parse(uri))
                            result.success(name)
                        } catch (e: Exception) {
                            result.error("NAME_ERROR", e.message, null)
                        }
                    }

                    "releasePermission" -> {
                        val uri = call.argument<String>("uri") ?: ""
                        try {
                            contentResolver.releasePersistableUriPermission(
                                Uri.parse(uri),
                                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                            )
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Safely take persistable URI permission.
     * Some content providers don't support persistable permissions and throw SecurityException.
     */
    private fun safeTakePersistableUriPermission(uri: Uri, flags: Int) {
        try {
            contentResolver.takePersistableUriPermission(uri, flags)
        } catch (_: SecurityException) {
            // Provider doesn't support persistable permissions; session-scoped permission still works
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_STORAGE_PERMISSION) {
            val result = pendingPermissionResult ?: return
            pendingPermissionResult = null
            val granted = grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
            result.success(granted)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        val result = pendingResult ?: return
        pendingResult = null

        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(null)
            return
        }

        when (requestCode) {
            REQUEST_PICK_TREE -> {
                val uri = data.data ?: return result.success(null)
                safeTakePersistableUriPermission(uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION)
                val name = getDisplayNameFromUri(uri)
                result.success(mapOf("uri" to uri.toString(), "name" to name))
            }

            REQUEST_PICK_FILE -> {
                val uris = mutableListOf<Map<String, String>>()
                val clipData = data.clipData
                if (clipData != null) {
                    for (i in 0 until clipData.itemCount) {
                        val uri = clipData.getItemAt(i).uri
                        safeTakePersistableUriPermission(uri,
                            Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        val name = getDisplayNameFromUri(uri)
                        uris.add(mapOf("uri" to uri.toString(), "name" to name))
                    }
                } else {
                    val uri = data.data
                    if (uri != null) {
                        safeTakePersistableUriPermission(uri,
                            Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        val name = getDisplayNameFromUri(uri)
                        uris.add(mapOf("uri" to uri.toString(), "name" to name))
                    }
                }
                result.success(uris)
            }

            REQUEST_PICK_OUTPUT_TREE -> {
                val uri = data.data ?: return result.success(null)
                safeTakePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or
                            Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                )
                val name = getDisplayNameFromUri(uri)
                result.success(mapOf("uri" to uri.toString(), "name" to name))
            }
        }
    }

    /**
     * List MP4 files from a tree URI using DocumentFile traversal.
     */
    private fun listMp4FromTree(treeUri: Uri, recursive: Boolean): List<Map<String, String>> {
        val docFile = DocumentFile.fromTreeUri(this, treeUri) ?: return emptyList()
        val results = mutableListOf<Map<String, String>>()
        collectMp4Files(docFile, recursive, results)
        return results.sortedBy { it["name"]?.lowercase() }
    }

    private fun collectMp4Files(
        dir: DocumentFile,
        recursive: Boolean,
        results: MutableList<Map<String, String>>
    ) {
        val children = dir.listFiles()
        for (child in children) {
            if (child.isDirectory && recursive) {
                collectMp4Files(child, true, results)
            } else if (child.isFile) {
                val name = child.name ?: continue
                if (name.lowercase().endsWith(".mp4")) {
                    results.add(mapOf(
                        "uri" to child.uri.toString(),
                        "name" to name
                    ))
                }
            }
        }
    }

    /**
     * Copy a content:// URI to app cache directory, return the absolute file path.
     */
    private fun copyUriToCache(contentUri: Uri, fileName: String): String {
        val cacheDir = File(cacheDir, "ffmpeg_input")
        if (!cacheDir.exists()) cacheDir.mkdirs()

        // Sanitize filename
        val safeName = fileName.replace(Regex("[^a-zA-Z0-9._\\-\\u4e00-\\u9fa5]"), "_")
        val targetFile = File(cacheDir, safeName)

        contentResolver.openInputStream(contentUri)?.use { input ->
            FileOutputStream(targetFile).use { output ->
                input.copyTo(output)
            }
        } ?: throw Exception("Cannot open input stream for $contentUri")

        return targetFile.absolutePath
    }

    /**
     * Write a cache file into a SAF tree URI as a new document.
     */
    private fun writeCacheFileToTree(treeUri: Uri, fileName: String, cacheFilePath: String) {
        val dir = DocumentFile.fromTreeUri(this, treeUri)
            ?: throw Exception("Cannot access output directory")

        // Create new file in the tree
        val newFile = dir.createFile("audio/mpeg", fileName)
            ?: throw Exception("Cannot create output file: $fileName")

        contentResolver.openOutputStream(newFile.uri)?.use { output ->
            File(cacheFilePath).inputStream().use { input ->
                input.copyTo(output)
            }
        } ?: throw Exception("Cannot open output stream")
    }

    /**
     * Save a cache file into the system Music directory.
     * API 29+ uses MediaStore (no permission needed); older versions write to
     * the public Music folder directly (requires WRITE_EXTERNAL_STORAGE).
     */
    private fun saveCacheFileToMusicDir(fileName: String, cacheFilePath: String) {
        val source = File(cacheFilePath)
        if (!source.exists()) throw Exception("Cache file not found: $cacheFilePath")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Audio.Media.DISPLAY_NAME, fileName)
                put(MediaStore.Audio.Media.MIME_TYPE, "audio/mpeg")
                put(MediaStore.Audio.Media.RELATIVE_PATH, Environment.DIRECTORY_MUSIC)
            }
            val uri = contentResolver.insert(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values
            ) ?: throw Exception("Cannot create file in Music directory: $fileName")
            contentResolver.openOutputStream(uri)?.use { output ->
                source.inputStream().use { input -> input.copyTo(output) }
            } ?: throw Exception("Cannot open output stream")
        } else {
            @Suppress("DEPRECATION")
            val musicDir = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_MUSIC
            )
            if (!musicDir.exists()) musicDir.mkdirs()

            // 重名文件追加 _1、_2 序号后缀
            val dot = fileName.lastIndexOf('.')
            val base = if (dot > 0) fileName.substring(0, dot) else fileName
            val ext = if (dot > 0) fileName.substring(dot) else ""
            var target = File(musicDir, fileName)
            var n = 1
            while (target.exists()) {
                target = File(musicDir, "${base}_$n$ext")
                n++
            }
            FileOutputStream(target).use { output ->
                source.inputStream().use { input -> input.copyTo(output) }
            }
        }
    }

    /**
     * Get display name from a URI.
     * Handles both tree URIs and single document URIs safely.
     */
    private fun getDisplayNameFromUri(uri: Uri): String {
        try {
            val docFile = if (uri.pathSegments.contains("document")) {
                DocumentFile.fromSingleUri(this, uri)
            } else {
                DocumentFile.fromTreeUri(this, uri)
            }
            if (docFile != null) {
                val name = docFile.name
                if (!name.isNullOrEmpty()) return name
            }
        } catch (_: Exception) {}
        // Fallback: query content resolver
        try {
            contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val idx = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
                    if (idx >= 0) return cursor.getString(idx)
                }
            }
        } catch (_: Exception) {}
        return uri.lastPathSegment ?: "unknown"
    }
}
