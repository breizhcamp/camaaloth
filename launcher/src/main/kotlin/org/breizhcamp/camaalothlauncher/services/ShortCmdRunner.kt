package org.breizhcamp.camaalothlauncher.services

import mu.KotlinLogging
import java.nio.file.Path
import java.util.stream.Collectors

private val logger = KotlinLogging.logger {}

/**
 * Runs a command and return result. The intended command to run is short lived and block execution thread during running.
 */
class ShortCmdRunner(private val appName: String, private val cmd: List<String>, private val logging: Boolean = false,
                     private val runDir: Path? = null) {

    fun run() : String {
        if (logging) logger.info { "Starting ${appName} with command : [$cmd]" }

        val processB = ProcessBuilder(cmd).redirectErrorStream(true)
        runDir?.let { processB.directory(it.toFile()) }

        val process = processB.start() //TODO better handling error
        return process.inputStream.bufferedReader().lines().collect(Collectors.joining())
    }

}