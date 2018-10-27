package org.breizhcamp.camaalothlauncher.services

import mu.KotlinLogging
import org.breizhcamp.camaalothlauncher.CamaalothProps
import org.springframework.messaging.simp.SimpMessagingTemplate
import org.springframework.stereotype.Service
import java.io.File
import java.io.InputStream
import java.nio.file.Path
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

private val logger = KotlinLogging.logger {}

/**
 * Service for handling nageru (start/stop...)
 */
@Service
class NageruSrv(private val props: CamaalothProps, private val msgTpl: SimpMessagingTemplate) {
    private val logDateFormater = DateTimeFormatter.ofPattern("yyyy-MM-dd_HH-mm-ss")

    fun start(recordingDir: Path) {
        NageruRunner(recordingDir).start()
    }

    /**
     * Thread that's run nageru and read sysout and syserr
     */
    private inner class NageruRunner(val recordingDir: Path) : Thread("NageruRunner") {
        override fun run() {
            val cmd = listOf("/bin/bash", props.nageru.startScript, "-r", recordingDir.toAbsolutePath().toString())

            logger.info { "Starting nageru with command : [$cmd]" }
            val nageru = ProcessBuilder(cmd)
                    .redirectErrorStream(true)
                    .directory(File(props.nageru.themeDir))
                    .start()

            ReadStream(nageru.inputStream, "NageruStdoutReader", recordingDir).start()
            val waitFor = nageru.waitFor()
            logger.info { "Nageru stopped and returned [$waitFor]" }
        }
    }

    /** Read input stream and copy into Outputs */
    private inner class ReadStream(private val inputStream: InputStream, name: String, private val recordingDir: Path) : Thread(name) {

        override fun run() {
            val dest = "/nageruOut"
            msgTpl.convertAndSend(dest, "---- NEW STREAM ----")

            val logfile = recordingDir.resolve(logDateFormater.format(LocalDateTime.now()) + "_nageru.log").toFile()

            logfile.bufferedWriter().use { writer ->

                inputStream.bufferedReader().forEachLine { line ->
                    logger.debug { "Nageru stdout : $line" }
                    msgTpl.convertAndSend(dest, line)
                    writer.appendln(line)
                    writer.flush()
                }
            }

        }
    }
}