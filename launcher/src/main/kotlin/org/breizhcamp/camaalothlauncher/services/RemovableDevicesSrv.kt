package org.breizhcamp.camaalothlauncher.services

import com.fasterxml.jackson.databind.ObjectMapper
import mu.KotlinLogging
import org.breizhcamp.camaalothlauncher.dto.LsblkDto
import org.breizhcamp.camaalothlauncher.dto.Partition
import org.springframework.stereotype.Service
import java.io.InputStream
import java.util.*
import java.util.concurrent.atomic.AtomicBoolean
import java.util.stream.Collectors
import javax.annotation.PostConstruct
import javax.annotation.PreDestroy
import kotlin.collections.ArrayList

private val logger = KotlinLogging.logger {}

/**
 * Retrieve, watch and notify removable drives found on the computer
 */
@Service
class RemovableDevicesSrv(private val objectMapper: ObjectMapper) {

    private val udevAdmMonitor = UdevAdmMonitor()

    @PostConstruct
    fun init() {
        udevAdmMonitor.start()
    }

    @PreDestroy
    fun shutdown() {
        udevAdmMonitor.shutdown()
    }

    /** @return The list of removable and mounted partitions */
    fun readPartitions(): ArrayList<Partition> {
        //lsblk -o NAME,MOUNTPOINT,VENDOR,LABEL,MODEL,HOTPLUG,SIZE -J
        val cmd = listOf("lsblk", "-o", "NAME,MOUNTPOINT,VENDOR,LABEL,MODEL,HOTPLUG,SIZE", "-J")
        logger.info { "Retrieving partitions with command : [$cmd]" }
        val lsblk = ProcessBuilder(cmd).redirectErrorStream(true).start() //TODO better handling error

        val jsonLsblk = lsblk.inputStream.bufferedReader().lines().collect(Collectors.joining())
        val devices = objectMapper.readValue(jsonLsblk, LsblkDto::class.java)

        val partitions = ArrayList<Partition>()
        for (device in devices.blockdevices.filter { it.hotplug == "1" && it.children != null }) {
            for (child in device.children!!) {
                if (child.mountpoint != null) {
                    partitions.add(Partition(child.mountpoint, child.name, child.label, device.model?.trim(), device.vendor?.trim(), child.size))
                }
            }
        }

        return partitions
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
                //TODO handling exception to warn user if thread crashed
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
                    //delay a little bit the run of lsblk in order to mount the partitions
                    //fuseblk emit an another line when mounting but not fat32
                    Timer("UdevAdm starting lsblk").schedule(object : TimerTask() {
                        override fun run() {
                            readPartitions()
                        }
                    }, 1000)

                }
            }
        }
    }
}