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
import java.time.Duration

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
        val jsonLsblk = ShortCmdRunner("lsblk partitions", cmd, true).run()
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

    /**
     * @return duration of the video [file]
     */
    fun fileDuration(file: Path) : Duration {
        //ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 -sexagesimal file:record-2018-11-02-16:16:51+0100-f00.nut
        val cmd = listOf("ffprobe", "-v", "fatal", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1",
                "file:${file.fileName}")

        val dur = ShortCmdRunner("ffprobe length", cmd, true, file.parent).run() //10.030000

        if (dur == "N/A") return Duration.ZERO
        val split = dur.split(".")
        return Duration.ofSeconds(split[0].toLong(), split[1].toLong() * 1000)
    }
}