package org.breizhcamp.camaalothlauncher.controller

import org.springframework.messaging.simp.annotation.SubscribeMapping
import org.springframework.stereotype.Controller

/**
 * Handle OSC message and send it to connected webpages
 */
@Controller
class OscCtrl {

    @SubscribeMapping("/osc")
    fun test() {
        println("connected")
    }

}