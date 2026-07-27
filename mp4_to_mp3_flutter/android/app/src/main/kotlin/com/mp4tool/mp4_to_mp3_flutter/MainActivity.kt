package com.mp4tool.mp4_to_mp3_flutter

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.mp4tool.mp4_to_mp3_flutter/saf"
    private val REQUEST_PICK_TREE = 1001
    private val REQUEST_PICK_FILE = 1002
    private val REQUEST_PICK_OUTPUT_TREE = 1003

    private var pendingResult: MethodChannel.Result? = null
    private var pendingMethod: String? = null

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
