package org.breizhcamp.camaalothlauncher.services

import com.fasterxml.jackson.databind.ObjectMapper
import org.breizhcamp.camaalothlauncher.CamaalothProps
import org.breizhcamp.camaalothlauncher.dto.TalkSession
import org.springframework.stereotype.Service
import java.io.FileNotFoundException
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import java.time.LocalDate
import java.util.zip.ZipEntry
import java.util.zip.ZipFile

/**
 * Manage Talk Data (zip...)
 */
@Service
class TalkSrv(private val objectMapper: ObjectMapper, private val props: CamaalothProps) {

    /** Selected user talk read from JSON file */
    private var currentTalk: TalkSession? = null

    /** Path designing recording dir for [currentTalk] */
    var recordingPath: Path? = null

    /**
     * @return the talk informations (and logo) read from the zip [file]
     */
    fun readTalkSession(file: String, withLogo: Boolean = true) : TalkSession {
        val zipFile = Paths.get(file)
        if (Files.notExists(zipFile)) throw FileNotFoundException("[$file] doesn't exists")

        ZipFile(file).use { zip ->
            val entries = zip.entries()

            var infos: TalkSession? = null
            var logo: ByteArray? = null

            while (entries.hasMoreElements()) {
                val entry = entries.nextElement()

                if (entry.name == "infos.json") {
                    infos = convertToTalk(zip, entry)
                }

                if (withLogo && entry.name == "logo.png") {
                    logo = zip.getInputStream(entry).use { it.readBytes() }
                }
            }

            if (infos == null) {
                throw FileNotFoundException("Cannot found [infos.json] in zip file [$file]")
            }

            infos.logo = logo
            return infos
        }
    }

    /** Define current talk session after reading zip [file] */
    fun setCurrentTalkFromFile(file: String): TalkSession? {
        val t = readTalkSession(file, false)
        currentTalk = t

        val dirName = LocalDate.now().toString() + " - " + t.talk + " - " + t.speakers.joinToString(" -") { it.name }
        recordingPath = Paths.get(props.recordingDir, dirName.replace('/', '-'))

        return currentTalk
    }

    /** Create directory for current dir */
    fun createCurrentTalkDir() {
        val preview = previewDir() ?: return

        if (Files.notExists(preview)) {
            Files.createDirectories(preview)
        }
    }

    fun previewDir() = recordingPath?.resolve("preview")

    private fun convertToTalk(zip: ZipFile, entry: ZipEntry?): TalkSession {
        zip.getInputStream(entry).use {
            return objectMapper.readValue(it, TalkSession::class.java)
        }
    }

}