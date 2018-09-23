package org.breizhcamp.camaalothlauncher.controller

import org.springframework.stereotype.Controller
import org.springframework.web.bind.annotation.GetMapping

@Controller
class HomeCtrl {

    @GetMapping("/")
    fun home() : String {
        return "000-home"
    }

}