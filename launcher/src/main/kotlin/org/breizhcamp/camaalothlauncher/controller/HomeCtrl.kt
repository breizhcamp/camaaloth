package org.breizhcamp.camaalothlauncher.controller

import org.springframework.stereotype.Controller
import org.springframework.web.bind.annotation.GetMapping

@Controller
class HomeCtrl {

    @GetMapping("/")
    fun home() : String {
        return "000-home"
    }

    @GetMapping("/010-talk-choice")
    fun talkChoix() : String {
        return "010-talk-choice"
    }
}