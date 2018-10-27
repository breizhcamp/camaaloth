package org.breizhcamp.camaalothlauncher.services

import mu.KotlinLogging
import org.breizhcamp.camaalothlauncher.CamaalothProps
import org.springframework.messaging.simp.SimpMessagingTemplate
import org.springframework.stereotype.Service
import java.nio.file.Path
import java.nio.file.Paths
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
        val cmd = listOf("/bin/bash", props.nageru.startScript, "-r", recordingDir.toAbsolutePath().toString())
        val logFile = recordingDir.resolve(logDateFormater.format(LocalDateTime.now()) + "_nageru.log")
        val runDir = Paths.get(props.nageru.themeDir)

        CmdRunner("nageru", cmd, runDir, logFile, msgTpl, "/nageruOut").start()
    }
}