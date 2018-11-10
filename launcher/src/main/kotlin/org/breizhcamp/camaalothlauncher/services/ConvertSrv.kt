package org.breizhcamp.camaalothlauncher.services

import org.springframework.messaging.simp.SimpMessagingTemplate
import org.springframework.stereotype.Service
import java.nio.file.Path
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

/**
 * Convert output files from nageru to MP4
 */
@Service
class ConvertSrv(private val talkSrv: TalkSrv, private val msgTpl: SimpMessagingTemplate) {
    private val logDateFormater = DateTimeFormatter.ofPattern("yyyy-MM-dd_HH-mm-ss")

    private var filesToConvert: List<Path> = emptyList()

    fun setFiles(files: List<Path>) {
        filesToConvert = ArrayList(files)
    }

    /**
     * Start conversion for selected files
     */
    fun startConvert() {
        val recordingPath = talkSrv.recordingPath ?: return
        if (filesToConvert.isEmpty()) return

        val inputArgs = if (filesToConvert.size == 1) {
            listOf("-i", "file:${filesToConvert[0]}")
        } else {
            recordingPath.resolve("concat.txt").toFile()
                    .writeText(filesToConvert.map { "file 'file:${it.fileName}'" }.joinToString("\n"))
            listOf("-f", "concat", "-safe", "0", "-i", "concat.txt")
        }

        val cmd = mutableListOf("ffmpeg")
        cmd.addAll(inputArgs)
        cmd.addAll(listOf("-c:v", "copy", "-c:a", "aac", "-b:a", "384k", "-profile:a", "aac_low", "export.mp4"))

        val logFile = recordingPath.resolve(logDateFormater.format(LocalDateTime.now()) + "_ffmpeg.log")
        LongCmdRunner("ffmpeg", cmd, recordingPath, logFile, msgTpl, "/040-ffmpeg-export-out").start()
    }

}