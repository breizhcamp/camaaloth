package org.breizhcamp.camaalothlauncher.services

import mu.KotlinLogging
import org.springframework.stereotype.Service
import java.io.InputStream
import java.util.concurrent.atomic.AtomicBoolean
import javax.annotation.PostConstruct
import javax.annotation.PreDestroy

private val logger = KotlinLogging.logger {}

/**
 * Retrieve, watch and notify removable drives found on the computer
 */
@Service
class RemovableDevicesSrv {

    private val udevAdmMonitor = UdevAdmMonitor()

    @PostConstruct
    fun init() {
        //lsblk -o NAME,MOUNTPOINT,VENDOR,LABEL,MODEL,HOTPLUG,SIZE -J

        udevAdmMonitor.start()
    }

    @PreDestroy
    fun shutdown() {
        udevAdmMonitor.shutdown()
    }

    fun readPartitions() {
        println("read partitions")
    }

    /**
     * Thread that's run "udevadm monitor" to watch changes in mount and umount filesystems.
     *
     * Smaple of udevadm ouput :
     *  KERNEL[4518.603613] add      /devices/virtual/bdi/
     *  KERNEL[5311.976541] remove   /devices/virtual/bdi/8:32 (bdi)
     */
    private inner class UdevAdmMonitor : Thread("UdevAdmMonitor") {
        val run = AtomicBoolean(true)

        override fun run() {
            val cmd = listOf("udevadm", "monitor", "--udev", "--subsystem-match=bdi")

            while (run.get()) {
                logger.info { "Watching mount with command : [$cmd]" }
                val udev = ProcessBuilder(cmd).redirectErrorStream(true).start()
                ReadUdevAdmStream(udev.inputStream, "UdevAdmMonitorInput").start()

                try {
                    val waitFor = udev.waitFor()
                    logger.info { "udevadm stopped and returned [$waitFor]" }

                    //when JVM stopping, waitFor is not launching an interrupted exception
                    //so we sleep for 2 second to wait for @PreDestroy if the Spring Container is really shutting down
                    //or if the process is just exiting normally (by an external kill for example)
                    Thread.sleep(2000)
                } catch (e: InterruptedException) {
                    logger.info("udevadm monitor interrupted")
                    Thread.currentThread().interrupt()
                }
            }
        }

        fun shutdown() = run.set(false)
    }

    /** Read input stream of UdevAdm and start readPartitions() when new line read */
    private inner class ReadUdevAdmStream(private val inputStream: InputStream, name: String) : Thread(name) {

        override fun run() {
            inputStream.bufferedReader().forEachLine { line ->
                logger.debug { "Udevadm Monitor : $line" }

                if (line.contains("/devices/virtual/bdi/")) {
                    readPartitions()
                }
            }
        }
    }
}