package org.breizhcamp.camaalothlauncher.controller

import org.breizhcamp.camaalothlauncher.services.NageruSrv
import org.breizhcamp.camaalothlauncher.services.TalkSrv
import org.springframework.http.HttpStatus.NO_CONTENT
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController

/**
 * Handle method for 030-live
 */
@RestController @RequestMapping("/live")
class LiveCtrl(private val talkSrv: TalkSrv, private val nageruSrv: NageruSrv) {

    @PostMapping("/start") @ResponseStatus(NO_CONTENT)
    fun startNageru() {
        val recordingDir = talkSrv.recordingPath ?: return
        nageruSrv.start(recordingDir)
    }

}