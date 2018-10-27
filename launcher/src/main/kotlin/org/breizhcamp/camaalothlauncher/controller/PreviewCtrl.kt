package org.breizhcamp.camaalothlauncher.controller

import org.breizhcamp.camaalothlauncher.services.NageruSrv
import org.breizhcamp.camaalothlauncher.services.TalkSrv
import org.springframework.http.HttpStatus.NO_CONTENT
import org.springframework.web.bind.annotation.*

/**
 * Handle method for 020-preview
 */
@RestController @RequestMapping("/preview")
class PreviewCtrl(private val talkSrv: TalkSrv, private val nageruSrv: NageruSrv) {

    @PostMapping("/start") @ResponseStatus(NO_CONTENT)
    fun startNageru() {
        val preview = talkSrv.previewDir() ?: return
        clearPreviewDir()
        nageruSrv.start(preview)
    }

    fun readVlc() {

    }

    @DeleteMapping("/clean")
    fun clearPreviewDir() {
        val preview = talkSrv.previewDir() ?: return
        preview.toFile().listFiles().forEach { it.deleteRecursively() }
    }

}