package org.breizhcamp.camaalothlauncher.controller

import org.breizhcamp.camaalothlauncher.services.TalkSrv
import org.springframework.stereotype.Controller
import org.springframework.ui.Model
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestParam

@Controller
class HomeCtrl(private val talkSrv: TalkSrv) {

    @GetMapping("/")
    fun home() : String {
        return "000-home"
    }

    @GetMapping("/010-talk-choice")
    fun talkChoix() : String {
        return "010-talk-choice"
    }

    @GetMapping("/020-preview")
    fun preview(@RequestParam file: String?, model: Model) : String {
        file?.let(talkSrv::setCurrentTalkFromFile)

        val talk = talkSrv.getCurrentTalk() ?: return "redirect:010-talk-choice"
        model.addAttribute("talk", talk)
        return "020-preview"
    }

    @GetMapping("/030-live")
    fun live(model: Model) : String {
        val talk = talkSrv.getCurrentTalk() ?: return "redirect:010-talk-choice"

        model.addAttribute("talk", talk)
        return "030-live"
    }

    @GetMapping("/040-export")
    fun export(model: Model) : String {
        val talk = talkSrv.getCurrentTalk() ?: return "redirect:010-talk-choice"

        model.addAttribute("talk", talk)
        return "040-export"
    }
}