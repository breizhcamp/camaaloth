package org.breizhcamp.camaalothlauncher.services

import com.fasterxml.jackson.databind.ObjectMapper
import mu.KotlinLogging
import org.breizhcamp.camaalothlauncher.dto.FileMeta
import org.breizhcamp.camaalothlauncher.dto.LsblkDto
import org.breizhcamp.camaalothlauncher.dto.Partition
import org.breizhcamp.camaalothlauncher.dto.TalkSession
import org.springframework.stereotype.Service
import java.io.FileNotFoundException
import java.nio.file.Files
import java.nio.file.Paths
import java.util.stream.Collectors
import java.util.zip.ZipFile

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
            Files.newDirectoryStream(Paths.get(partition.mountpoint), pattern).forEach {
                res.add(FileMeta(it.fileName.toString(), it.parent.toString(),
                        Files.getLastModifiedTime(it).toInstant(), partition))
            }
        }

        return res
    }

    /**
     * @return the talk informations read from the zip [file]
     */
    fun readTalkSession(file: String) : TalkSession {
        val zipFile = Paths.get(file)
        if (Files.notExists(zipFile)) throw FileNotFoundException("[$file] doesn't exists")

        val zip = ZipFile(file)
        val entries = zip.entries()

        while (entries.hasMoreElements()) {
            val entry = entries.nextElement()

            if (entry.name == "infos.json") {
                return objectMapper.readValue(zip.getInputStream(entry), TalkSession::class.java)
            }
        }
        throw FileNotFoundException("Cannot found [infos.json] in zip file [$file]")
    }
}