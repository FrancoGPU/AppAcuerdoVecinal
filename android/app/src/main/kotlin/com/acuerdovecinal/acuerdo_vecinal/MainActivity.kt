package com.acuerdovecinal.acuerdo_vecinal

import android.content.ClipData
import android.content.ContentValues
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.Build
import android.os.Environment
import android.os.ParcelFileDescriptor
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.IOException
import kotlin.math.min
import kotlin.math.roundToInt

class MainActivity : FlutterActivity() {
    companion object {
        private const val PDF_CHANNEL = "acuerdo_vecinal/pdf_export"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PDF_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "compartirPdf" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val fileName = call.argument<String>("fileName") ?: "acta_acuerdo.pdf"
                        val subject = call.argument<String>("subject") ?: "Acta de Compromiso Digital"
                        val text = call.argument<String>("text") ?: ""
                        if (bytes == null || bytes.isEmpty()) {
                            result.error("INVALID_ARGS", "El contenido del PDF está vacío.", null)
                            return@setMethodCallHandler
                        }
                        try {
                            compartirPdf(bytes, fileName, subject, text)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("PDF_SHARE_ERROR", e.message ?: "Error al compartir PDF", null)
                        }
                    }

                    "guardarPdfEnDescargas" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val fileName = call.argument<String>("fileName") ?: "acta_acuerdo.pdf"
                        if (bytes == null || bytes.isEmpty()) {
                            result.error("INVALID_ARGS", "El contenido del PDF está vacío.", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val ubicacion = guardarEnDescargas(bytes, fileName)
                            result.success(ubicacion)
                        } catch (e: Exception) {
                            result.error("PDF_SAVE_ERROR", e.message ?: "Error al guardar PDF", null)
                        }
                    }

                    "renderizarPdfPaginas" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        if (bytes == null || bytes.isEmpty()) {
                            result.error("INVALID_ARGS", "El contenido del PDF está vacío.", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val paginas = renderizarPdfPaginas(bytes)
                            result.success(paginas)
                        } catch (e: Exception) {
                            result.error("PDF_RENDER_ERROR", e.message ?: "Error al renderizar PDF", null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun compartirPdf(
        bytes: ByteArray,
        fileName: String,
        subject: String,
        text: String,
    ) {
        val dir = File(cacheDir, "actas").apply {
            if (!exists()) mkdirs()
        }
        val file = File(dir, fileName)
        file.writeBytes(bytes)

        val uri = FileProvider.getUriForFile(
            this,
            "$packageName.acta_provider",
            file,
        )

        val sendIntent = Intent(Intent.ACTION_SEND).apply {
            type = "application/pdf"
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_SUBJECT, subject)
            if (text.isNotEmpty()) {
                putExtra(Intent.EXTRA_TEXT, text)
            }
            clipData = ClipData.newRawUri(fileName, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        val chooser = Intent.createChooser(sendIntent, "Compartir Acta PDF").apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(chooser)
    }

    private fun guardarEnDescargas(bytes: ByteArray, fileName: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IOException("No se pudo crear el archivo en Descargas.")

            try {
                val stream = contentResolver.openOutputStream(uri)
                    ?: throw IOException("No se pudo abrir el flujo de escritura.")
                stream.use { it.write(bytes) }

                val doneValues = ContentValues().apply {
                    put(MediaStore.Downloads.IS_PENDING, 0)
                }
                contentResolver.update(uri, doneValues, null, null)
                return "Descargas/$fileName"
            } catch (e: Exception) {
                contentResolver.delete(uri, null, null)
                throw e
            }
        }

        val dir = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS) ?: cacheDir
        if (!dir.exists()) dir.mkdirs()
        val outFile = File(dir, fileName)
        outFile.writeBytes(bytes)
        return outFile.absolutePath
    }

    private fun renderizarPdfPaginas(bytes: ByteArray): List<ByteArray> {
        val dir = File(cacheDir, "actas").apply {
            if (!exists()) mkdirs()
        }
        val tempFile = File(dir, "preview_${System.currentTimeMillis()}.pdf")
        tempFile.writeBytes(bytes)

        val paginas = ArrayList<ByteArray>()
        var descriptor: ParcelFileDescriptor? = null
        var renderer: PdfRenderer? = null
        try {
            descriptor = ParcelFileDescriptor.open(tempFile, ParcelFileDescriptor.MODE_READ_ONLY)
            renderer = PdfRenderer(descriptor)
            val total = min(renderer.pageCount, 20)
            for (i in 0 until total) {
                renderer.openPage(i).use { page ->
                    val maxWidth = 1440
                    val scale = min(2.0f, maxWidth.toFloat() / page.width.coerceAtLeast(1))
                    val width = (page.width * scale).roundToInt().coerceAtLeast(1)
                    val height = (page.height * scale).roundToInt().coerceAtLeast(1)
                    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                    try {
                        val canvas = Canvas(bitmap)
                        canvas.drawColor(Color.WHITE)
                        page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                        val baos = ByteArrayOutputStream()
                        bitmap.compress(Bitmap.CompressFormat.PNG, 100, baos)
                        paginas.add(baos.toByteArray())
                    } finally {
                        bitmap.recycle()
                    }
                }
            }
        } finally {
            try {
                renderer?.close()
            } catch (_: Exception) {
            }
            try {
                descriptor?.close()
            } catch (_: Exception) {
            }
            tempFile.delete()
        }
        return paginas
    }
}
