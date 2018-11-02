package org.breizhcamp.camaalothlauncher.controller

import org.breizhcamp.camaalothlauncher.dto.FileMeta
import org.breizhcamp.camaalothlauncher.services.FilesSrv
import org.breizhcamp.camaalothlauncher.services.NageruSrv
import org.breizhcamp.camaalothlauncher.services.TalkSrv
import org.springframework.http.HttpStatus.NO_CONTENT
import org.springframework.web.bind.annotation.*
import java.nio.file.Paths
import java.time.Duration

/**
 * Handle method for 030-live
 */
@RestController @RequestMapping("/live")
class LiveCtrl(private val talkSrv: TalkSrv, private val nageruSrv: NageruSrv, private val filesSrv: FilesSrv) {

    @PostMapping("/start") @ResponseStatus(NO_CONTENT)
    fun startNageru() {
        val recordingDir = talkSrv.recordingPath ?: return
        nageruSrv.start(recordingDir)
    }

    @GetMapping("/files")
    fun listFiles() : List<FileMeta> {
        val recordingDir = talkSrv.recordingPath ?: return emptyList()
        return filesSrv.listFiles(recordingDir, "*.nut", null)
    }

    @GetMapping("/duration")
    fun duration(@RequestParam file: String) : Duration {
        return filesSrv.fileDuration(Paths.get(file))
    }

}