package org.breizhcamp.camaalothlauncher.dto

import java.time.LocalDate

/**
 * Infos for a talk session
 */
data class TalkSession (
        /** Meetup name (ex: BreizhJUG) */
        var name: String,
        var date: LocalDate,
        var talk: String,
        var speakers: List<Speaker>,
        var logo: ByteArray?
)