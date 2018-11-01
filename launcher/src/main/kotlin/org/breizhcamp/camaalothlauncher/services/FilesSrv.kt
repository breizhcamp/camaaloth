package org.breizhcamp.camaalothlauncher.services

import com.fasterxml.jackson.databind.ObjectMapper
import mu.KotlinLogging
import org.breizhcamp.camaalothlauncher.dto.FileMeta
import org.breizhcamp.camaalothlauncher.dto.LsblkDto
import org.breizhcamp.camaalothlauncher.dto.Partition
import org.springframework.stereotype.Service
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import java.util.stream.Collectors

private val logger = KotlinLogging.logger {}

/**
 * Retrieve, watch and notify removable drives found on the computer
 */
@Service
class FilesSrv(private val objectMapper: ObjectMapper) {

    /** @return The list of removable and mounted partitions */
    fun readPartitions(): List<Partition> {
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
     * @return files matching the [pattern] at root of the specified [partitions]
     */
    fun getFilesFromPartitions(partitions: List<Partition>, pattern: String) : List<FileMeta> {
        val res = ArrayList<FileMeta>()

        for (partition in partitions) {
            val path = Paths.get(partition.mountpoint)
            res.addAll(listFiles(path, pattern, partition))
        }

        return res
    }

    /**
     * @return files matching the [pattern] in [path]
     */
    fun listFiles(path: Path?, pattern: String, partition: Partition?): ArrayList<FileMeta> {
        val res = ArrayList<FileMeta>()

        Files.newDirectoryStream(path, pattern).use { stream ->
            stream.forEach {
                res.add(FileMeta(it.fileName.toString(), it.parent.toString(),
                        Files.getLastModifiedTime(it).toInstant(), partition, Files.size(it)))
            }
        }

        return res
    }
}