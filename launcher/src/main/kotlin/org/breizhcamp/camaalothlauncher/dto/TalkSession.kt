package org.breizhcamp.camaalothlauncher.dto

import java.time.LocalDate

/**
 * Infos for a talk session
 */
data class TalkSession (
        var name: String,
        var date: LocalDate,
        var talk: String,
        var speakers: List<Speaker>
)