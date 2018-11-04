package org.breizhcamp.camaalothlauncher.controller

import org.breizhcamp.camaalothlauncher.services.CmdRunner
import org.breizhcamp.camaalothlauncher.services.NageruSrv
import org.breizhcamp.camaalothlauncher.services.TalkSrv
import org.springframework.http.HttpStatus.NO_CONTENT
import org.springframework.web.bind.annotation.*
import java.nio.file.Files

/**
 * Handle method for 020-preview
 */
@RestController @RequestMapping("/preview")
class PreviewCtrl(private val talkSrv: TalkSrv, private val nageruSrv: NageruSrv) {

    @PostMapping("/start") @ResponseStatus(NO_CONTENT)
    fun startNageru() {
        val preview = talkSrv.previewDir() ?: return
        clearPreviewDir()
        nageruSrv.start(preview, "/020-nageru-preview-out")
    }

    @PostMapping("/view") @ResponseStatus(NO_CONTENT)
    fun readVlc() {
        val preview = talkSrv.previewDir() ?: return

        Files.newDirectoryStream(preview, "*.nut")
            .use { it.firstOrNull() }
            ?.let { nutFile ->
                val cmd = listOf("vlc", nutFile.toAbsolutePath().toString())
                CmdRunner("vlc", cmd, preview).start()
            }
    }

    @DeleteMapping @ResponseStatus(NO_CONTENT)
    fun clearPreviewDir() {
        val preview = talkSrv.previewDir() ?: return
        preview.toFile().listFiles().forEach { it.deleteRecursively() }
    }

}