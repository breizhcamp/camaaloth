package org.breizhcamp.camaalothlauncher.controller

import org.breizhcamp.camaalothlauncher.services.ConvertSrv
import org.springframework.http.HttpStatus.NO_CONTENT
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController
import java.io.InputStream

/**
 * Controller for 040-export
 */
@RestController @RequestMapping("/export")
class ExportCtrl(private val convertSrv: ConvertSrv) {

    @PostMapping("/start") @ResponseStatus(NO_CONTENT)
    fun start() {
        convertSrv.startConvert()
    }

    /**
     * Retrieve progress sent by ffmpeg during conversion.
     */
    @PostMapping("/progress")
    fun progress(input: InputStream) {
        convertSrv.progress(input)
    }
}