package org.breizhcamp.camaalothlauncher.services

import kotlinx.coroutines.Dispatchers.IO
import kotlinx.coroutines.async
import kotlinx.coroutines.runBlocking
import mu.KotlinLogging
import org.breizhcamp.camaalothlauncher.dto.FFMpegProgress
import org.springframework.boot.web.servlet.context.ServletWebServerInitializedEvent
import org.springframework.context.ApplicationListener
import org.springframework.messaging.simp.SimpMessagingTemplate
import org.springframework.stereotype.Service
import java.io.InputStream
import java.io.UncheckedIOException
import java.nio.file.Path
import java.time.Duration
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

private val logger = KotlinLogging.logger {}

/**
 * Convert output files from nageru to MP4
 */
@Service
class ConvertSrv(private val talkSrv: TalkSrv, private val msgTpl: SimpMessagingTemplate, private val filesSrv: FilesSrv)
    : ApplicationListener<ServletWebServerInitializedEvent> {

    private val logDateFormater = DateTimeFormatter.ofPattern("yyyy-MM-dd_HH-mm-ss")

    private var filesToConvert: List<Path> = emptyList()
    private var httpPort = 0

    override fun onApplicationEvent(event: ServletWebServerInitializedEvent) {
        httpPort = event.source.port
    }

    fun setFiles(files: List<Path>) {
        filesToConvert = ArrayList(files)
    }

    /**
     * Start conversion for selected files
     */
    fun startConvert() : Duration {
        val recordingPath = talkSrv.recordingPath ?: return Duration.ZERO
        if (filesToConvert.isEmpty()) return Duration.ZERO
        val duration = videoFileLength(filesToConvert)

        val inputArgs = if (filesToConvert.size == 1) {
            listOf("-i", "file:${filesToConvert[0]}")
        } else {
            recordingPath.resolve("concat.txt").toFile()
                    .writeText(filesToConvert.map { "file 'file:${it.fileName}'" }.joinToString("\n"))
            listOf("-f", "concat", "-safe", "0", "-i", "concat.txt")
        }

        val cmd = mutableListOf("ffmpeg", "-n", "-progress", "http://localhost:$httpPort/export/progress")
        cmd.addAll(inputArgs)
        cmd.addAll(listOf("-c:v", "copy", "-c:a", "aac", "-b:a", "384k", "-profile:a", "aac_low", "export.mp4"))

        val logFile = recordingPath.resolve(logDateFormater.format(LocalDateTime.now()) + "_ffmpeg.log")
        LongCmdRunner("ffmpeg", cmd, recordingPath, logFile, msgTpl, "/040-ffmpeg-export-out").start()

        return duration
    }

    /**
     * Process input from ffmpeg, sending "messages" each ended with progress=xxx, each line with key=value
     */
    fun progress(input: InputStream) {
        input.bufferedReader().use { r ->
            val curMsg = HashMap<String, String>()

            try {
                for (line in r.lines()) {
                    val (key, value) = line.split('=')
                    curMsg.put(key, value)

                    if (line.startsWith("progress=") && curMsg.size > 0) {
                        val progress = FFMpegProgress.build(curMsg)
                        msgTpl.convertAndSend("/040-ffmpeg-export-progress", progress)
                        curMsg.clear()
                    }
                }
            } catch (e: UncheckedIOException) {
                //ffmpeg cut the connection violently, we discard the exception
                logger.info { "FFMpeg has cut the progress \"a l'arrache\"" }
            }
        }
    }

    /**
     * Compute the length of several video files
     */
    private fun videoFileLength(files: List<Path>) : Duration = runBlocking(IO) {
        val defered = files.map { f ->
            async { filesSrv.fileDuration(f) }
        }

        defered.fold(Duration.ZERO) { acc, d -> acc + d.await() }
    }
}