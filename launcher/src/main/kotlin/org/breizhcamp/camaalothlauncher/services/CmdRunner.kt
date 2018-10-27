package org.breizhcamp.camaalothlauncher.services

import mu.KotlinLogging
import org.springframework.messaging.simp.SimpMessagingTemplate
import java.io.BufferedWriter
import java.io.InputStream
import java.nio.file.Path

private val logger = KotlinLogging.logger {}

/**
 * Command runner, can write output to file or stomp topic
 */
class CmdRunner(private val appName: String, private val cmd: List<String>, private val runDir: Path,
                private val logFile: Path?, private val msgTpl: SimpMessagingTemplate?, private val stompDest: String?)
    : Thread("${appName}Runner"){

    override fun run() {
        logger.info { "Starting ${appName} with command : [$cmd]" }
        val process = ProcessBuilder(cmd)
                .redirectErrorStream(true)
                .directory(runDir.toFile())
                .start()

        ReadStream(process.inputStream, "${appName}StdoutReader", logFile).start()
        val waitFor = process.waitFor()

        val exitLog = "${appName} stopped and returned [$waitFor]"
        logger.info { exitLog }
        sendMsg(msgTpl, stompDest, exitLog)
    }

    /** Read input stream and copy into Outputs */
    private inner class ReadStream(private val inputStream: InputStream, name: String, private val logFile: Path?) : Thread(name) {

        override fun run() {
            sendMsg(msgTpl, stompDest, "---- NEW STREAM ----")

            if (logFile != null) {
                logFile.toFile().bufferedWriter().use(this@ReadStream::readInput)
            } else {
                readInput(null)
            }
        }

        private fun readInput(writer: BufferedWriter?) {
            inputStream.bufferedReader().forEachLine { line ->
                logger.debug { "${appName} stdout : $line" }
                sendMsg(msgTpl, stompDest, line)
                writer?.appendln(line)
                writer?.flush()
            }
        }
    }

    private fun sendMsg(msgTpl: SimpMessagingTemplate?, stompDest: String?, msg: Any) {
        if (msgTpl == null || stompDest == null) return
        msgTpl.convertAndSend(stompDest, msg)
    }

}